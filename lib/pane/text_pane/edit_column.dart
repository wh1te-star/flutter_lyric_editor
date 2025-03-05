import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/lyric_snippet_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_selection_edit.dart';
import 'package:lyric_editor/position/seek_position.dart';

class EditColumn extends StatelessWidget {
  final LyricSnippetMap lyricSnippetMap;
  final SeekPosition seekPosition;
  final TextPaneCursorMover textPaneCursorMover;

  const EditColumn(this.lyricSnippetMap, this.seekPosition, this.textPaneCursorMover, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> elements = [];
    for (MapEntry<LyricSnippetID, LyricSnippet> lyricSnippetEntry in lyricSnippetMap.map.entries) {
      LyricSnippetID lyricSnippetID = lyricSnippetEntry.key;
      LyricSnippet lyricSnippet = lyricSnippetEntry.value;
      Widget widget = Container();
      if (textPaneCursorMover.textPaneCursor is SentenceSelectionCursor) {
        widget = SentenceSelectionEdit(lyricSnippet, seekPosition, textPaneCursorMover.textPaneCursor as SentenceSelectionCursor);
      }
      elements.add(widget);
    }

    return Column(children: elements);
  }
}
