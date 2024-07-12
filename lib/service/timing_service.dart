import 'dart:collection';
import 'dart:io';
import 'package:collection/collection.dart';
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
  Future<void>? _loadLyricsFuture;
  int currentPosition = 0;
  int audioDuration = 180000;

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
          String singlelineText =
              rawText.replaceAll("\n", "").replaceAll("\r", "");
          lyricSnippetList.clear();
          lyricSnippetList.add(LyricSnippet(
            vocalist: Vocalist("vocalist 1", 0),
            index: 1,
            sentence: singlelineText,
            startTimestamp: 0,
            timingPoints: [TimingPoint(singlelineText.length, audioDuration)],
          ));
          masterSubject.add(NotifyLyricParsed(lyricSnippetList));
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
          masterSubject.add(NotifyLyricParsed(lyricSnippetList));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No file selected')),
          );
        }
      }
      if (signal is RequestExportLyric) {
        const String fileName = 'example.xlrc';
        final FileSaveLocation? result =
            await getSaveLocation(suggestedName: fileName);
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
      if (signal is RequestAddVocalist) {
        addVocalist(signal.vocalistName);
        masterSubject.add(NotifyVocalistAdded(lyricSnippetList));
      }
      if (signal is RequestDeleteVocalist) {
        deleteVocalist(signal.vocalistName);
        masterSubject.add(NotifyVocalistDeleted(lyricSnippetList));
      }
      if (signal is RequestChangeVocalistName) {
        getSnippetsWithVocalistName(signal.oldName)
            .forEach((LyricSnippet snippet) {
          snippet.vocalist = Vocalist(signal.newName, 0);
        });
        masterSubject.add(NotifyVocalistNameChanged(lyricSnippetList));
      }
      if (signal is RequestToAddLyricTiming) {
        LyricSnippet snippet = getSnippetWithID(signal.snippetID);
        addTimingPoint(snippet, signal.characterPosition, signal.seekPosition);
        masterSubject.add(
            NotifyTimingPointAdded(signal.snippetID, snippet.timingPoints));
      }
      if (signal is RequestToDeleteLyricTiming) {
        LyricSnippet snippet = getSnippetWithID(signal.snippetID);
        deleteTimingPoint(snippet, signal.characterPosition, signal.choice);
        masterSubject.add(NotifyTimingPointDeletion(signal.characterPosition));
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
              extendSnippet(snippet, SnippetEdge.start,
                  snippet.startTimestamp - currentPosition);
            } else if (snippet.startTimestamp < currentPosition) {
              shortenSnippet(snippet, SnippetEdge.start,
                  currentPosition - snippet.startTimestamp);
            }
          } else {
            if (currentPosition < snippet.endTimestamp) {
              shortenSnippet(snippet, SnippetEdge.end,
                  snippet.endTimestamp - currentPosition);
            } else if (snippet.endTimestamp < currentPosition) {
              extendSnippet(snippet, SnippetEdge.end,
                  currentPosition - snippet.endTimestamp);
            }
          }
        }
        masterSubject.add(NotifySnippetMove(lyricSnippetList));
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
    return lyricSnippetList
        .where((snippet) => snippet.vocalist.name == vocalistName)
        .toList();
  }

  void addVocalist(String vocalistName) {
    lyricSnippetList.add(LyricSnippet(
        vocalist: Vocalist(vocalistName, 0),
        index: 0,
        sentence: "",
        startTimestamp: 0,
        timingPoints: [TimingPoint(0, 1)]));
  }

  void deleteVocalist(String vocalistName) {
    lyricSnippetList
        .removeWhere((snippet) => snippet.vocalist.name == vocalistName);
  }

  Future<void> loadLyrics() async {
    try {
      rawLyricText = await rootBundle.loadString('assets/ウェルカムティーフレンド.xlrc');
      masterSubject.add(NotifyLyricLoaded(rawLyricText));

      lyricSnippetList = parseLyric(rawLyricText);
      masterSubject.add(NotifyLyricParsed(lyricSnippetList));
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

    final vocalistCombination = document.findAllElements('VocalistsColor');
    for (var vocalistName in vocalistCombination) {
      final colorElements = vocalistName.findElements('Color');
      for (var colorElement in colorElements) {
        final name = colorElement.getAttribute('name')!;
        final color = int.parse(colorElement.getAttribute('color')!, radix: 16);
        vocalistColorList[name] = color;

        final vocalistNames = colorElement
            .findAllElements('Vocalist')
            .map((e) => e.innerText)
            .toList();
        if (vocalistNames.length >= 2) {
          vocalistCombinationCorrespondence[name] = vocalistNames;
        }
      }
    }

    final lineTimestamps = document.findAllElements('LineTimestamp');
    List<LyricSnippet> snippets = [];
    for (var lineTimestamp in lineTimestamps) {
      final startTime =
          parseTimestamp(lineTimestamp.getAttribute('startTime')!);
      final vocalistName = lineTimestamp.getAttribute('vocalistName')!;

      final wordTimestamps = lineTimestamp.findElements('WordTimestamp');
      String sentence = '';
      List<TimingPoint> timingPoints = [];

      for (var wordTimestamp in wordTimestamps) {
        final time = parseTimestamp(wordTimestamp.getAttribute('time')!);
        final word = wordTimestamp.innerText;
        timingPoints.add(TimingPoint(word.length, time));
        sentence += word;
      }
      snippets.add(LyricSnippet(
        vocalist: Vocalist(vocalistName, 123456),
        index: 0,
        sentence: sentence,
        startTimestamp: startTime,
        timingPoints: timingPoints,
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
          for (var timingPoint in snippet.timingPoints) {
            builder.element('WordTimestamp',
                attributes: {
                  'time': _formatTimestamp(timingPoint.wordDuration),
                },
                nest: snippet.sentence.substring(characterPosition,
                    characterPosition + timingPoint.wordLength));
            characterPosition += timingPoint.wordLength;
          }
        });
      }
    });

    final document = builder.buildDocument();
    return document.toXmlString(pretty: true, indent: '  ');
  }

  void assignIndex(List<LyricSnippet> snippets) {
    Map<Vocalist, int> idMap = {};

    snippets.sort((LyricSnippet a, LyricSnippet b) =>
        a.startTimestamp.compareTo(b.startTimestamp));
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
          for (int i = 0; i < snippet.timingPoints.length; i++) {
            final currentPoint = snippet.timingPoints[i];
            final nextPoint = i < snippet.timingPoints.length - 1
                ? snippet.timingPoints[i + 1]
                : null;

            final endtime = snippet.timingPoints
                .map((point) => point.wordDuration)
                .reduce((a, b) => a + b);
            final duration = nextPoint != null
                ? nextPoint.wordDuration - currentPoint.wordDuration
                : endtime - currentPoint.wordDuration;

            builder.element('WordTimestamp',
                attributes: {
                  'time': _formatDuration(Duration(milliseconds: duration)),
                },
                nest: snippet.sentence.substring(characterPosition,
                    characterPosition + currentPoint.wordLength));
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
    final milliseconds =
        duration.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
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
      final endtime = snippet.startTimestamp +
          snippet.timingPoints
              .map((point) => point.wordDuration)
              .reduce((a, b) => a + b);
      return snippet.startTimestamp < currentPosition &&
          currentPosition < endtime;
    }).toList();
  }

  void divideSnippet(int index, int charPosition, int seekPosition) {
    int snippetMargin = 100;
    String beforeString =
        lyricSnippetList[index].sentence.substring(0, charPosition);
    String afterString =
        lyricSnippetList[index].sentence.substring(charPosition);
    Vocalist vocalist = lyricSnippetList[index].vocalist;
    List<LyricSnippet> newSnippets = [];
    if (beforeString.isNotEmpty) {
      int snippetDuration =
          currentPosition - lyricSnippetList[index].startTimestamp;
      newSnippets.add(
        LyricSnippet(
          vocalist: vocalist,
          index: 0,
          sentence: beforeString,
          startTimestamp: lyricSnippetList[index].startTimestamp,
          timingPoints: [TimingPoint(beforeString.length, snippetDuration)],
        ),
      );
    }
    if (afterString.isNotEmpty) {
      int snippetDuration = lyricSnippetList[index].endTimestamp -
          lyricSnippetList[index].startTimestamp -
          currentPosition -
          snippetMargin;
      newSnippets.add(
        LyricSnippet(
          vocalist: vocalist,
          index: 0,
          sentence: afterString,
          startTimestamp: currentPosition + snippetMargin,
          timingPoints: [TimingPoint(afterString.length, snippetDuration)],
        ),
      );
    }
    if (index != -1) {
      lyricSnippetList.removeAt(index);
      lyricSnippetList.insertAll(index, newSnippets);
    }
    assignIndex(lyricSnippetList);
    masterSubject.add(NotifySnippetDivided(lyricSnippetList));
  }

  void concatenateSnippets(List<LyricSnippet> snippets) {
    Map<Vocalist, List<LyricSnippet>> snippetsForeachVocalist = groupBy(
      snippets,
      (LyricSnippet snippet) => snippet.vocalist,
    );
    snippetsForeachVocalist.forEach((vocalist, vocalistSnippets) {
      vocalistSnippets
          .sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));
      for (int index = 1; index < vocalistSnippets.length; index++) {
        LyricSnippet leftSnippet = vocalistSnippets[0];
        LyricSnippet rightSnippet = vocalistSnippets[index];
        late final int extendDuration;
        if (leftSnippet.endTimestamp <= rightSnippet.startTimestamp) {
          extendDuration =
              rightSnippet.startTimestamp - leftSnippet.endTimestamp;
        } else {
          extendDuration = 0;
        }
        leftSnippet.timingPoints.last.wordDuration += extendDuration;
        leftSnippet.sentence += rightSnippet.sentence;
        leftSnippet.timingPoints.addAll(rightSnippet.timingPoints);

        removeSnippetWithID(rightSnippet.id);
      }
    });
    assignIndex(lyricSnippetList);
    masterSubject.add(NotifySnippetConcatenated(lyricSnippetList));
  }

  void moveSnippet(LyricSnippet snippet, int shiftDuration) {
    snippet.startTimestamp += shiftDuration;
  }

  void extendSnippet(
      LyricSnippet snippet, SnippetEdge snippetEdge, int extendDuration) {
    assert(extendDuration >= 0, "Should be shorten function.");
    if (snippetEdge == SnippetEdge.start) {
      snippet.startTimestamp -= extendDuration;
      snippet.timingPoints.first.wordDuration += extendDuration;
    } else {
      snippet.timingPoints.last.wordDuration += extendDuration;
    }
  }

  void shortenSnippet(
      LyricSnippet snippet, SnippetEdge snippetEdge, int shortenDuration) {
    assert(shortenDuration >= 0, "Should be extend function.");
    if (snippetEdge == SnippetEdge.start) {
      int index = 0;
      int rest = shortenDuration;
      while (index < snippet.timingPoints.length &&
          rest - snippet.timingPoints[index].wordDuration > 0) {
        rest -= snippet.timingPoints[index].wordDuration;
        index++;
      }
      snippet.startTimestamp += shortenDuration;
      snippet.timingPoints = snippet.timingPoints.sublist(index);
      snippet.timingPoints.first.wordDuration -= rest;
    } else {
      int index = snippet.timingPoints.length - 1;
      int rest = shortenDuration;
      while (
          index >= 0 && rest - snippet.timingPoints[index].wordDuration > 0) {
        rest -= snippet.timingPoints[index].wordDuration;
        index--;
      }
      snippet.timingPoints = snippet.timingPoints.sublist(0, index + 1);
      snippet.timingPoints.last.wordDuration -= rest;
    }
  }

  void addTimingPoint(
      LyricSnippet snippet, int characterPosition, int seekPosition) {
    int index = 0;
    int restWordLength = characterPosition;
    while (index < snippet.timingPoints.length &&
        restWordLength - snippet.timingPoints[index].wordLength > 0) {
      restWordLength -= snippet.timingPoints[index].wordLength;
      index++;
    }
    int seekIndex = 0;
    int restWordDuration = seekPosition - snippet.startTimestamp;
    while (seekIndex < snippet.timingPoints.length &&
        restWordDuration - snippet.timingPoints[seekIndex].wordDuration > 0) {
      restWordDuration -= snippet.timingPoints[seekIndex].wordDuration;
      seekIndex++;
    }
    if (index != seekIndex) {
      debugPrint(
          "There is the contradiction in the order between the character position and the seek position.");
      return;
    }
    if (restWordLength != 0) {
      snippet.timingPoints[index] = TimingPoint(
          snippet.timingPoints[index].wordLength - restWordLength,
          snippet.timingPoints[index].wordDuration - restWordDuration);
      snippet.timingPoints
          .insert(index, TimingPoint(restWordLength, restWordDuration));
    }
  }

  void deleteTimingPoint(
      LyricSnippet snippet, int characterPosition, Choice choice) {
    int index = 0;
    int position = 0;
    while (
        index < snippet.timingPoints.length && position < characterPosition) {
      position += snippet.timingPoints[index].wordLength;
      index++;
    }
    if (position != characterPosition) return;
    snippet.timingPoints[index].wordLength +=
        snippet.timingPoints[index + 1].wordLength;
    snippet.timingPoints[index].wordDuration +=
        snippet.timingPoints[index + 1].wordDuration;
    snippet.timingPoints.removeAt(index + 1);
  }
}
