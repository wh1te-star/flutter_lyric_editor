import 'dart:io';
import 'package:collection/collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:xml/xml.dart' as xml;

final timingMasterProvider = ChangeNotifierProvider((ref) {
  final musicPlayerService = ref.watch(musicPlayerMasterProvider);
  return TimingService(musicPlayerService);
});

class TimingService extends ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;

  TimingService(this.musicPlayerProvider) {
    _loadLyricsFuture = loadLyrics();
  }

  String rawLyricText = "";
  List<List<LyricSnippet>> _undoHistory = [];

  Map<String, int> _vocalistColorList = {};
  Map<String, List<String>> _vocalistCombinationCorrespondence = {};
  List<LyricSnippet> _lyricSnippetList = [];
  Future<void>? _loadLyricsFuture;

  Map<String, int> get vocalistColorList => _vocalistColorList;
  Map<String, List<String>> get vocalistCombinationCorrespondence => _vocalistCombinationCorrespondence;
  List<LyricSnippet> get lyricSnippetList => _lyricSnippetList;
  Future<void>? get loadLyricsFuture => _loadLyricsFuture;

  String defaultVocalistName = "vocalist 1";

  void requestInitLyric(String rawText) async {
    int audioDuration = musicPlayerProvider.audioDuration;
    String singlelineText = rawText.replaceAll("\n", "").replaceAll("\r", "");
    _lyricSnippetList.clear();
    _lyricSnippetList.add(LyricSnippet(
      vocalist: Vocalist(defaultVocalistName, 0),
      index: 1,
      sentence: singlelineText,
      startTimestamp: 0,
      timingPoints: [TimingPoint(singlelineText.length, audioDuration)],
    ));

    _vocalistColorList.clear();
    _vocalistColorList[defaultVocalistName] = 0xff777777;

    notifyListeners();
  }

  void requestLoadLyric(String rawText) async {
    rawLyricText = rawText;
    _lyricSnippetList = parseLyric(rawText);
    notifyListeners();
  }

  void requestExportLyric(FileSaveLocation result) async {
    final String rawLyricText = serializeLyric(_lyricSnippetList);
    final File file = File(result.path);
    await file.writeAsString(rawLyricText);
    notifyListeners();
  }

  void requestAddVocalist(String vocalistName) {
    pushUndoHistory(_lyricSnippetList);

    addVocalist(vocalistName);
    notifyListeners();
  }

  void requestDeleteVocalist(String vocalistName) {
    pushUndoHistory(_lyricSnippetList);

    deleteVocalist(vocalistName);
    notifyListeners();
  }

  void requestChangeVocalistName(String oldName, String newName) {
    pushUndoHistory(_lyricSnippetList);

    changeVocalistName(oldName, newName);
    notifyListeners();
  }

  void requestToAddLyricTiming(LyricSnippetID snippetID, int characterPosition, int seekPosition) {
    LyricSnippet snippet = getSnippetWithID(snippetID);
    addTimingPoint(snippet, characterPosition, seekPosition);
  }

  void requestToDeleteLyricTiming(LyricSnippetID snippetID, int characterPosition, Choice choice) {
    LyricSnippet snippet = getSnippetWithID(snippetID);
    deleteTimingPoint(snippet, characterPosition, choice);
    notifyListeners();
  }

  void requestDivideSnippet(LyricSnippetID snippetID, int characterPosition) {
    int index = getSnippetIndexWithID(snippetID);
    int currentPosition = musicPlayerProvider.seekPosition;
    divideSnippet(index, characterPosition, currentPosition);
    notifyListeners();
  }

  void requestConcatenateSnippet(List<LyricSnippetID> snippetIDs) {
    List<LyricSnippet> snippets = translateIDsToSnippets(snippetIDs);
    concatenateSnippets(snippets);
    notifyListeners();
  }

  void requestSnippetMove(LyricSnippetID snippetID, SnippetEdge snippetEdge, bool holdLength) {
    pushUndoHistory(_lyricSnippetList);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    int currentPosition = musicPlayerProvider.audioDuration;
    if (holdLength) {
      if (snippetEdge == SnippetEdge.start) {
        moveSnippet(snippet, snippet.startTimestamp - currentPosition);
      } else {
        moveSnippet(snippet, currentPosition - snippet.endTimestamp);
      }
    } else {
      if (snippetEdge == SnippetEdge.start) {
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
    notifyListeners();
  }

  void requestUndo() {
    _lyricSnippetList = popUndoHistory();
    assignIndex(_lyricSnippetList);
    notifyListeners();
  }
  /* Define music player provider callback
      if (signal is NotifySeekPosition) {
        currentPosition = signal.seekPosition;
      }
      if (signal is NotifyAudioFileLoaded) {
        audioDuration = signal.millisec;
      }
      */

  List<LyricSnippet> translateIDsToSnippets(List<LyricSnippetID> ids) {
    return ids.map((id) => getSnippetWithID(id)).toList();
  }

  int getSnippetIndexWithID(LyricSnippetID id) {
    return _lyricSnippetList.indexWhere((snippet) => snippet.id == id);
  }

  LyricSnippet getSnippetWithID(LyricSnippetID id) {
    return _lyricSnippetList.firstWhere((snippet) => snippet.id == id);
  }

  void removeSnippetWithID(LyricSnippetID id) {
    _lyricSnippetList.removeWhere((snippet) => snippet.id == id);
  }

  List<LyricSnippet> getSnippetsWithVocalistName(String vocalistName) {
    return _lyricSnippetList.where((snippet) => snippet.vocalist.name == vocalistName).toList();
  }

  void addVocalist(String vocalistName) {
    _vocalistColorList[vocalistName] = 0xFF222222;
    _lyricSnippetList.add(LyricSnippet(vocalist: Vocalist(vocalistName, 0), index: 0, sentence: "", startTimestamp: 0, timingPoints: [TimingPoint(0, 1)]));
  }

  void deleteVocalist(String vocalistName) {
    _vocalistColorList.remove(vocalistName);
    _lyricSnippetList.removeWhere((snippet) => snippet.vocalist.name == vocalistName);
  }

  void changeVocalistName(String oldName, String newName) {
    Map<String, List<String>> updatedMap = {};

    _vocalistCombinationCorrespondence.forEach((String key, List<String> value) {
      int index = value.indexOf(oldName);
      if (index != -1) {
        value[index] = newName;
        updatedMap[value.join(", ")] = value;
      } else {
        updatedMap[key] = value;
      }
    });

    _vocalistCombinationCorrespondence = updatedMap;

    _vocalistColorList[newName] = _vocalistColorList[oldName]!;
    _vocalistColorList.remove(oldName);

    getSnippetsWithVocalistName(oldName).forEach((LyricSnippet snippet) {
      snippet.vocalist = Vocalist(newName, 0);
    });
  }

  Future<void> loadLyrics() async {
    try {
      rawLyricText = await rootBundle.loadString('assets/ウェルカムティーフレンド.xlrc');
      notifyListeners();

      _lyricSnippetList = parseLyric(rawLyricText);
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

  List<LyricSnippet> parseLyric(String rawLyricText) {
    final document = xml.XmlDocument.parse(rawLyricText);

    final vocalistCombination = document.findAllElements('VocalistsColor');
    for (var vocalistName in vocalistCombination) {
      final colorElements = vocalistName.findElements('Color');
      for (var colorElement in colorElements) {
        final name = colorElement.getAttribute('name')!;
        final color = int.parse(colorElement.getAttribute('color')!, radix: 16);
        _vocalistColorList[name] = color + 0xFF000000;

        final vocalistNames = colorElement.findAllElements('Vocalist').map((e) => e.innerText).toList();
        if (vocalistNames.length >= 2) {
          _vocalistCombinationCorrespondence[name] = vocalistNames;
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
                nest: snippet.sentence.substring(characterPosition, characterPosition + timingPoint.wordLength));
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
      for (var snippet in _lyricSnippetList) {
        builder.element('LineTimestamp', attributes: {
          'vocalistName': snippet.vocalist.name,
          'startTime': _formatTimestamp(snippet.startTimestamp),
        }, nest: () {
          int characterPosition = 0;
          for (int i = 0; i < snippet.timingPoints.length; i++) {
            final currentPoint = snippet.timingPoints[i];
            final nextPoint = i < snippet.timingPoints.length - 1 ? snippet.timingPoints[i + 1] : null;

            final endtime = snippet.timingPoints.map((point) => point.wordDuration).reduce((a, b) => a + b);
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
    String first30Chars = rawLyricText.substring(0, 30);
    debugPrint(first30Chars);
  }

  List<LyricSnippet> getSnippetsAtCurrentSeekPosition() {
    return _lyricSnippetList.where((snippet) {
      final endtime = snippet.startTimestamp + snippet.timingPoints.map((point) => point.wordDuration).reduce((a, b) => a + b);
      int currentPosition = musicPlayerProvider.seekPosition;
      return snippet.startTimestamp < currentPosition && currentPosition < endtime;
    }).toList();
  }

  void divideSnippet(int index, int charPosition, int seekPosition) {
    if (index == -1) {
      return;
    }
    int snippetMargin = 100;
    String beforeString = _lyricSnippetList[index].sentence.substring(0, charPosition);
    String afterString = _lyricSnippetList[index].sentence.substring(charPosition);
    Vocalist vocalist = _lyricSnippetList[index].vocalist;
    List<LyricSnippet> newSnippets = [];
    int currentPosition = musicPlayerProvider.seekPosition;
    if (beforeString.isNotEmpty) {
      int snippetDuration = currentPosition - _lyricSnippetList[index].startTimestamp;
      newSnippets.add(
        LyricSnippet(
          vocalist: vocalist,
          index: 0,
          sentence: beforeString,
          startTimestamp: _lyricSnippetList[index].startTimestamp,
          timingPoints: [TimingPoint(beforeString.length, snippetDuration)],
        ),
      );
    }
    if (afterString.isNotEmpty) {
      int snippetDuration = _lyricSnippetList[index].endTimestamp - _lyricSnippetList[index].startTimestamp - currentPosition - snippetMargin;
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
    if (newSnippets.isNotEmpty) {
      _lyricSnippetList.removeAt(index);
      _lyricSnippetList.insertAll(index, newSnippets);
      assignIndex(_lyricSnippetList);
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
        leftSnippet.timingPoints.last.wordDuration += extendDuration;
        leftSnippet.sentence += rightSnippet.sentence;
        leftSnippet.timingPoints.addAll(rightSnippet.timingPoints);

        removeSnippetWithID(rightSnippet.id);
      }
    });
    assignIndex(_lyricSnippetList);
  }

  void moveSnippet(LyricSnippet snippet, int shiftDuration) {
    snippet.startTimestamp += shiftDuration;
  }

  void extendSnippet(LyricSnippet snippet, SnippetEdge snippetEdge, int extendDuration) {
    assert(extendDuration >= 0, "Should be shorten function.");
    if (snippetEdge == SnippetEdge.start) {
      snippet.startTimestamp -= extendDuration;
      snippet.timingPoints.first.wordDuration += extendDuration;
    } else {
      snippet.timingPoints.last.wordDuration += extendDuration;
    }
  }

  void shortenSnippet(LyricSnippet snippet, SnippetEdge snippetEdge, int shortenDuration) {
    assert(shortenDuration >= 0, "Should be extend function.");
    if (snippetEdge == SnippetEdge.start) {
      int index = 0;
      int rest = shortenDuration;
      while (index < snippet.timingPoints.length && rest - snippet.timingPoints[index].wordDuration > 0) {
        rest -= snippet.timingPoints[index].wordDuration;
        index++;
      }
      snippet.startTimestamp += shortenDuration;
      snippet.timingPoints = snippet.timingPoints.sublist(index);
      snippet.timingPoints.first.wordDuration -= rest;
    } else {
      int index = snippet.timingPoints.length - 1;
      int rest = shortenDuration;
      while (index >= 0 && rest - snippet.timingPoints[index].wordDuration > 0) {
        rest -= snippet.timingPoints[index].wordDuration;
        index--;
      }
      snippet.timingPoints = snippet.timingPoints.sublist(0, index + 1);
      snippet.timingPoints.last.wordDuration -= rest;
    }
  }

  void addTimingPoint(LyricSnippet snippet, int characterPosition, int seekPosition) {
    int index = 0;
    int restWordLength = characterPosition;
    while (index < snippet.timingPoints.length && restWordLength - snippet.timingPoints[index].wordLength > 0) {
      restWordLength -= snippet.timingPoints[index].wordLength;
      index++;
    }
    int seekIndex = 0;
    int restWordDuration = seekPosition - snippet.startTimestamp;
    while (seekIndex < snippet.timingPoints.length && restWordDuration - snippet.timingPoints[seekIndex].wordDuration > 0) {
      restWordDuration -= snippet.timingPoints[seekIndex].wordDuration;
      seekIndex++;
    }
    if (index != seekIndex) {
      debugPrint("There is the contradiction in the order between the character position and the seek position.");
      return;
    }
    if (restWordLength != 0) {
      snippet.timingPoints[index] = TimingPoint(snippet.timingPoints[index].wordLength - restWordLength, snippet.timingPoints[index].wordDuration - restWordDuration);
      snippet.timingPoints.insert(index, TimingPoint(restWordLength, restWordDuration));
    }
  }

  void deleteTimingPoint(LyricSnippet snippet, int characterPosition, Choice choice) {
    int index = 0;
    int position = 0;
    while (index < snippet.timingPoints.length && position < characterPosition) {
      position += snippet.timingPoints[index].wordLength;
      index++;
    }
    if (position != characterPosition) return;
    snippet.timingPoints[index - 1].wordLength += snippet.timingPoints[index].wordLength;
    snippet.timingPoints[index - 1].wordDuration += snippet.timingPoints[index].wordDuration;
    snippet.timingPoints.removeAt(index);
  }

  void pushUndoHistory(List<LyricSnippet> lyricSnippetList) {
    List<LyricSnippet> copy = lyricSnippetList.map((snippet) {
      return LyricSnippet(
        vocalist: Vocalist(snippet.vocalist.name, _vocalistColorList[snippet.vocalist.name]!),
        index: snippet.index,
        sentence: snippet.sentence,
        startTimestamp: snippet.startTimestamp,
        timingPoints: snippet.timingPoints.map((point) {
          return TimingPoint(point.wordLength, point.wordDuration);
        }).toList(),
      );
    }).toList();
    _undoHistory.add(copy);
  }

  List<LyricSnippet> popUndoHistory() {
    if (_undoHistory.isEmpty) {
      return [];
    }
    return _undoHistory.removeLast();
  }
}

enum Choice {
  former,
  latter,
}

enum SnippetEdge {
  start,
  end,
}
