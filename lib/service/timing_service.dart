import 'dart:io';
import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:rxdart/rxdart.dart';
import 'package:xml/xml.dart' as xml;

class TimingService {
  final BuildContext context;
  final PublishSubject<dynamic> masterSubject;
  String rawLyricText = "";
  Map<String, int> vocalistColorList = {};
  Map<String, List<String>> vocalistCombinationCorrespondence = {};
  List<LyricSnippet> lyricSnippetList = [];
  List<int> sections = [];

  Future<void>? _loadLyricsFuture;
  int currentPosition = 0;
  int audioDuration = 180000;

  List<List<LyricSnippet>> undoHistory = [];

  String defaultVocalistName = "vocalist 1";

  TimingService({required this.masterSubject, required this.context}) {
    masterSubject.stream.listen((signal) async {
      if (signal is RequestInitLyric) {
        final XFile? file = await openFile(acceptedTypeGroups: [
          XTypeGroup(
            label: 'text',
            extensions: ['txt'],
            mimeTypes: ['text/plain'],
          )
        ]);

        if (file != null) {
          String rawText = await file.readAsString();
          String singlelineText = rawText.replaceAll("\n", "").replaceAll("\r", "");
          lyricSnippetList.clear();
          lyricSnippetList.add(LyricSnippet(
            vocalist: Vocalist(defaultVocalistName, 0),
            index: 1,
            sentence: singlelineText,
            startTimestamp: 0,
            sentenceSegments: [SentenceSegment(singlelineText.length, audioDuration)],
          ));

          vocalistColorList.clear();
          vocalistColorList[defaultVocalistName] = 0xff777777;

          masterSubject.add(NotifyLyricParsed(lyricSnippetList, vocalistColorList, vocalistCombinationCorrespondence));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file selected')),
          );
        }
      }
      if (signal is RequestLoadLyric) {
        final XFile? file = await openFile(acceptedTypeGroups: [
          XTypeGroup(
            label: 'xlrc',
            extensions: ['xlrc'],
            mimeTypes: ['application/xml'],
          )
        ]);

        if (file != null) {
          rawLyricText = await file.readAsString();
          lyricSnippetList = parseLyric(rawLyricText);

          pushUndoHistory(lyricSnippetList);
          masterSubject.add(NotifyLyricParsed(lyricSnippetList, vocalistColorList, vocalistCombinationCorrespondence));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file selected')),
          );
        }
      }
      if (signal is RequestExportLyric) {
        const String fileName = 'example.xlrc';
        final FileSaveLocation? result = await getSaveLocation(suggestedName: fileName);
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file selected')),
          );
          return;
        }

        final String rawLyricText = serializeLyric(lyricSnippetList);
        final File file = File(result.path);
        await file.writeAsString(rawLyricText);
      }
      if (signal is RequestAddSection) {
        addSection(signal.seekPosition);
        masterSubject.add(NotifySectionAdded(sections));
      }
      if (signal is RequestDeleteSection) {
        deleteSection(signal.seekPosition);
        masterSubject.add(NotifySectionDeleted(sections));
      }
      if (signal is RequestAddVocalist) {
        pushUndoHistory(lyricSnippetList);

        addVocalist(signal.vocalistName);
        masterSubject.add(NotifyVocalistAdded(lyricSnippetList, vocalistColorList, vocalistCombinationCorrespondence));
      }
      if (signal is RequestDeleteVocalist) {
        pushUndoHistory(lyricSnippetList);

        deleteVocalist(signal.vocalistName);

        masterSubject.add(NotifyVocalistDeleted(lyricSnippetList, vocalistColorList, vocalistCombinationCorrespondence));
      }
      if (signal is RequestChangeVocalistName) {
        pushUndoHistory(lyricSnippetList);

        changeVocalistName(signal.oldName, signal.newName);
        masterSubject.add(NotifyVocalistNameChanged(lyricSnippetList, vocalistColorList, vocalistCombinationCorrespondence));
      }
      if (signal is RequestToAddTimingPoint) {
        LyricSnippet snippet = getSnippetWithID(signal.snippetID);
        try {
          addTimingPoint(snippet, signal.characterPosition, signal.seekPosition);
        } catch (e) {
          debugPrint(e.toString());
        }
        masterSubject.add(NotifyTimingPointAdded(lyricSnippetList));
      }
      if (signal is RequestToDeleteTimingPoint) {
        LyricSnippet snippet = getSnippetWithID(signal.snippetID);
        try {
          deleteTimingPoint(snippet, signal.characterPosition, signal.option);
        } catch (e) {
          debugPrint(e.toString());
        }
        masterSubject.add(NotifyTimingPointDeleted(lyricSnippetList));
      }
      if (signal is NotifySeekPosition) {
        currentPosition = signal.seekPosition;
      }
      if (signal is NotifyAudioFileLoaded) {
        audioDuration = signal.millisec;
      }

      if (signal is RequestDivideSnippet) {
        int index = getSnippetIndexWithID(signal.snippetID);
        divideSnippet(index, signal.charPos, currentPosition);
      }
      if (signal is RequestConcatenateSnippet) {
        List<LyricSnippet> snippets = translateIDsToSnippets(signal.snippetIDs);
        concatenateSnippets(snippets);
      }
      if (signal is RequestSnippetMove) {
        pushUndoHistory(lyricSnippetList);

        LyricSnippet snippet = getSnippetWithID(signal.id);
        if (signal.holdLength) {
          if (signal.snippetEdge == SnippetEdge.start) {
            moveSnippet(snippet, snippet.startTimestamp - currentPosition);
          } else {
            moveSnippet(snippet, currentPosition - snippet.endTimestamp);
          }
        } else {
          if (signal.snippetEdge == SnippetEdge.start) {
            if (currentPosition < snippet.startTimestamp) {
              extendSnippet(snippet, SnippetEdge.start, snippet.startTimestamp - currentPosition);
            } else if (snippet.startTimestamp < currentPosition) {
              shortenSnippet(snippet, SnippetEdge.start, currentPosition - snippet.startTimestamp);
            }
          } else {
            if (currentPosition < snippet.endTimestamp) {
              shortenSnippet(snippet, SnippetEdge.end, snippet.endTimestamp - currentPosition);
            } else if (snippet.endTimestamp < currentPosition) {
              extendSnippet(snippet, SnippetEdge.end, currentPosition - snippet.endTimestamp);
            }
          }
        }
        masterSubject.add(NotifySnippetMove(lyricSnippetList));
      }

      if (signal is RequestUndo) {
        lyricSnippetList = popUndoHistory();
        assignIndex(lyricSnippetList);
        masterSubject.add(NotifyUndo(lyricSnippetList));
      }
    });
    _loadLyricsFuture = loadLyrics();
  }

  List<LyricSnippet> translateIDsToSnippets(List<LyricSnippetID> ids) {
    return ids.map((id) => getSnippetWithID(id)).toList();
  }

  int getSnippetIndexWithID(LyricSnippetID id) {
    return lyricSnippetList.indexWhere((snippet) => snippet.id == id);
  }

  LyricSnippet getSnippetWithID(LyricSnippetID id) {
    return lyricSnippetList.firstWhere((snippet) => snippet.id == id);
  }

  void removeSnippetWithID(LyricSnippetID id) {
    lyricSnippetList.removeWhere((snippet) => snippet.id == id);
  }

  List<LyricSnippet> getSnippetsWithVocalistName(String vocalistName) {
    return lyricSnippetList.where((snippet) => snippet.vocalist.name == vocalistName).toList();
  }

  void addSection(int seekPosition) {
    if (!sections.contains(seekPosition)) {
      sections.add(seekPosition);
    }
  }

  void deleteSection(int seekPosition) {
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
  }

  void addVocalist(String vocalistName) {
    vocalistColorList[vocalistName] = 0xFF222222;
  }

  void deleteVocalist(String vocalistName) {
    vocalistColorList.remove(vocalistName);
    lyricSnippetList.removeWhere((snippet) => snippet.vocalist.name == vocalistName);
  }

void changeVocalistName(String oldName, String newName) {
  Map<String, int> updatedVocalistColorList = {};

  vocalistColorList.forEach((key, value) {
    if (key == oldName) {
      updatedVocalistColorList[newName] = value;
    } else {
      updatedVocalistColorList[key] = value;
    }
  });

  vocalistColorList = updatedVocalistColorList;

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
    snippet.vocalist = Vocalist(newName, 0);
  });
}

  Future<void> loadLyrics() async {
    try {
      rawLyricText = await rootBundle.loadString('assets/ウェルカムティーフレンド.xlrc');
      masterSubject.add(NotifyLyricLoaded(rawLyricText));

      lyricSnippetList = parseLyric(rawLyricText);
      masterSubject.add(NotifyLyricParsed(lyricSnippetList, vocalistColorList, vocalistCombinationCorrespondence));
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

  List<LyricSnippet> parseLyric(String rawLyricText) {
    final document = xml.XmlDocument.parse(rawLyricText);

    final vocalistCombination = document.findAllElements('VocalistsList');
    for (var vocalistName in vocalistCombination) {
      final colorElements = vocalistName.findElements('VocalistInfo');
      for (var colorElement in colorElements) {
        final name = colorElement.getAttribute('name')!;
        final color = int.parse(colorElement.getAttribute('color')!, radix: 16);
        vocalistColorList[name] = color + 0xFF000000;

        final vocalistNames = colorElement.findAllElements('Vocalist').map((e) => e.innerText).toList();
        if (vocalistNames.length >= 2) {
          vocalistCombinationCorrespondence[name] = vocalistNames;
        }
      }
    }

    final lineTimestamps = document.findAllElements('LineTimestamp');
    List<LyricSnippet> snippets = [];
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
      snippets.add(LyricSnippet(
        vocalist: Vocalist(vocalistName, 123456),
        index: 0,
        sentence: sentence,
        startTimestamp: startTime,
        sentenceSegments: sentenceSegments,
      ));
    }

    assignIndex(snippets);

    return snippets;
  }

  String serializeLyric(List<LyricSnippet> lyricSnippetList) {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('Lyrics', nest: () {
      for (var snippet in lyricSnippetList) {
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

  void assignIndex(List<LyricSnippet> snippets) {
    Map<Vocalist, int> idMap = {};

    snippets.sort((LyricSnippet a, LyricSnippet b) => a.startTimestamp.compareTo(b.startTimestamp));
    snippets.forEach((LyricSnippet snippet) {
      Vocalist vocalist = snippet.vocalist;
      if (!idMap.containsKey(vocalist)) {
        idMap[vocalist] = 1;
      } else {
        idMap[vocalist] = idMap[vocalist]! + 1;
      }
      snippet.index = idMap[vocalist]!;
    });
  }

  Future<void> writeTranslatedXmlToFile() async {
    final builder = xml.XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('Lyrics', nest: () {
      for (var snippet in lyricSnippetList) {
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
    return lyricSnippetList.where((snippet) {
      final endtime = snippet.startTimestamp + snippet.sentenceSegments.map((point) => point.wordDuration).reduce((a, b) => a + b);
      return snippet.startTimestamp < currentPosition && currentPosition < endtime;
    }).toList();
  }

  void divideSnippet(int index, int charPosition, int seekPosition) {
    if (index == -1) {
      return;
    }
    int snippetMargin = 100;
    String beforeString = lyricSnippetList[index].sentence.substring(0, charPosition);
    String afterString = lyricSnippetList[index].sentence.substring(charPosition);
    Vocalist vocalist = lyricSnippetList[index].vocalist;
    List<LyricSnippet> newSnippets = [];
    if (beforeString.isNotEmpty) {
      int snippetDuration = currentPosition - lyricSnippetList[index].startTimestamp;
      newSnippets.add(
        LyricSnippet(
          vocalist: vocalist,
          index: 0,
          sentence: beforeString,
          startTimestamp: lyricSnippetList[index].startTimestamp,
          sentenceSegments: [SentenceSegment(beforeString.length, snippetDuration)],
        ),
      );
    }
    if (afterString.isNotEmpty) {
      int snippetDuration = lyricSnippetList[index].endTimestamp - lyricSnippetList[index].startTimestamp - currentPosition - snippetMargin;
      newSnippets.add(
        LyricSnippet(
          vocalist: vocalist,
          index: 0,
          sentence: afterString,
          startTimestamp: currentPosition + snippetMargin,
          sentenceSegments: [SentenceSegment(afterString.length, snippetDuration)],
        ),
      );
    }
    if (newSnippets.isNotEmpty) {
      lyricSnippetList.removeAt(index);
      lyricSnippetList.insertAll(index, newSnippets);
      assignIndex(lyricSnippetList);
      masterSubject.add(NotifySnippetDivided(lyricSnippetList));
    }
  }

  void concatenateSnippets(List<LyricSnippet> snippets) {
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

        removeSnippetWithID(rightSnippet.id);
      }
    });
    assignIndex(lyricSnippetList);
    masterSubject.add(NotifySnippetConcatenated(lyricSnippetList));
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

  void addTimingPoint(LyricSnippet snippet, int characterPosition, int seekPosition) {
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
  }

  void deleteTimingPoint(LyricSnippet snippet, int characterPosition, Option option) {
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
  }

  void pushUndoHistory(List<LyricSnippet> lyricSnippetList) {
    List<LyricSnippet> copy = lyricSnippetList.map((snippet) {
      return LyricSnippet(
        vocalist: Vocalist(snippet.vocalist.name, vocalistColorList[snippet.vocalist.name]!),
        index: snippet.index,
        sentence: snippet.sentence,
        startTimestamp: snippet.startTimestamp,
        sentenceSegments: snippet.sentenceSegments.map((point) {
          return SentenceSegment(point.wordLength, point.wordDuration);
        }).toList(),
      );
    }).toList();
    undoHistory.add(copy);
  }

  List<LyricSnippet> popUndoHistory() {
    if (undoHistory.isEmpty) {
      return [];
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
