import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_controller.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_edit.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class EditColumn extends StatelessWidget {
  final SentenceMap sentenceMap;
  final SeekPosition seekPosition;
  final TextPaneCursorController textPaneCursorController;
  final CursorBlinker cursorBlinker;

  const EditColumn(this.sentenceMap, this.seekPosition, this.textPaneCursorController, this.cursorBlinker, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> elements = [];
    TextPaneListCursor textPaneListCursor = textPaneCursorController.textPaneListCursor;
    for (MapEntry<SentenceID, Sentence> sentenceEntry in sentenceMap.map.entries) {
      SentenceID sentenceID = sentenceEntry.key;
      Sentence sentence = sentenceEntry.value;
      TextPaneListCursor? listCursor;
      if (sentenceID == textPaneListCursor.sentenceID) {
        listCursor = textPaneListCursor;
      }

      Widget widget = SentenceEdit(
        sentence,
        seekPosition,
        listCursor,
        cursorBlinker,
      );
      elements.add(widget);
    }

    return Column(children: elements);
  }
}
