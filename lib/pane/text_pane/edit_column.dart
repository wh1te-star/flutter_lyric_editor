import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_selection_edit.dart';
import 'package:lyric_editor/position/seek_position.dart';

class EditColumn extends StatelessWidget {
  final LyricSnippetMap lyricSnippetMap;
  final SeekPosition seekPosition;
  final TextPaneCursor textPaneCursor;

  const EditColumn(this.lyricSnippetMap, this.seekPosition, this.textPaneCursor, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> elements = [];
    for (LyricSnippet lyricSnippet in lyricSnippetMap.values) {
      Widget widget = Container();
      widget = SentenceSelectionEdit(lyricSnippet, seekPosition, textPaneCursor as SentenceSelectionCursor);
      elements.add(widget);
    }

    return Column(children: elements);
  }
}
