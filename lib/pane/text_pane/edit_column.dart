import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_controller.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/lyric_snippet_edit.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class EditColumn extends StatelessWidget {
  final LyricSnippetMap lyricSnippetMap;
  final SeekPosition seekPosition;
  final TextPaneCursorController textPaneCursorController;
  final CursorBlinker cursorBlinker;

  const EditColumn(this.lyricSnippetMap, this.seekPosition, this.textPaneCursorController, this.cursorBlinker, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> elements = [];
    TextPaneListCursor textPaneListCursor = textPaneCursorController.textPaneListCursor;
    for (MapEntry<LyricSnippetID, LyricSnippet> lyricSnippetEntry in lyricSnippetMap.map.entries) {
      LyricSnippetID lyricSnippetID = lyricSnippetEntry.key;
      LyricSnippet lyricSnippet = lyricSnippetEntry.value;
      TextPaneCursor? textPaneCursor = null;
      if (lyricSnippetID == textPaneListCursor.lyricSnippetID) {
        textPaneCursor = textPaneListCursor.textPaneCursor;
      }

      Widget widget = LyricSnippetEdit(
        lyricSnippet,
        seekPosition,
        textPaneCursor,
        cursorBlinker,
      );
      elements.add(widget);
    }

    return Column(children: elements);
  }
}
