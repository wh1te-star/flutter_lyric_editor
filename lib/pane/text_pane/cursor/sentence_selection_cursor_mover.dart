import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/text_pane.dart';

class SentenceSelectionCursorMover extends TextPaneCursorMover {
  SentenceSelectionCursorMover({
    required super.lyricSnippetMap,
    required super.textPaneCursor,
    required super.cursorBlinker,
  });

  @override
  TextPaneCursor defaultCursor() {
    return TextPaneCursor(textPaneCursor.lyricSnippetID, cursorBlinker);
  }

  @override
  TextPaneCursorMover moveUpCursor();
  @override
  TextPaneCursorMover moveDownCursor();
  @override
  TextPaneCursorMover moveLeftCursor();
  @override
  TextPaneCursorMover moveRightCursor();
}
