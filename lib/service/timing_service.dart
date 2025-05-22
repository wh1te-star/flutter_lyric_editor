import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/sentence/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/section/section_list.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist_color_map.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/service/xlrc_parser.dart';
import 'package:lyric_editor/utility/undo_history.dart';
import 'package:tuple/tuple.dart';

final timingMasterProvider = ChangeNotifierProvider((ref) {
  final musicPlayerService = ref.read(musicPlayerMasterProvider);
  return TimingService(musicPlayerProvider: musicPlayerService);
});

class TimingService extends ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;

  SentenceMap lyricSnippetMap = SentenceMap({});
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
  void addSection(SeekPosition seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.section, sectionList);
    sectionList.addSection(seekPosition);
    notifyListeners();
  }

  void removeSection(SeekPosition seekPosition) {
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

  void removeVocalistByID(VocalistID vocalistID) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.removeVocalistByID(vocalistID);
    notifyListeners();
  }

  void removeVocalistByName(String vocalistName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.removeVocalistByName(vocalistName);
    notifyListeners();
  }

  void changeVocalistName(String oldName, String newName) {
    undoHistory.pushUndoHistory(LyricUndoType.vocalistsColor, vocalistColorMap);
    vocalistColorMap = vocalistColorMap.changeVocalistName(oldName, newName);
    notifyListeners();
  }

  /* * * * * * * * * * * * * * * * * *
   LyricSnippetMap functions
  * * * * * * * * * * * * * * * * * */
  Sentence getLyricSnippetByID(LyricSnippetID id) {
    return lyricSnippetMap.getLyricSnippetByID(id);
  }

  SentenceMap getLyricSnippetByVocalistID(VocalistID vocalistID) {
    return lyricSnippetMap.getLyricSnippetByVocalistID(vocalistID);
  }

  SentenceMap getSnippetsAtSeekPosition({
    SeekPosition? seekPosition,
    VocalistID? vocalistID,
    Duration startBulge = Duration.zero,
    Duration endBulge = Duration.zero,
  }) {
    seekPosition ??= musicPlayerProvider.seekPosition;
    return lyricSnippetMap.getSnippetsAtSeekPosition(
      seekPosition: seekPosition,
      vocalistID: vocalistID,
      startBulge: startBulge,
      endBulge: endBulge,
    );
  }

  void addLyricSnippet(Sentence lyricSnippet) {
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

  void addAnnotation(LyricSnippetID snippetID, Phrase segmentRange, String annotationString) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.addAnnotation(snippetID, segmentRange, annotationString);
    notifyListeners();
  }

  void removeAnnotation(LyricSnippetID snippetID, Phrase segmentRange) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.removeAnnotation(snippetID, segmentRange);
    notifyListeners();
  }

  void addTimingPoint(LyricSnippetID snippetID, InsertionPosition charPosition, SeekPosition seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.addTimingPoint(snippetID, charPosition, seekPosition);
    notifyListeners();
  }

  void removeTimingPoint(LyricSnippetID snippetID, InsertionPosition charPosition, Option option) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.removeTimingPoint(snippetID, charPosition, option);
    notifyListeners();
  }

  void addAnnotationTimingPoint(LyricSnippetID snippetID, Phrase segmentRange, InsertionPosition charPosition, SeekPosition seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.addAnnotationTimingPoint(snippetID, segmentRange, charPosition, seekPosition);
    notifyListeners();
  }

  void removeAnnotationTimingPoint(LyricSnippetID snippetID, Phrase segmentRange, InsertionPosition charPosition, Option option) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.removeAnnotationTimingPoint(snippetID, segmentRange, charPosition, option);
    notifyListeners();
  }

  void manipulateSnippet(LyricSnippetID snippetID, SnippetEdge snippetEdge, bool holdLength) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.manipulateSentence(snippetID, musicPlayerProvider.seekPosition, snippetEdge, holdLength);
    notifyListeners();
  }

  void divideSnippet(LyricSnippetID snippetID, InsertionPosition charPosition, SeekPosition seekPosition) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.divideSentence(snippetID, charPosition, seekPosition);
    notifyListeners();
  }

  void concatenateSnippets(LyricSnippetID firstLyricSnippetID, LyricSnippetID secondLyricSnippetID) {
    undoHistory.pushUndoHistory(LyricUndoType.lyricSnippet, lyricSnippetMap);
    lyricSnippetMap = lyricSnippetMap.concatenateSnippets(firstLyricSnippetID, secondLyricSnippetID);
    notifyListeners();
  }

  /* * * * * * * * * * * * * * * * * *
   Change Notifier's Original functions
  * * * * * * * * * * * * * * * * * */
  void importLyric(String importPath) async {
    File file = File(importPath);
    String rawText = await file.readAsString();

    XlrcParser parser = XlrcParser();
    Tuple3<SentenceMap, VocalistColorMap, SectionList> data = parser.deserialize(rawText);
    lyricSnippetMap = data.item1;
    vocalistColorMap = data.item2;
    sectionList = data.item3;

    notifyListeners();
  }

  void exportLyric(String exportPath) {
    XlrcParser parser = XlrcParser();
    Tuple3<SentenceMap, VocalistColorMap, SectionList> data = Tuple3<SentenceMap, VocalistColorMap, SectionList>(
      lyricSnippetMap,
      vocalistColorMap,
      sectionList,
    );
    String rawText = parser.serialize(data);

    File file = File(exportPath);
    file.writeAsStringSync(rawText);
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
        sectionList = value;
      }
    }

    notifyListeners();
  }
}

enum Option {
  segment,
  former,
  latter,
}

enum SnippetEdge {
  start,
  end,
}
