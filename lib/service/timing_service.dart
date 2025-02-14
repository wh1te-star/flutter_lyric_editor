import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/section/section_list.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist_color_map.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/utility/undo_history.dart';
import 'package:tuple/tuple.dart';

final timingMasterProvider = ChangeNotifierProvider((ref) {
  final musicPlayerService = ref.read(musicPlayerMasterProvider);
  return TimingService(musicPlayerProvider: musicPlayerService);
});

class TimingService extends ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;

  LyricSnippetMap lyricSnippetMap = LyricSnippetMap({});
  Map<LyricSnippetID, int> snippetTracks = {};
  VocalistColorMap vocalistColorMap = VocalistColorMap({});
  SectionList sectionList = SectionList([]);

  LyricUndoHistory undoHistory = LyricUndoHistory();

  TimingService({
    required this.musicPlayerProvider,
  });

  /* * * * * * * * * * * * * * * * * *
   SectionList functions
  * * * * * * * * * * * * * * * * * */
  void addSection(int seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.section, sectionList);
    sectionList.addSection(seekPosition);
    notifyListeners();
  }

  void removeSection(int seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.section, sectionList);
    sectionList.removeSection(seekPosition);
    notifyListeners();
  }

  /* * * * * * * * * * * * * * * * * *
   VocalistColorMap functions
  * * * * * * * * * * * * * * * * * */
  void addVocalist(Vocalist vocalist) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.addVocalist(vocalist);
    notifyListeners();
  }

  void deleteVocalistByID(VocalistID vocalistID) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.removeVocalistByID(vocalistID);
    notifyListeners();
  }

  void deleteVocalistByName(String vocalistName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.removeVocalistByName(vocalistName);
    notifyListeners();
  }

  void changeVocalistName(String oldName, String newName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.changeVocalistName(oldName, newName);
    notifyListeners();
  }

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

  /* * * * * * * * * * * * * * * * * *
   LyricSnippetMap functions
  * * * * * * * * * * * * * * * * * */
  void addLyricSnippet(LyricSnippet lyricSnippet) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap.addLyricSnippet(lyricSnippet);
    notifyListeners();
  }

  void removeLyricSnippet(LyricSnippetID snippetID) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap.removeLyricSnippetByID(snippetID);
    notifyListeners();
  }

  void editSentence(LyricSnippetID snippetID, String newSentence) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.editSentence(snippetID, newSentence);
    notifyListeners();
  }

  void addAnnotation(LyricSnippetID snippetID, SegmentRange segmentRange, String annotationString) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.addAnnotation(snippetID, segmentRange, annotationString);
    notifyListeners();
  }

  void removeAnnotation(LyricSnippetID snippetID, SegmentRange segmentRange) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.removeAnnotation(snippetID, segmentRange);
    notifyListeners();
  }

  void addTimingPoint(LyricSnippetID snippetID, int charPosition, int seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.addTimingPoint(snippetID, charPosition, seekPosition);
    notifyListeners();
  }

  void removeTimingPoint(LyricSnippetID snippetID, int charPosition, Option option) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.removeTimingPoint(snippetID, charPosition, option);
    notifyListeners();
  }

  void addAnnotationTimingPoint(LyricSnippetID snippetID, SegmentRange segmentRange, int charPosition, int seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.addAnnotationTimingPoint(snippetID, segmentRange, charPosition, seekPosition);
    notifyListeners();
  }

  void removeAnnotationTimingPoint(LyricSnippetID snippetID, SegmentRange segmentRange, int charPosition, Option option) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.removeAnnotationTimingPoint(snippetID, segmentRange, charPosition, option);
    notifyListeners();
  }

  void manipulateSnippet(LyricSnippetID snippetID, SnippetEdge snippetEdge, bool holdLength) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.manipulateSnippet(snippetID, musicPlayerProvider.seekPosition, snippetEdge, holdLength);
    notifyListeners();
  }

  void divideSnippet(LyricSnippetID snippetID, int charPosition, int seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.divideSnippet(snippetID, charPosition, seekPosition);
    notifyListeners();
  }

  void concatenateSnippets(Tuple2<LyricSnippetID, LyricSnippetID> snippetIDs) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.concatenateSnippets(snippetIDs);
    notifyListeners();
  }

  /* * * * * * * * * * * * * * * * * *
   Change Notifier's Original functions
  * * * * * * * * * * * * * * * * * */
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
        sectionList = value;
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
