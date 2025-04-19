import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/segment_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/seek_position.dart';
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

      textPaneCursorMover.cursorBlinker.restartCursorTimer();
      notifyListeners();
    });

    timingService.addListener(() {
      LyricSnippetMap lyricSnippetMap = timingService.getSnippetsAtSeekPosition();
      SeekPosition seekPosition = musicPlayerProvider.seekPosition;
      textPaneCursorMover = textPaneCursorMover.updateCursor(lyricSnippetMap, cursorBlinker, seekPosition);

      textPaneCursorMover.cursorBlinker.restartCursorTimer();
      notifyListeners();
    });
  }

  void moveUpCursor() {
    textPaneCursorMover = textPaneCursorMover.moveUpCursor();
    debugPrint("${textPaneCursorMover.textPaneCursor}");

    textPaneCursorMover.cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveDownCursor() {
    textPaneCursorMover = textPaneCursorMover.moveDownCursor();
    debugPrint("${textPaneCursorMover.textPaneCursor}");

    textPaneCursorMover.cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveLeftCursor() {
    textPaneCursorMover = textPaneCursorMover.moveLeftCursor();
    debugPrint("${textPaneCursorMover.textPaneCursor}");

    textPaneCursorMover.cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveRightCursor() {
    textPaneCursorMover = textPaneCursorMover.moveRightCursor();
    debugPrint("${textPaneCursorMover.textPaneCursor}");

    textPaneCursorMover.cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void enterSegmentSelectionMode() {
    assert(textPaneCursorMover is SentenceSelectionCursorMover, "This is an unexpected call. The cursor type must be SentenceSelectionCursorMover, but is ${textPaneCursorMover.runtimeType}");
    SentenceSelectionCursorMover cursorMover = textPaneCursorMover as SentenceSelectionCursorMover;
    textPaneCursorMover = cursorMover.enterSegmentSelectionMode();
  }

  void exitSegmentSelectionMode() {
    assert(textPaneCursorMover is SegmentSelectionCursorMover, "This is an unexpected call. The cursor type must be SegmentSelectionCursorMover, but is ${textPaneCursorMover.runtimeType}");
    SegmentSelectionCursorMover cursorMover = textPaneCursorMover as SegmentSelectionCursorMover;
    textPaneCursorMover = cursorMover.exitSegmentSelectionMode();
  }

  void switchToRangeSelection() {
    assert(textPaneCursorMover is SegmentSelectionCursorMover, "This is an unexpected call. The cursor type must be SegmentSelectionCursorMover, but is ${textPaneCursorMover.runtimeType}");
    SegmentSelectionCursorMover cursorMover = textPaneCursorMover as SegmentSelectionCursorMover;
    textPaneCursorMover = cursorMover.switchToRangeSelection();
  }
}
