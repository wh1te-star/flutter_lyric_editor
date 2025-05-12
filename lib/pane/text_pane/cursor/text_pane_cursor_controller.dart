import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TextPaneCursorController {
  final LyricSnippetMap lyricSnippetMap;
  final LyricSnippetID lyricSnippetID;
  final TextPaneCursor textPaneCursor;
  final SeekPosition seekPosition;
  final CursorBlinker cursorBlinker;

  TextPaneCursorController({
    required this.lyricSnippetMap,
    required this.lyricSnippetID,
    required this.seekPosition,
    required this.textPaneCursor,
    required this.cursorBlinker,
  });

  TextPaneCursorController initByCursor(TextPaneCursor cursor) {
    return TextPaneCursorController(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      textPaneCursor: cursor,
      seekPosition: seekPosition,
      cursorBlinker: cursorBlinker,
    );
  }

  TextPaneCursorController moveUpCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveUpCursor();
    return initByCursor(nextCursor);
  }

  TextPaneCursorController moveDownCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveDownCursor();
    return initByCursor(nextCursor);
  }

  TextPaneCursorController moveLeftCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveLeftCursor();
    return initByCursor(nextCursor);
  }

  TextPaneCursorController moveRightCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveRightCursor();
    return initByCursor(nextCursor);
  }

  TextPaneCursorController updateCursor(
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  ) {
    TextPaneCursor nextCursor = textPaneCursor.updateCursor(lyricSnippetMap,lyricSnippetID, seekPosition);
    return initByCursor(nextCursor);
  }
}
