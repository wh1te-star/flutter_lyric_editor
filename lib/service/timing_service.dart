import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:xml/xml.dart' as xml;

final timingMasterProvider = ChangeNotifierProvider((ref) {
  final musicPlayerService = ref.read(musicPlayerMasterProvider);
  return TimingService(musicPlayerProvider: musicPlayerService);
});

class TimingService extends ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;

  Map<SnippetID, LyricSnippet> lyricSnippetList = {};
  Map<String, int> vocalistColorMap = {};
  List<int> sections = [];
  Map<String, List<String>> vocalistCombinationCorrespondence = {};

  SnippetIdGenerator snippetIdGenerator = SnippetIdGenerator();
  VocalistIdGenerator vocalistIdGenerator = VocalistIdGenerator();

  Future<void>? _loadLyricsFuture;
  List<Map<SnippetID, LyricSnippet>> undoHistory = [];

  String defaultVocalistName = "vocalist 1";

  TimingService({
    required this.musicPlayerProvider,
  }) {
    _loadLyricsFuture = loadExampleLyrics();
  }

  void initLyric(String rawText) {
    int audioDuration = musicPlayerProvider.audioDuration;
    String singlelineText = rawText.replaceAll("\n", "").replaceAll("\r", "");
    lyricSnippetList.clear();
    lyricSnippetList[snippetIdGenerator.idGen()] = LyricSnippet(
      vocalist: Vocalist(
        id: vocalistIdGenerator.idGen(),
        name: defaultVocalistName,
        color: 0,
      ),
      sentence: singlelineText,
      startTimestamp: 0,
      sentenceSegments: [SentenceSegment(singlelineText.length, audioDuration)],
    );

    vocalistColorMap.clear();
    vocalistColorMap[defaultVocalistName] = 0xff777777;

    notifyListeners();
  }

  void loadLyric(String rawLyricText) {
    lyricSnippetList = parseLyric(rawLyricText);

    pushUndoHistory(lyricSnippetList);
    notifyListeners();
  }

  void exportLyric(String path) async {
    final String rawLyricText = serializeLyric(lyricSnippetList);
    final File file = File(path);
    await file.writeAsString(rawLyricText);
  }

  List<LyricSnippet> translateIDsToSnippets(List<SnippetID> ids) {
    return ids.map((id) => getSnippetWithID(id)).toList();
  }

  LyricSnippet getSnippetWithID(SnippetID id) {
    return lyricSnippetList[id]!;
  }

  void removeSnippetWithID(SnippetID id) {
    lyricSnippetList.remove(id);
  }

  List<LyricSnippet> getSnippetsWithVocalistName(String vocalistName) {
    return lyricSnippetList.values.where((snippet) => snippet.vocalist.name == vocalistName).toList();
  }

  void addSection(int seekPosition) {
    pushUndoHistory(lyricSnippetList);

    if (!sections.contains(seekPosition)) {
      sections.add(seekPosition);
    }

    notifyListeners();
  }

  void deleteSection(int seekPosition) {
    pushUndoHistory(lyricSnippetList);

    int targetIndex = 0;
    int minDistance = 3600000;
    for (int index = 0; index < sections.length; index++) {
      int distance = sections[index] - seekPosition;
      if (distance < 0) {
        distance = -distance;
      }
      if (distance < minDistance) {
        minDistance = distance;
        targetIndex = index;
      }
    }

    if (minDistance < 5000) {
      sections.removeAt(targetIndex);
    }

    notifyListeners();
  }

  void addVocalist(String vocalistName) {
    pushUndoHistory(lyricSnippetList);

    vocalistColorMap[vocalistName] = 0xFF222222;

    notifyListeners();
  }

  void deleteVocalist(String vocalistName) {
    pushUndoHistory(lyricSnippetList);

    vocalistColorMap.remove(vocalistName);
    lyricSnippetList.removeWhere((id, snippet) => snippet.vocalist.name == vocalistName);

    notifyListeners();
  }

  void changeVocalistName(String oldName, String newName) {
    pushUndoHistory(lyricSnippetList);

    Map<String, int> updatedVocalistColorList = {};

    vocalistColorMap.forEach((key, value) {
      if (vocalistCombinationCorrespondence.containsKey(key)) {
        List<String> vocalistNames = vocalistCombinationCorrespondence[key]!;
        if (vocalistNames.contains(oldName)) {
          int index = vocalistNames.indexWhere((String name) {
            return name == oldName;
          });
          vocalistNames[index] = newName;
          String newCombinationName = vocalistNames.join(", ");
          vocalistCombinationCorrespondence[newCombinationName] = vocalistNames;
          vocalistCombinationCorrespondence.remove(key);

          updatedVocalistColorList[newCombinationName] = value;
          getSnippetsWithVocalistName(key).forEach((LyricSnippet snippet) {
            snippet.vocalist = Vocalist(
              id: snippet.vocalist.id,
              name: newCombinationName,
              color: 0,
            );
          });
        } else {
          updatedVocalistColorList[key] = value;
        }
      } else if (key == oldName) {
        updatedVocalistColorList[newName] = value;
        getSnippetsWithVocalistName(key).forEach((LyricSnippet snippet) {
          snippet.vocalist = Vocalist(
            id: snippet.vocalist.id,
            name: newName,
            color: 0,
          );
        });
      } else {
        updatedVocalistColorList[key] = value;
      }
    });

    vocalistColorMap = updatedVocalistColorList;

    Map<String, List<String>> updatedMap = {};

    vocalistCombinationCorrespondence.forEach((String key, List<String> value) {
      int index = value.indexOf(oldName);
      if (index != -1) {
        value[index] = newName;
        updatedMap[value.join(", ")] = value;
      } else {
        updatedMap[key] = value;
      }
    });

    vocalistCombinationCorrespondence = updatedMap;

    getSnippetsWithVocalistName(oldName).forEach((LyricSnippet snippet) {
      snippet.vocalist = Vocalist(
        id: snippet.vocalist.id,
        name: newName,
        color: 0,
      );
    });

    notifyListeners();
  }

  Future<void> loadExampleLyrics() async {
    try {
      String rawLyricText = await rootBundle.loadString('assets/ウェルカムティーフレンド.xlrc');

      lyricSnippetList = parseLyric(rawLyricText);
      notifyListeners();
      //writeTranslatedXmlToFile();
    } catch (e) {
      debugPrint("Error loading lyrics: $e");
    }
  }

  int parseTimestamp(String timestamp) {
    final parts = timestamp.split(':');
    final minutes = int.parse(parts[0]);
    final secondsParts = parts[1].split('.');
    final seconds = int.parse(secondsParts[0]);
    final milliseconds = int.parse(secondsParts[1]);
    return (minutes * 60 + seconds) * 1000 + milliseconds;
  }

  Map<SnippetID, LyricSnippet> parseLyric(String rawLyricText) {
    final document = xml.XmlDocument.parse(rawLyricText);

    final vocalistCombination = document.findAllElements('VocalistsList');
    for (var vocalistName in vocalistCombination) {
      final colorElements = vocalistName.findElements('VocalistInfo');
      for (var colorElement in colorElements) {
        final name = colorElement.getAttribute('name')!;
        final color = int.parse(colorElement.getAttribute('color')!, radix: 16);
        vocalistColorMap[name] = color + 0xFF000000;

        final vocalistNames = colorElement.findAllElements('Vocalist').map((e) => e.innerText).toList();
        if (vocalistNames.length >= 2) {
          vocalistCombinationCorrespondence[name] = vocalistNames;
        }
      }
    }

    final lineTimestamps = document.findAllElements('LineTimestamp');
    Map<SnippetID, LyricSnippet> snippets = {};
    for (var lineTimestamp in lineTimestamps) {
      final startTime = parseTimestamp(lineTimestamp.getAttribute('startTime')!);
      final vocalistName = lineTimestamp.getAttribute('vocalistName')!;

      final wordTimestamps = lineTimestamp.findElements('WordTimestamp');
      String sentence = '';
      List<SentenceSegment> sentenceSegments = [];

      for (var wordTimestamp in wordTimestamps) {
        final time = parseTimestamp(wordTimestamp.getAttribute('time')!);
        final word = wordTimestamp.innerText;
        sentenceSegments.add(SentenceSegment(word.length, time));
        sentence += word;
      }
      snippets[snippetIdGenerator.idGen()] = LyricSnippet(
        vocalist: Vocalist(
          id: vocalistIdGenerator.idGen(),
          name: vocalistName,
          color: 123456,
        ),
        sentence: sentence,
        startTimestamp: startTime,
        sentenceSegments: sentenceSegments,
      );
    }

    return snippets;
  }

  String serializeLyric(Map<SnippetID, LyricSnippet> lyricSnippetList) {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('Lyrics', nest: () {
      for (var snippet in lyricSnippetList.values) {
        builder.element('LineTimestamp', attributes: {
          'vocalistName': snippet.vocalist.name,
          'startTime': _formatTimestamp(snippet.startTimestamp),
        }, nest: () {
          int characterPosition = 0;
          for (var sentenceSegment in snippet.sentenceSegments) {
            builder.element('WordTimestamp',
                attributes: {
                  'time': _formatTimestamp(sentenceSegment.wordDuration),
                },
                nest: snippet.sentence.substring(characterPosition, characterPosition + sentenceSegment.wordLength));
            characterPosition += sentenceSegment.wordLength;
          }
        });
      }
    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: true, indent: '  ');
  }

  Future<void> writeTranslatedXmlToFile() async {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('Lyrics', nest: () {
      for (var snippet in lyricSnippetList.values) {
        builder.element('LineTimestamp', attributes: {
          'vocalistName': snippet.vocalist.name,
          'startTime': _formatTimestamp(snippet.startTimestamp),
        }, nest: () {
          int characterPosition = 0;
          for (int i = 0; i < snippet.sentenceSegments.length; i++) {
            final currentPoint = snippet.sentenceSegments[i];
            final nextPoint = i < snippet.sentenceSegments.length - 1 ? snippet.sentenceSegments[i + 1] : null;

            final endtime = snippet.sentenceSegments.map((point) => point.wordDuration).reduce((a, b) => a + b);
            final duration = nextPoint != null ? nextPoint.wordDuration - currentPoint.wordDuration : endtime - currentPoint.wordDuration;

            builder.element('WordTimestamp',
                attributes: {
                  'time': _formatDuration(Duration(milliseconds: duration)),
                },
                nest: snippet.sentence.substring(characterPosition, characterPosition + currentPoint.wordLength));
            characterPosition += currentPoint.wordLength;
          }
        });
      }
    });

    /*
    final document = builder.buildDocument();
    final xmlString = document.toXmlString(pretty: true);
    debugPrint(xmlString);
    */
  }

  String _formatTimestamp(int timestamp) {
    final minutes = (timestamp ~/ 60000).toString().padLeft(2, '0');
    final seconds = ((timestamp % 60000) ~/ 1000).toString().padLeft(2, '0');
    final milliseconds = (timestamp % 1000).toString().padLeft(3, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds = duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  Future<void> printLyric() async {
    if (_loadLyricsFuture != null) {
      await _loadLyricsFuture;
    }
    //String first30Chars = rawLyricText.substring(0, 30);
    //debugPrint(first30Chars);
  }

  List<LyricSnippet> getSnippetsAtCurrentSeekPosition() {
    int seekPosition = musicPlayerProvider.seekPosition;
    return lyricSnippetList.values.where((snippet) {
      final endtime = snippet.startTimestamp + snippet.sentenceSegments.map((point) => point.wordDuration).reduce((a, b) => a + b);
      return snippet.startTimestamp < seekPosition && seekPosition < endtime;
    }).toList();
  }

  void divideSnippet(SnippetID snippetID, int charPosition) {
    pushUndoHistory(lyricSnippetList);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    int seekPosition = musicPlayerProvider.seekPosition;
    int snippetMargin = 100;
    String beforeString = snippet.sentence.substring(0, charPosition);
    String afterString = snippet.sentence.substring(charPosition);
    Vocalist vocalist = snippet.vocalist;
    Map<SnippetID, LyricSnippet> newSnippets = {};
    if (beforeString.isNotEmpty) {
      int snippetDuration = seekPosition - snippet.startTimestamp;
      newSnippets[snippetIdGenerator.idGen()] = LyricSnippet(
        vocalist: vocalist,
        sentence: beforeString,
        startTimestamp: snippet.startTimestamp,
        sentenceSegments: [SentenceSegment(beforeString.length, snippetDuration)],
      );
    }
    if (afterString.isNotEmpty) {
      int snippetDuration = snippet.endTimestamp - snippet.startTimestamp - seekPosition - snippetMargin;
      newSnippets[snippetIdGenerator.idGen()] = LyricSnippet(
        vocalist: vocalist,
        sentence: afterString,
        startTimestamp: seekPosition + snippetMargin,
        sentenceSegments: [SentenceSegment(afterString.length, snippetDuration)],
      );
    }
    if (newSnippets.isNotEmpty) {
      lyricSnippetList.removeWhere((id, snippet) => id == snippetID);
      lyricSnippetList.addAll(newSnippets);
    }

    notifyListeners();
  }

  void concatenateSnippets(List<SnippetID> snippetIDs) {
    pushUndoHistory(lyricSnippetList);

    List<LyricSnippet> snippets = translateIDsToSnippets(snippetIDs);

    Map<Vocalist, List<LyricSnippet>> snippetsForeachVocalist = groupBy(
      snippets,
      (LyricSnippet snippet) => snippet.vocalist,
    );
    snippetsForeachVocalist.forEach((vocalist, vocalistSnippets) {
      vocalistSnippets.sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));
      for (int index = 1; index < vocalistSnippets.length; index++) {
        LyricSnippet leftSnippet = vocalistSnippets[0];
        LyricSnippet rightSnippet = vocalistSnippets[index];
        late final int extendDuration;
        if (leftSnippet.endTimestamp <= rightSnippet.startTimestamp) {
          extendDuration = rightSnippet.startTimestamp - leftSnippet.endTimestamp;
        } else {
          extendDuration = 0;
        }
        leftSnippet.sentenceSegments.last.wordDuration += extendDuration;
        leftSnippet.sentence += rightSnippet.sentence;
        leftSnippet.sentenceSegments.addAll(rightSnippet.sentenceSegments);

        SnippetID rightSnippetID = snippetIDs[index];
        removeSnippetWithID(rightSnippetID);
      }
    });

    notifyListeners();
  }

  void manipulateSnippet(SnippetID snippetID, SnippetEdge snippetEdge, bool holdLength) {
    pushUndoHistory(lyricSnippetList);

    int seekPosition = musicPlayerProvider.seekPosition;
    LyricSnippet snippet = getSnippetWithID(snippetID);
    if (holdLength) {
      if (snippetEdge == SnippetEdge.start) {
        moveSnippet(snippet, snippet.startTimestamp - seekPosition);
      } else {
        moveSnippet(snippet, seekPosition - snippet.endTimestamp);
      }
    } else {
      if (snippetEdge == SnippetEdge.start) {
        if (seekPosition < snippet.startTimestamp) {
          extendSnippet(snippet, SnippetEdge.start, snippet.startTimestamp - seekPosition);
        } else if (snippet.startTimestamp < seekPosition) {
          shortenSnippet(snippet, SnippetEdge.start, seekPosition - snippet.startTimestamp);
        }
      } else {
        if (seekPosition < snippet.endTimestamp) {
          shortenSnippet(snippet, SnippetEdge.end, snippet.endTimestamp - seekPosition);
        } else if (snippet.endTimestamp < seekPosition) {
          extendSnippet(snippet, SnippetEdge.end, seekPosition - snippet.endTimestamp);
        }
      }
    }

    notifyListeners();
  }

  void moveSnippet(LyricSnippet snippet, int shiftDuration) {
    snippet.startTimestamp += shiftDuration;
  }

  void extendSnippet(LyricSnippet snippet, SnippetEdge snippetEdge, int extendDuration) {
    assert(extendDuration >= 0, "Should be shorten function.");
    if (snippetEdge == SnippetEdge.start) {
      snippet.startTimestamp -= extendDuration;
      snippet.sentenceSegments.first.wordDuration += extendDuration;
    } else {
      snippet.sentenceSegments.last.wordDuration += extendDuration;
    }
  }

  void shortenSnippet(LyricSnippet snippet, SnippetEdge snippetEdge, int shortenDuration) {
    assert(shortenDuration >= 0, "Should be extend function.");
    if (snippetEdge == SnippetEdge.start) {
      int index = 0;
      int rest = shortenDuration;
      while (index < snippet.sentenceSegments.length && rest - snippet.sentenceSegments[index].wordDuration > 0) {
        rest -= snippet.sentenceSegments[index].wordDuration;
        index++;
      }
      snippet.startTimestamp += shortenDuration;
      snippet.sentenceSegments = snippet.sentenceSegments.sublist(index);
      snippet.sentenceSegments.first.wordDuration -= rest;
    } else {
      int index = snippet.sentenceSegments.length - 1;
      int rest = shortenDuration;
      while (index >= 0 && rest - snippet.sentenceSegments[index].wordDuration > 0) {
        rest -= snippet.sentenceSegments[index].wordDuration;
        index--;
      }
      snippet.sentenceSegments = snippet.sentenceSegments.sublist(0, index + 1);
      snippet.sentenceSegments.last.wordDuration -= rest;
    }
  }

  void addTimingPoint(SnippetID snippetID, int characterPosition, int seekPosition) {
    pushUndoHistory(lyricSnippetList);

    LyricSnippet snippet = getSnippetWithID(snippetID);

    if (characterPosition <= 0 || snippet.sentence.length <= characterPosition) {
      throw TimingPointException("The char position is out of the valid range.");
    }

    int timingPointIndex = -1;
    int leftBoundPosition = 0;
    int centerPosition = 0;
    int rightBoundPosition = 0;

    int sentenceSegmentIndex = -1;
    int charRest = 0;

    int charPositionSum = 0;
    int durationSum = 0;
    for (int index = 0; index < snippet.sentenceSegments.length; index++) {
      charPositionSum += snippet.sentenceSegments[index].wordLength;
      durationSum += snippet.sentenceSegments[index].wordDuration;
      if (charPositionSum == characterPosition) {
        timingPointIndex = index + 1;
        leftBoundPosition = snippet.startTimestamp + (durationSum - snippet.sentenceSegments[index].wordDuration);
        centerPosition = snippet.startTimestamp + durationSum;
        rightBoundPosition = snippet.startTimestamp + (durationSum + snippet.sentenceSegments[index + 1].wordDuration);
        break;
      }
      if (charPositionSum > characterPosition) {
        sentenceSegmentIndex = index;
        leftBoundPosition = snippet.startTimestamp + (durationSum - snippet.sentenceSegments[index].wordDuration);
        rightBoundPosition = snippet.startTimestamp + durationSum;
        charRest = characterPosition - (charPositionSum - snippet.sentenceSegments[index].wordLength);
        break;
      }
    }

    if (timingPointIndex == -1) {
      if (seekPosition <= leftBoundPosition || rightBoundPosition <= seekPosition) {
        throw TimingPointException("The seek position is not valid.");
      }

      int formerLength = charRest;
      int formerDuration = seekPosition - leftBoundPosition;
      int latterLength = snippet.sentenceSegments[sentenceSegmentIndex].wordLength - charRest;
      int latterDuration = rightBoundPosition - seekPosition;

      snippet.sentenceSegments[sentenceSegmentIndex] = SentenceSegment(latterLength, latterDuration);
      snippet.sentenceSegments.insert(sentenceSegmentIndex, SentenceSegment(formerLength, formerDuration));
    } else {
      if (seekPosition <= leftBoundPosition || rightBoundPosition <= seekPosition) {
        throw TimingPointException("The seek position is not valid.");
      }
      if (seekPosition == centerPosition) {
        throw TimingPointException("Cannot add duplicate timing point.");
      }
      if (snippet.sentenceSegments[timingPointIndex].wordLength == 0) {
        throw TimingPointException("Cannot add timing point more than 2");
      }

      int formerLength;
      int formerDuration;
      int latterLength;
      int latterDuration;
      if (seekPosition < centerPosition) {
        formerLength = snippet.sentenceSegments[timingPointIndex - 1].wordLength;
        formerDuration = seekPosition - leftBoundPosition;
        latterLength = 0;
        latterDuration = centerPosition - seekPosition;

        snippet.sentenceSegments[timingPointIndex - 1] = SentenceSegment(formerLength, formerDuration);
        snippet.sentenceSegments.insert(timingPointIndex, SentenceSegment(latterLength, latterDuration));
      } else {
        formerLength = snippet.sentenceSegments[timingPointIndex].wordLength;
        formerDuration = rightBoundPosition - seekPosition;
        latterLength = 0;
        latterDuration = seekPosition - centerPosition;

        snippet.sentenceSegments[timingPointIndex] = SentenceSegment(formerLength, formerDuration);
        snippet.sentenceSegments.insert(timingPointIndex, SentenceSegment(latterLength, latterDuration));
      }
    }

    notifyListeners();
  }

  void deleteTimingPoint(SnippetID snippetID, int characterPosition, {Option option = Option.former}) {
    pushUndoHistory(lyricSnippetList);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    if (characterPosition <= 0 || snippet.sentence.length <= characterPosition) {
      throw TimingPointException("The character position is out of the valid range.");
    }

    int timingPointIndex = -1;
    int charPositionSum = 0;
    for (int index = 0; index < snippet.sentenceSegments.length; index++) {
      charPositionSum += snippet.sentenceSegments[index].wordLength;
      if (charPositionSum == characterPosition) {
        timingPointIndex = index;
        break;
      }
      if (charPositionSum > characterPosition) {
        throw TimingPointException("There is not specified timing point.");
      }
    }
    if (option == Option.former) {
      int newLength = snippet.sentenceSegments[timingPointIndex].wordLength + snippet.sentenceSegments[timingPointIndex + 1].wordLength;
      int newDuration = snippet.sentenceSegments[timingPointIndex].wordDuration + snippet.sentenceSegments[timingPointIndex + 1].wordDuration;
      snippet.sentenceSegments.removeAt(timingPointIndex);
      snippet.sentenceSegments[timingPointIndex] = SentenceSegment(newLength, newDuration);
    } else {
      timingPointIndex++;
      if (snippet.sentenceSegments[timingPointIndex].wordLength != 0) {
        throw TimingPointException("There is not specified timing point.");
      }
      int newLength = snippet.sentenceSegments[timingPointIndex + 1].wordLength;
      int newDuration = snippet.sentenceSegments[timingPointIndex].wordDuration + snippet.sentenceSegments[timingPointIndex + 1].wordDuration;
      snippet.sentenceSegments.removeAt(timingPointIndex);
      snippet.sentenceSegments[timingPointIndex] = SentenceSegment(newLength, newDuration);
    }

    notifyListeners();
  }

  void editSentence(SnippetID snippetID, String newSentence) {
    pushUndoHistory(lyricSnippetList);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    List<int> charPositionTranslation = getCharPositionTranslation(snippet.sentence, newSentence);
    int charPosition = 0;
    List<int> allCharPosition = [0];
    for (int index = 0; index < snippet.sentenceSegments.length; index++) {
      charPosition += snippet.sentenceSegments[index].wordLength;
      allCharPosition.add(charPosition);
    }

    allCharPosition.forEach((int currentCharPosition) {
      if (charPositionTranslation[currentCharPosition] == -1) {
        try {
          deleteTimingPoint(snippetID, currentCharPosition, option: Option.former);
        } catch (TimingPointException) {
          debugPrint(e.toString());
        }
        try {
          deleteTimingPoint(snippetID, currentCharPosition, option: Option.latter);
        } catch (TimingPointException) {
          debugPrint(e.toString());
        }
      }
    });

    charPosition = 0;
    allCharPosition.clear();
    allCharPosition.add(0);
    for (int index = 0; index < snippet.sentenceSegments.length; index++) {
      charPosition += snippet.sentenceSegments[index].wordLength;
      allCharPosition.add(charPosition);
    }

    for (int index = 0; index < snippet.sentenceSegments.length; index++) {
      int leftCharPosition = charPositionTranslation[allCharPosition[index]];
      int rightCharPosition = charPositionTranslation[allCharPosition[index + 1]];
      snippet.sentenceSegments[index].wordLength = rightCharPosition - leftCharPosition;
    }

    integrate2OrMoreTimingPoints(snippet);

    snippet.sentence = newSentence;

    notifyListeners();
  }

  void integrate2OrMoreTimingPoints(LyricSnippet snippet) {
    List<SentenceSegment> result = [];
    int accumulatedSum = 0;

    snippet.sentenceSegments.forEach((SentenceSegment sentenceSegment) {
      if (sentenceSegment.wordLength == 0) {
        accumulatedSum += sentenceSegment.wordDuration;
      } else {
        if (accumulatedSum != 0) {
          result.add(SentenceSegment(0, accumulatedSum));
          accumulatedSum = 0;
        }
        result.add(sentenceSegment);
      }
    });

    if (accumulatedSum != 0) {
      result.add(SentenceSegment(0, accumulatedSum));
    }

    snippet.sentenceSegments = result;
  }

  List<int> getCharPositionTranslation(String oldSentence, String newSentence) {
    int oldLength = oldSentence.length;
    int newLength = newSentence.length;

    List<List<int>> lcsMap = List.generate(oldLength + 1, (_) => List.filled(newLength + 1, 0));

    for (int i = 1; i <= oldLength; i++) {
      for (int j = 1; j <= newLength; j++) {
        if (oldSentence[i - 1] == newSentence[j - 1]) {
          lcsMap[i][j] = lcsMap[i - 1][j - 1] + 1;
        } else {
          lcsMap[i][j] = max(lcsMap[i - 1][j], lcsMap[i][j - 1]);
        }
      }
    }

    List<int> indexTranslation = List.filled(oldLength + 1, -1);
    int i = oldLength, j = newLength;

    while (i > 0 && j > 0) {
      if (oldSentence[i - 1] == newSentence[j - 1]) {
        indexTranslation[i] = j;
        indexTranslation[i - 1] = j - 1;
        i--;
        j--;
      } else if (lcsMap[i - 1][j] >= lcsMap[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }

    return indexTranslation;
  }

  void undo() {
    lyricSnippetList = popUndoHistory();

    notifyListeners();
  }

  void pushUndoHistory(Map<SnippetID, LyricSnippet> lyricSnippetList) {
    Map<SnippetID, LyricSnippet> copy = lyricSnippetList.map((id, snippet) {
      return MapEntry(
        id,
        LyricSnippet(
          vocalist: Vocalist(
            id: snippet.vocalist.id,
            name: snippet.vocalist.name,
            color: snippet.vocalist.color,
          ),
          sentence: snippet.sentence,
          startTimestamp: snippet.startTimestamp,
          sentenceSegments: snippet.sentenceSegments.map((point) {
            return SentenceSegment(point.wordLength, point.wordDuration);
          }).toList(),
        ),
      );
    });

    undoHistory.add(copy);
  }

  Map<SnippetID, LyricSnippet> popUndoHistory() {
    if (undoHistory.isEmpty) {
      return {};
    }
    return undoHistory.removeLast();
  }
}

class TimingPointException implements Exception {
  final String message;
  TimingPointException(this.message);

  @override
  String toString() => 'TimingPointException: $message';
}
