import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/pane/text_pane/cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/position_type_info.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

final textPaneMasterProvider = ChangeNotifierProvider((ref) {
  final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
  final TimingService timingService = ref.read(timingMasterProvider);
  return TextPaneProvider(musicPlayerProvider: musicPlayerService, timingService: timingService);
});

class TextPaneProvider with ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;
  final TimingService timingService;
  late TextPaneCursor textPaneCursor;
  late CursorBlinker cursorBlinker;

  bool isAnnotationSelection = false;
  bool isSegmentSelection = false;

  TextPaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    musicPlayerProvider.addListener(() {
      updateCursorIfNeedBySeekPosition();
    });

    timingService.addListener(() {
      updateCursorIfNeedByItemDeletion();
    });

    cursorBlinker = CursorBlinker(
      blinkIntervalInMillisec: 1000,
      onTick: () {
        notifyListeners();
      },
    );
    textPaneCursor = SentenceSelectionCursor(LyricSnippetID.empty, cursorBlinker, InsertionPosition(1), Option.former);
  }

  void updateCursorIfNeedBySeekPosition() {
    Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;
    if (currentSnippets.isEmpty) {
      return;
    }

    if (!currentSnippets.keys.toList().contains(textPaneCursor.lyricSnippetID)) {
      textPaneCursor.lyricSnippetID = currentSnippets.keys.first;
    }

    LyricSnippet snippet = currentSnippets.values.first;
    int currentSnippetPosition = snippet.timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    PositionTypeInfo nextSnippetPosition = snippet.timing.getPositionTypeInfo((textPaneCursor as SentenceSelectionCursor).charPosition.position);
    if (currentSnippetPosition != nextSnippetPosition.index) {
      textPaneCursor = getDefaultSentenceSelectionCursor(textPaneCursor.lyricSnippetID);
      cursorBlinker.restartCursorTimer();
    }
  }

  void updateCursorIfNeedByItemDeletion() {
    Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;
    if (currentSnippets.isEmpty) {
      return;
    }

    LyricSnippet? snippet = timingService.lyricSnippetMap[textPaneCursor.lyricSnippetID];
    if (snippet == null) {
      textPaneCursor = getDefaultSentenceSelectionCursor(LyricSnippetID(1));
      return;
    }

    if (isAnnotationSelection) {
      return;
    }

    Annotation? annotation = snippet.annotationMap.map[(textPaneCursor as AnnotationSelectionCursor).segmentRange];
    if (annotation == null) {
      textPaneCursor = getDefaultAnnotationSelectionCursor(textPaneCursor.lyricSnippetID);
      return;
    }
  }

  SentenceSelectionCursor getDefaultSentenceSelectionCursor(LyricSnippetID id) {
    SentenceSelectionCursor defaultCursor = SentenceSelectionCursor.empty;

    LyricSnippet snippet = timingService.getLyricSnippetByID(id);
    int currentSnippetPosition = snippet.timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    defaultCursor.lyricSnippetID = id;
    defaultCursor.charPosition = snippet.timingPoints[currentSnippetPosition].charPosition + 1;
    defaultCursor.option = Option.former;

    return defaultCursor;
  }

  AnnotationSelectionCursor getDefaultAnnotationSelectionCursor(LyricSnippetID id) {
    AnnotationSelectionCursor defaultCursor = AnnotationSelectionCursor.empty;

    LyricSnippet snippet = timingService.getLyricSnippetByID(id);
    int? annotationIndex = snippet.getAnnotationIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    MapEntry<SegmentRange, Annotation>? cursorAnnotationEntry = snippet.getAnnotationWords(annotationIndex!);
    SegmentRange range = cursorAnnotationEntry.key;
    Annotation annotation = cursorAnnotationEntry.value;

    int index = annotation.timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);

    defaultCursor.lyricSnippetID = id;
    defaultCursor.segmentRange = range;
    defaultCursor.charPosition = annotation.timingPoints[index].charPosition + 1;
    defaultCursor.option = Option.former;

    return defaultCursor;
  }

  int countOccurrences(List<int> list, int number) {
    return list.where((element) => element == number).length;
  }

}
