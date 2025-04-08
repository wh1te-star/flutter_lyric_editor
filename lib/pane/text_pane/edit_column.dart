import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/lyric_snippet_edit.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class EditColumn extends StatelessWidget {
  final LyricSnippetMap lyricSnippetMap;
  final SeekPosition seekPosition;
  final TextPaneCursorMover textPaneCursorMover;
  final CursorBlinker cursorBlinker;

  const EditColumn(this.lyricSnippetMap, this.seekPosition, this.textPaneCursorMover, this.cursorBlinker, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> elements = [];
    for (MapEntry<LyricSnippetID, LyricSnippet> lyricSnippetEntry in lyricSnippetMap.map.entries) {
      LyricSnippet lyricSnippet = lyricSnippetEntry.value;
      Widget widget = LyricSnippetEdit(
        lyricSnippet,
        seekPosition,
        textPaneCursorMover.textPaneCursor,
        cursorBlinker,
      );
      elements.add(widget);
    }

    return Column(children: elements);
  }
}
