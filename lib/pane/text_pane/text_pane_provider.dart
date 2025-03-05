import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/annotation_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/position_type_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
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
  late TextPaneCursorMover textPaneCursorMover;
  late CursorBlinker cursorBlinker;

  bool isAnnotationSelection = false;
  bool isSegmentSelection = false;

  TextPaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    musicPlayerProvider.addListener(() {
      updateCursorBySeekPosition();
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
    updateCursorBySeekPosition();
  }

  void updateCursorBySeekPosition() {
    LyricSnippetMap lyricSnippetsAtSeekPosition = timingService.getSnippetsAtSeekPosition();
    if (lyricSnippetsAtSeekPosition.isEmpty) {
      textPaneCursorMover = SentenceSelectionCursorMover(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        textPaneCursor: SentenceSelectionCursor.empty,
        cursorBlinker: cursorBlinker,
        seekPosition: musicPlayerProvider.seekPosition,
      );
      return;
    }

    SeekPosition seekPosition = musicPlayerProvider.seekPosition;
    TextPaneCursor textPaneCursor = textPaneCursorMover.textPaneCursor;

    LyricSnippetID lyricSnippetID = lyricSnippetsAtSeekPosition.keys.first;
    LyricSnippet lyricSnippet = lyricSnippetsAtSeekPosition.values.first;
    if (lyricSnippetsAtSeekPosition.containsKey(lyricSnippetID)) {
      lyricSnippetID = textPaneCursor.lyricSnippetID;
      lyricSnippet = lyricSnippetsAtSeekPosition[lyricSnippetID]!;
    }

    int currentSnippetPosition = lyricSnippet.timing.getSegmentIndexFromSeekPosition(seekPosition);
    PositionTypeInfo nextSnippetPosition = lyricSnippet.timing.getPositionTypeInfo((textPaneCursor as SentenceSelectionCursor).charPosition.position);
    if (currentSnippetPosition != nextSnippetPosition.index) {
      textPaneCursorMover = SentenceSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        lyricSnippetID: lyricSnippetID,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
      cursorBlinker.restartCursorTimer();
    }
  }

  void updateCursorIfNeedByItemDeletion() {
    LyricSnippetMap lyricSnippetsAtSeekPosition = timingService.getSnippetsAtSeekPosition();
    if (lyricSnippetsAtSeekPosition.isEmpty) {
      return;
    }

    SeekPosition seekPosition = musicPlayerProvider.seekPosition;
    TextPaneCursor textPaneCursor = textPaneCursorMover.textPaneCursor;
    LyricSnippet? lyricSnippet = timingService.lyricSnippetMap[textPaneCursor.lyricSnippetID];
    if (lyricSnippet == null) {
      textPaneCursorMover = SentenceSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        lyricSnippetID: LyricSnippetID(1),
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
      return;
    }

    if (isAnnotationSelection) {
      return;
    }

    Annotation? annotation = lyricSnippet.annotationMap.map[(textPaneCursor as AnnotationSelectionCursor).segmentRange];
    if (annotation == null) {
      textPaneCursorMover = AnnotationSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetsAtSeekPosition,
        lyricSnippetID: textPaneCursor.lyricSnippetID,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
      return;
    }
  }

  void moveUpCursor() {}
  void moveDownCursor() {}
  void moveLeftCursor() {}
  void moveRightCursor() {}

  void enterSegmentSelectionMode() {}

  void exitSegmentSelectionMode() {}

  void switchToRangeSelection() {}
}
