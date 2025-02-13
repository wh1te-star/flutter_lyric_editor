import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/section/section_list.dart';
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
  SectionList sections = SectionList([]);

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

  List<LyricSnippet> translateIDsToSnippets(List<LyricSnippetID> ids) {
    return ids.map((id) => getSnippetWithID(id)).toList();
  }

  void addVocalist(String vocalistName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);

    vocalistColorMap[_vocalistIdGenerator.idGen()] = Vocalist(name: vocalistName, color: 0xFF222222);

    notifyListeners();
  }

  void deleteVocalist(String vocalistName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);

    VocalistID id = getVocalistIDByName(vocalistName);
    vocalistColorMap.remove(id);
    lyricSnippetMap.removeWhere((id, snippet) => vocalistColorMap[snippet.vocalistID]!.name == vocalistName);

    notifyListeners();
  }

  void changeVocalistName(String oldName, String newName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);

    VocalistID vocalistID = getVocalistIDByName(oldName);
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

    lyricSnippetMap = lyricSnippetMap.divideSnippet(snippetID, charPosition, seekPosition);

    notifyListeners();
  }

  void concatenateSnippets(List<LyricSnippetID> snippetIDs) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

    lyricSnippetMap = lyricSnippetMap.concatenateSnippets(snippetIDs);

    notifyListeners();
  }

  void manipulateSnippet(LyricSnippetID snippetID, SnippetEdge snippetEdge, bool holdLength) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);

    lyricSnippetMap = lyricSnippetMap.manipulateSnippet(snippetID, snippetEdge, holdLength);

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
