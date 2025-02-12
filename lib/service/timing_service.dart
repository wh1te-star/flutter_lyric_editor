import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist_color_map.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/utility/undo_history.dart';

final timingMasterProvider = ChangeNotifierProvider((ref) {
  final musicPlayerService = ref.read(musicPlayerMasterProvider);
  return TimingService(musicPlayerProvider: musicPlayerService);
});

class TimingService extends ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;

  LyricSnippetMap lyricSnippetMap = LyricSnippetMap({});
  Map<LyricSnippetID, int> snippetTracks = {};
  VocalistColorMap vocalistColorMap = VocalistColorMap({});
  List<int> sections = [];

  LyricUndoHistory undoHistory = LyricUndoHistory();

  String defaultVocalistName = "Vocalist Name";
  String vocalistNameSeparator = ", ";

  TimingService({
    required this.musicPlayerProvider,
  });

  Map<VocalistID, LyricSnippetMap> get snippetsForeachVocalist {
    return groupBy(
      lyricSnippetMap.entries,
      (MapEntry<LyricSnippetID, LyricSnippet> entry) {
        return entry.value.vocalistID;
      },
    ).map(
      (VocalistID vocalistID, List<MapEntry<LyricSnippetID, LyricSnippet>> snippets) => MapEntry(
        vocalistID,
        LyricSnippetMap(
          {for (var entry in snippets) entry.key: entry.value},
        ),
      ),
    );
  }

  Map<LyricSnippetID, int> getTrackNumber(Map<LyricSnippetID, LyricSnippet> lyricSnippetList, int startBulge, int endBulge) {
    if (lyricSnippetList.isEmpty) return {};

    Map<LyricSnippetID, int> snippetTracks = {};

    int maxOverlap = 0;
    int currentOverlap = 1;
    int currentEndTime = lyricSnippetList.values.first.endTimestamp + endBulge;
    snippetTracks[lyricSnippetList.keys.first] = 0;

    for (int i = 1; i < lyricSnippetList.length; i++) {
      LyricSnippetID currentSnippetID = lyricSnippetList.keys.toList()[i];
      LyricSnippet currentSnippet = lyricSnippetList.values.toList()[i];
      int start = currentSnippet.startTimestamp - startBulge;
      int end = currentSnippet.endTimestamp + endBulge;
      if (start <= currentEndTime) {
        currentOverlap++;
      } else {
        currentOverlap = 1;
        currentEndTime = end;
      }
      if (currentOverlap > maxOverlap) {
        maxOverlap = currentOverlap;
      }

      snippetTracks[currentSnippetID] = currentOverlap - 1;
    }

    return snippetTracks;
  }

  LyricSnippetMap getSnippetsAtSeekPosition({int? seekPosition, VocalistID? vocalistID, int startBulge = 0, int endBulge = 0}) {
    return lyricSnippetMap.getSnippetsAtSeekPosition(
      seekPosition: seekPosition ?? musicPlayerProvider.seekPosition,
      vocalistID: vocalistID,
      startBulge: startBulge,
      endBulge: endBulge,
    );
  }

  int getLanes({VocalistID? vocalistID}) {
    List<LyricSnippet> snippets = vocalistID != null ? snippetsForeachVocalist[vocalistID]?.map.values.toList() ?? [] : lyricSnippetMap.values.toList();
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
    lyricSnippetMap.clear();
    lyricSnippetMap[_snippetIdGenerator.idGen()] = LyricSnippet(
      vocalistID: vocalistColorMap.keys.first,
      startTimestamp: 0,
      sentenceSegments: [SentenceSegment(singlelineText, audioDuration)],
      annotationMap: {},
    );
    sortLyricSnippetList();

    notifyListeners();
  }

  void loadLyric(String rawLyricText) {
    lyricSnippetMap = parseLyric(rawLyricText);
    sortLyricSnippetList();

    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    notifyListeners();
  }

  void exportLyric(String path) async {
    final String rawLyricText = serializeLyric(lyricSnippetMap);
    final File file = File(path);
    await file.writeAsString(rawLyricText);
  }

  List<LyricSnippet> translateIDsToSnippets(List<LyricSnippetID> ids) {
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

  LyricSnippet getSnippetWithID(LyricSnippetID id) {
    return lyricSnippetMap[id]!;
  }

  void removeSnippetWithID(LyricSnippetID id) {
    lyricSnippetMap.remove(id);
  }

  List<LyricSnippet> getSnippetsWithVocalistName(String vocalistName) {
    return lyricSnippetMap.values.where((snippet) => vocalistColorMap[snippet.vocalistID]!.name == vocalistName).toList();
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
    lyricSnippetMap.removeWhere((id, snippet) => vocalistColorMap[snippet.vocalistID]!.name == vocalistName);

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

      lyricSnippetMap = parseLyric(rawLyricText);
      sortLyricSnippetList();
      notifyListeners();
      //writeTranslatedXmlToFile();
    } catch (e) {
      debugPrint("Error loading lyrics: $e");
    }
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

  void addSnippet(String sentence, int startSeekPosition, VocalistID vocalistID) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

    const int defaultSnippetDuration = 3000;
    lyricSnippetMap[_snippetIdGenerator.idGen()] = LyricSnippet(
      startTimestamp: startSeekPosition,
      vocalistID: vocalistID,
      sentenceSegments: [
        SentenceSegment(
          sentence,
          defaultSnippetDuration,
        ),
      ],
      annotationMap: {},
    );
    sortLyricSnippetList();

    notifyListeners();
  }

  void deleteSnippet(LyricSnippetID snippetID) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

    lyricSnippetMap.remove(snippetID);

    notifyListeners();
  }

  void divideSnippet(LyricSnippetID snippetID, int charPosition, int seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    int snippetMargin = 100;
    String beforeString = snippet.sentence.substring(0, charPosition);
    String afterString = snippet.sentence.substring(charPosition);
    VocalistID vocalistID = snippet.vocalistID;
    Map<LyricSnippetID, LyricSnippet> newSnippets = {};
    if (beforeString.isNotEmpty) {
      int snippetDuration = seekPosition - snippet.startTimestamp;
      newSnippets[_snippetIdGenerator.idGen()] = LyricSnippet(
        vocalistID: vocalistID,
        startTimestamp: snippet.startTimestamp,
        sentenceSegments: [SentenceSegment(beforeString, snippetDuration)],
        annotationMap: snippet.annotationMap,
      );
    }
    if (afterString.isNotEmpty) {
      int snippetDuration = snippet.endTimestamp - snippet.startTimestamp - seekPosition - snippetMargin;
      newSnippets[_snippetIdGenerator.idGen()] = LyricSnippet(
        vocalistID: vocalistID,
        startTimestamp: seekPosition + snippetMargin,
        sentenceSegments: [SentenceSegment(afterString, snippetDuration)],
        annotationMap: snippet.annotationMap,
      );
    }
    if (newSnippets.isNotEmpty) {
      lyricSnippetMap.removeWhere((id, snippet) => id == snippetID);
      lyricSnippetMap.addAll(newSnippets);
    }
    sortLyricSnippetList();

    notifyListeners();
  }

  void concatenateSnippets(List<LyricSnippetID> snippetIDs) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

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

        LyricSnippetID rightSnippetID = snippetIDs[index];
        removeSnippetWithID(rightSnippetID);
      }
    });
    sortLyricSnippetList();

    notifyListeners();
  }

  void manipulateSnippet(LyricSnippetID snippetID, SnippetEdge snippetEdge, bool holdLength) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

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

  void addTimingPoint({
    required LyricSnippetID snippetID,
    SegmentRange? annotationRange,
    required int charPosition,
    required int seekPosition,
  }) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

    LyricSnippet snippet = getSnippetWithID(snippetID);

    if (annotationRange == null) {
      snippet.addTimingPoint(charPosition, seekPosition);
    } else {
      snippet.annotationMap[annotationRange]!.addTimingPoint(charPosition, seekPosition);
    }

    notifyListeners();
  }

  void deleteTimingPoint({
    required LyricSnippetID snippetID,
    SegmentRange? annotationRange,
    required int charPosition,
    Option option = Option.former,
  }) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    if (annotationRange == null) {
      snippet.deleteTimingPoint(charPosition, option);
    } else {
      snippet.annotationMap[annotationRange]!.deleteTimingPoint(charPosition, option);
    }

    notifyListeners();
  }

  void addAnnotation(LyricSnippetID snippetID, String annotationString, int startIndex, int endIndex) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    snippet.addAnnotation(annotationString, startIndex, endIndex);

    notifyListeners();
  }

  void deleteAnnotation(LyricSnippetID snippetID, SegmentRange range) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

    LyricSnippet snippet = getSnippetWithID(snippetID);
    snippet.deleteAnnotation(range);

    notifyListeners();
  }

  void editSentence(LyricSnippetID snippetID, String newSentence) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

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
        lyricSnippetMap = value;
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
