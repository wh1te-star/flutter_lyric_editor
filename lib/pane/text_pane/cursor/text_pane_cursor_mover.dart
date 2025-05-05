import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TextPaneCursorMover {
  final LyricSnippetMap lyricSnippetMap;
  final LyricSnippetID lyricSnippetID;
  final TextPaneCursor textPaneCursor;
  final SeekPosition seekPosition;
  final CursorBlinker cursorBlinker;

  TextPaneCursorMover({
    required this.lyricSnippetMap,
    required this.lyricSnippetID,
    required this.seekPosition,
    required this.textPaneCursor,
    required this.cursorBlinker,
  });

  TextPaneCursorMover defaultCursor(LyricSnippetID lyricSnippetID) {}

  TextPaneCursorMover initByCursor(TextPaneCursor cursor) {
    return TextPaneCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      textPaneCursor: cursor,
      seekPosition: seekPosition,
      cursorBlinker: cursorBlinker,
    );
  }

  TextPaneCursorMover moveUpCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveUpCursor();
    return initByCursor(nextCursor);
  }

  TextPaneCursorMover moveDownCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveDownCursor();
    return initByCursor(nextCursor);
  }

  TextPaneCursorMover moveLeftCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveLeftCursor();
    return initByCursor(nextCursor);
  }

  TextPaneCursorMover moveRightCursor() {
    cursorBlinker.restartCursorTimer();

    TextPaneCursor nextCursor = textPaneCursor.moveRightCursor();
    return initByCursor(nextCursor);
  }

  TextPaneCursorMover updateCursor(
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    CursorBlinker cursorBlinker,
    SeekPosition seekPosition,
  ) {
    TextPaneCursor nextCursor = textPaneCursor.updateCursor(lyricSnippetMap, cursorBlinker, seekPosition);
    return initByCursor(nextCursor);
  }
}
