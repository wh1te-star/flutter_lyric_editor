import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_controller.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/base_list_cursor.dart';
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
  late TextPaneCursorController textPaneCursorController;
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
    textPaneCursorController = TextPaneCursorController(
      lyricSnippetMap: LyricSnippetMap.empty,
      lyricSnippetID: LyricSnippetID.empty,
      textPaneListCursor: SentenceSelectionListCursor.empty,
      seekPosition: musicPlayerProvider.seekPosition,
      cursorBlinker: cursorBlinker,
    );

    musicPlayerProvider.addListener(() {
      LyricSnippetMap lyricSnippetMap = timingService.getSnippetsAtSeekPosition();
      SeekPosition seekPosition = musicPlayerProvider.seekPosition;
      textPaneCursorController = textPaneCursorController.updateCursor(lyricSnippetMap, seekPosition);

      notifyListeners();
    });

    timingService.addListener(() {
      LyricSnippetMap lyricSnippetMap = timingService.getSnippetsAtSeekPosition();
      SeekPosition seekPosition = musicPlayerProvider.seekPosition;
      textPaneCursorController = textPaneCursorController.updateCursor(lyricSnippetMap, seekPosition);

      notifyListeners();
    });
  }

  void moveUpCursor() {
    textPaneCursorController = textPaneCursorController.moveUpCursor();
    debugPrint("${textPaneCursorController.textPaneListCursor}");

    notifyListeners();
  }

  void moveDownCursor() {
    textPaneCursorController = textPaneCursorController.moveDownCursor();
    debugPrint("${textPaneCursorController.textPaneListCursor}");

    notifyListeners();
  }

  void moveLeftCursor() {
    textPaneCursorController = textPaneCursorController.moveLeftCursor();
    debugPrint("${textPaneCursorController.textPaneListCursor}");

    notifyListeners();
  }

  void moveRightCursor() {
    textPaneCursorController = textPaneCursorController.moveRightCursor();
    debugPrint("${textPaneCursorController.textPaneListCursor}");

    notifyListeners();
  }

  void enterSegmentSelectionMode() {
    textPaneCursorController = textPaneCursorController.enterSegmentSelectionMode();
  }

  void exitSegmentSelectionMode() {
    textPaneCursorController = textPaneCursorController.exitSegmentSelectionMode();
  }

  void switchToRangeSelection() {
    textPaneCursorController = textPaneCursorController.switchToRangeSelection();
  }
}
