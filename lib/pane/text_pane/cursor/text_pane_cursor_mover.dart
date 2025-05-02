import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

abstract class TextPaneCursorMover {
  final LyricSnippetMap lyricSnippetMap;
  final LyricSnippetID lyricSnippetID;
  final TextPaneCursor textPaneCursor;
  final SeekPosition seekPosition;
  final CursorBlinker cursorBlinker;

  TextPaneCursorMover({
    required this.lyricSnippetMap,
    required this.lyricSnippetID,
    required this.textPaneCursor,
    required this.seekPosition,
    required this.cursorBlinker,
  });

  TextPaneCursor defaultCursor(LyricSnippetID lyricSnippetID);
  TextPaneCursorMover moveUpCursor();
  TextPaneCursorMover moveDownCursor();
  TextPaneCursorMover moveLeftCursor();
  TextPaneCursorMover moveRightCursor();
  TextPaneCursorMover updateCursor(
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    CursorBlinker cursorBlinker,
    SeekPosition seekPosition,
  );
}
