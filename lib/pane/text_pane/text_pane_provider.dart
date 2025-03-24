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
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_controller.dart';
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

  TextPaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    cursorBlinker = CursorBlinker(
      blinkIntervalInMillisec: 1000,
      onTick: () {
        notifyListeners();
      },
    );
    textPaneCursorMover = SentenceSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: timingService.getSnippetsAtSeekPosition(),
      lyricSnippetID: LyricSnippetID.empty,
      cursorBlinker: cursorBlinker,
      seekPosition: musicPlayerProvider.seekPosition,
    );

    musicPlayerProvider.addListener(() {
      LyricSnippetMap lyricSnippetMap = timingService.getSnippetsAtSeekPosition();
      SeekPosition seekPosition = musicPlayerProvider.seekPosition;
      textPaneCursorMover = textPaneCursorMover.updateCursor(lyricSnippetMap, cursorBlinker, seekPosition);
    });

    timingService.addListener(() {
      LyricSnippetMap lyricSnippetMap = timingService.getSnippetsAtSeekPosition();
      SeekPosition seekPosition = musicPlayerProvider.seekPosition;
      textPaneCursorMover = textPaneCursorMover.updateCursor(lyricSnippetMap, cursorBlinker, seekPosition);
    });
  }

  void moveUpCursor() {
    textPaneCursorMover.moveUpCursor();
  }

  void moveDownCursor() {
    textPaneCursorMover.moveDownCursor();
  }

  void moveLeftCursor() {
    textPaneCursorMover.moveLeftCursor();
  }

  void moveRightCursor() {
    textPaneCursorMover.moveRightCursor();
  }

  void enterSegmentSelectionMode() {
    //textPaneCursorMover.enterSegmentSelectionMode();
  }

  void exitSegmentSelectionMode() {
    //textPaneCursorMover.exitSegmentSelectionMode();
  }

  void switchToRangeSelection() {
    //textPaneCursorMover.switchToRangeSelection();
  }
}
