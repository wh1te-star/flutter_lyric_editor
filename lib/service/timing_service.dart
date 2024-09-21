import 'dart:io';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/undo_history.dart';
import 'package:xml/xml.dart' as xml;

final timingMasterProvider = ChangeNotifierProvider((ref) {
  final musicPlayerService = ref.read(musicPlayerMasterProvider);
  return TimingService(musicPlayerProvider: musicPlayerService);
});

class TimingService extends ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;

  Map<SnippetID, LyricSnippet> lyricSnippetList = {};
  Map<VocalistID, Vocalist> vocalistColorMap = {};
  List<int> sections = [];

  final SnippetIdGenerator _snippetIdGenerator = SnippetIdGenerator();
  final VocalistIdGenerator _vocalistIdGenerator = VocalistIdGenerator();

  LyricUndoHistory undoHistory = LyricUndoHistory();

  String defaultVocalistName = "Vocalist Name";
  String vocalistNameSeparator = ", ";

  TimingService({
    required this.musicPlayerProvider,
  });

  Map<VocalistID, Map<SnippetID, LyricSnippet>> get snippetsForeachVocalist {
    return groupBy(
      lyricSnippetList.entries,
      (MapEntry<SnippetID, LyricSnippet> entry) {
        return entry.value.vocalistID;
      },
    ).map(
      (VocalistID vocalistID, List<MapEntry<SnippetID, LyricSnippet>> snippets) => MapEntry(
        vocalistID,
        {for (var entry in snippets) entry.key: entry.value},
      ),
    );
  }

  void sortLyricSnippetList() {
    lyricSnippetList = Map.fromEntries(
      lyricSnippetList.entries.toList()
        ..sort(
          (a, b) {
            int compareStartTime = a.value.startTimestamp.compareTo(b.value.startTimestamp);
            if (compareStartTime != 0) {
              return compareStartTime;
            } else {
              return a.value.vocalistID.id.compareTo(b.value.vocalistID.id);
            }
          },
        ),
    );
  }

  Map<SnippetID, LyricSnippet> getCurrentSeekPositionSnippets() {
    int seekPosition = musicPlayerProvider.seekPosition;

    return Map.fromEntries(
      lyricSnippetList.entries.where((entry) {
        return entry.value.startTimestamp <= seekPosition && seekPosition <= entry.value.endTimestamp;
      }),
    );
  }

  int getLanes({VocalistID? vocalistID}) {
    List<LyricSnippet> snippets = vocalistID != null ? snippetsForeachVocalist[vocalistID]?.values.toList() ?? [] : lyricSnippetList.values.toList();
    if (snippets.isEmpty) return 1;
    int maxOverlap = 1;
    int currentOverlap = 1;
    int currentEndTime = snippets.first.endTimestamp;

    for (int i = 1; i < snippets.length; ++i) {
      int start = snippets[i].startTimestamp;
      int end = snippets[i].endTimestamp;
      if (start <= currentEndTime) {
        currentOverlap++;
      } else {
        currentOverlap = 1;
        currentEndTime = end;
      }
      if (currentOverlap > maxOverlap) {
        maxOverlap = currentOverlap;
      }
    }

    return maxOverlap;
  }

  void initLyric(String rawText) {
    int audioDuration = musicPlayerProvider.audioDuration;

    vocalistColorMap.clear();
    vocalistColorMap[_vocalistIdGenerator.idGen()] = Vocalist(name: defaultVocalistName, color: 0xff777777);

    String singlelineText = rawText.replaceAll("\n", "").replaceAll("\r", "");
    lyricSnippetList.clear();
    lyricSnippetList[_snippetIdGenerator.idGen()] = LyricSnippet(
      vocalistID: vocalistColorMap.keys.first,
      startTimestamp: 0,
      sentenceSegments: [SentenceSegment(singlelineText, audioDuration)],
      annotation: [],
    );
    sortLyricSnippetList();

    notifyListeners();
  }

  void loadLyric(String rawLyricText) {
    lyricSnippetList = parseLyric(rawLyricText);
    sortLyricSnippetList();

    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetList);
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

  bool isBitTrue(VocalistID targetID, VocalistID singleID) {
    return (targetID.id & singleID.id) != 0;
  }

  String generateVocalistCombinationNameFromID(VocalistID vocalistID) {
    int signalBitID = 1;
    String vocalistName = "";
    while (signalBitID < vocalistColorMap.keys.toList().last.id) {
      if (isBitTrue(vocalistID, VocalistID(signalBitID))) {
        vocalistName += vocalistNameSeparator;
        vocalistName += vocalistColorMap[VocalistID(signalBitID)]!.name;
      }
      signalBitID *= 2;
    }

    vocalistName = vocalistName.substring(vocalistNameSeparator.length);
    return vocalistName;
  }

  VocalistID getVocalistIDWithName(String vocalistName) {
    final entry = vocalistColorMap.entries.firstWhere(
      (entry) => entry.value.name == vocalistName,
      orElse: () => throw Exception('Vocalist not found'),
    );
    return entry.key;
  }

  Vocalist getVocalistWithName(String vocalistName) {
    final entry = vocalistColorMap.entries.firstWhere(
      (entry) => entry.value.name == vocalistName,
      orElse: () => throw Exception('Vocalist not found'),
    );
    return entry.value;
  }

  LyricSnippet getSnippetWithID(SnippetID id) {
    return lyricSnippetList[id]!;
  }

  void removeSnippetWithID(SnippetID id) {
    lyricSnippetList.remove(id);
  }

  List<LyricSnippet> getSnippetsWithVocalistName(String vocalistName) {
    return lyricSnippetList.values.where((snippet) => vocalistColorMap[snippet.vocalistID]!.name == vocalistName).toList();
  }

  void addSection(int seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.section, sections);

    if (!sections.contains(seekPosition)) {
      sections.add(seekPosition);
    }

    notifyListeners();
  }

  void deleteSection(int seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.section, sections);

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
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);

    vocalistColorMap[_vocalistIdGenerator.idGen()] = Vocalist(name: vocalistName, color: 0xFF222222);

    notifyListeners();
  }

  void deleteVocalist(String vocalistName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);

    VocalistID id = getVocalistIDWithName(vocalistName);
    vocalistColorMap.remove(id);
    lyricSnippetList.removeWhere((id, snippet) => vocalistColorMap[snippet.vocalistID]!.name == vocalistName);

    notifyListeners();
  }

  void changeVocalistName(String oldName, String newName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);

    VocalistID vocalistID = getVocalistIDWithName(oldName);
    vocalistColorMap[vocalistID]!.name = newName;

    for (MapEntry<VocalistID, Vocalist> entry in vocalistColorMap.entries) {
      VocalistID id = entry.key;
      Vocalist vocalist = entry.value;
      if (id.id != vocalistID.id && isBitTrue(id, vocalistID)) {
        vocalist.name = generateVocalistCombinationNameFromID(id);
      }
    }

    notifyListeners();
  }

  Future<void> loadExampleLyrics() async {
    try {
      String rawLyricText = await rootBundle.loadString('assets/ウェルカムティーフレンド.xlrc');

      lyricSnippetList = parseLyric(rawLyricText);
      sortLyricSnippetList();
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

        final vocalistNames = colorElement.findAllElements('Vocalist').map((e) => e.innerText).toList();
        if (vocalistNames.length == 1) {
          vocalistColorMap[_vocalistIdGenerator.idGen()] = Vocalist(name: name, color: color + 0xFF000000);
        } else {
          int combinationID = 0;
          for (String vocalistName in vocalistNames) {
            combinationID += getVocalistIDWithName(vocalistName).id;
          }
          vocalistColorMap[VocalistID(combinationID)] = Vocalist(name: name, color: color + 0xFF000000);
        }
      }
    }

    final lineTimestamps = document.findAllElements('LineTimestamp');
    Map<SnippetID, LyricSnippet> snippets = {};
    for (var lineTimestamp in lineTimestamps) {
      final startTime = parseTimestamp(lineTimestamp.getAttribute('startTime')!);
      final vocalistName = lineTimestamp.getAttribute('vocalistName')!;

      final wordTimestamps = lineTimestamp.findElements('WordTimestamp');
      List<SentenceSegment> sentenceSegments = [];

      for (var wordTimestamp in wordTimestamps) {
        final time = parseTimestamp(wordTimestamp.getAttribute('time')!);
        final word = wordTimestamp.innerText;
        sentenceSegments.add(SentenceSegment(word, time));
      }
      snippets[_snippetIdGenerator.idGen()] = LyricSnippet(
        vocalistID: getVocalistIDWithName(vocalistName),
        startTimestamp: startTime,
        sentenceSegments: sentenceSegments,
        annotation: [],
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
          'vocalistName': vocalistColorMap[snippet.vocalistID]!.name,
          'startTime': _formatTimestamp(snippet.startTimestamp),
        }, nest: () {
          for (var sentenceSegment in snippet.sentenceSegments) {
            builder.element(
              'WordTimestamp',
              attributes: {
                'time': _formatTimestamp(sentenceSegment.duration),
              },
              nest: sentenceSegment.word,
            );
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
          'vocalistName': vocalistColorMap[snippet.vocalistID]!.name,
          'startTime': _formatTimestamp(snippet.startTimestamp),
        }, nest: () {
          for (int i = 0; i < snippet.sentenceSegments.length; i++) {
            final currentSegment = snippet.sentenceSegments[i];
            final duration = currentSegment.duration;

            builder.element(
              'WordTimestamp',
              attributes: {
                'time': _formatDuration(Duration(milliseconds: duration)),
              },
              nest: snippet.sentenceSegments[i].word,
            );
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

  void divideSnippet(SnippetID snippetID, int charPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetList);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    int seekPosition = musicPlayerProvider.seekPosition;
    int snippetMargin = 100;
    String beforeString = snippet.sentence.substring(0, charPosition);
    String afterString = snippet.sentence.substring(charPosition);
    VocalistID vocalistID = snippet.vocalistID;
    Map<SnippetID, LyricSnippet> newSnippets = {};
    if (beforeString.isNotEmpty) {
      int snippetDuration = seekPosition - snippet.startTimestamp;
      newSnippets[_snippetIdGenerator.idGen()] = LyricSnippet(
        vocalistID: vocalistID,
        startTimestamp: snippet.startTimestamp,
        sentenceSegments: [SentenceSegment(beforeString, snippetDuration)],
        annotation: snippet.annotation,
      );
    }
    if (afterString.isNotEmpty) {
      int snippetDuration = snippet.endTimestamp - snippet.startTimestamp - seekPosition - snippetMargin;
      newSnippets[_snippetIdGenerator.idGen()] = LyricSnippet(
        vocalistID: vocalistID,
        startTimestamp: seekPosition + snippetMargin,
        sentenceSegments: [SentenceSegment(afterString, snippetDuration)],
        annotation: snippet.annotation,
      );
    }
    if (newSnippets.isNotEmpty) {
      lyricSnippetList.removeWhere((id, snippet) => id == snippetID);
      lyricSnippetList.addAll(newSnippets);
    }
    sortLyricSnippetList();

    notifyListeners();
  }

  void concatenateSnippets(List<SnippetID> snippetIDs) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetList);

    snippetsForeachVocalist.values.toList().forEach((vocalistSnippetsMap) {
      List<LyricSnippet> vocalistSnippets = vocalistSnippetsMap.values.toList();
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
        leftSnippet.sentenceSegments.last.duration += extendDuration;
        leftSnippet.sentenceSegments.addAll(rightSnippet.sentenceSegments);

        SnippetID rightSnippetID = snippetIDs[index];
        removeSnippetWithID(rightSnippetID);
      }
    });
    sortLyricSnippetList();

    notifyListeners();
  }

  void manipulateSnippet(SnippetID snippetID, SnippetEdge snippetEdge, bool holdLength) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetList);

    int seekPosition = musicPlayerProvider.seekPosition;
    LyricSnippet snippet = getSnippetWithID(snippetID);
    if (holdLength) {
      if (snippetEdge == SnippetEdge.start) {
        snippet.moveSnippet(snippet.startTimestamp - seekPosition);
      } else {
        snippet.moveSnippet(seekPosition - snippet.endTimestamp);
      }
    } else {
      if (snippetEdge == SnippetEdge.start) {
        if (seekPosition < snippet.startTimestamp) {
          snippet.extendSnippet(SnippetEdge.start, snippet.startTimestamp - seekPosition);
        } else if (snippet.startTimestamp < seekPosition) {
          snippet.shortenSnippet(SnippetEdge.start, seekPosition - snippet.startTimestamp);
        }
      } else {
        if (seekPosition < snippet.endTimestamp) {
          snippet.shortenSnippet(SnippetEdge.end, snippet.endTimestamp - seekPosition);
        } else if (snippet.endTimestamp < seekPosition) {
          snippet.extendSnippet(SnippetEdge.end, seekPosition - snippet.endTimestamp);
        }
      }
    }
    sortLyricSnippetList();

    notifyListeners();
  }

  void addTimingPoint(SnippetID snippetID, int characterPosition, int seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetList);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    snippet.addTimingPoint(characterPosition, seekPosition);

    notifyListeners();
  }

  void deleteTimingPoint(SnippetID snippetID, int characterPosition, {Option option = Option.former}) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetList);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    snippet.deleteTimingPoint(characterPosition, option);

    notifyListeners();
  }

  void editSentence(SnippetID snippetID, String newSentence) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetList);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    snippet.editSentence(newSentence);

    notifyListeners();
  }

  void undo() {
    LyricUndoAction? action = undoHistory.popUndoHistory();
    if (action != null) {
      LyricUndoType type = action.type;
      dynamic value = action.value;

      if (type == LyricUndoType.lyricSnippet) {
        lyricSnippetList = value;
      } else if (type == LyricUndoType.vocalistsColor) {
        vocalistColorMap = value;
      } else {
        sections = value;
      }
    }

    notifyListeners();
  }
}

enum Option {
  former,
  latter,
}

enum SnippetEdge {
  start,
  end,
}
