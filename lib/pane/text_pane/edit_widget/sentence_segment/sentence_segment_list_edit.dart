import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/sentence_segment_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/timing_point_edit.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SentenceSegmentListEdit extends StatelessWidget {
  final WordList sentenceSegmentList;
  final TextPaneCursor? textPaneCursor;
  final CursorBlinker? cursorBlinker;

  const SentenceSegmentListEdit({
    required this.sentenceSegmentList,
    this.textPaneCursor,
    this.cursorBlinker,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> editWidgets = [];
    List<Word> sentenceSegments = sentenceSegmentList.list;
    List<TextPaneCursor?> cursorList = List.filled(sentenceSegmentList.length, null);
    if (textPaneCursor != null) {
      cursorList = textPaneCursor!.getSegmentDividedCursors(sentenceSegmentList);
    }

    for (int index = 0; index < sentenceSegments.length; index++) {
      Word sentenceSegment = sentenceSegments[index];
      TextPaneCursor? segmentCursor = cursorList[index];

      bool isTimingPointPosition = false;
      if (segmentCursor is SentenceSelectionCursor && segmentCursor.insertionPosition.position == 0) {
        isTimingPointPosition = true;
      }

      if (index > 0) {
        editWidgets.add(TimingPointEdit(
          cursorBlinker: isTimingPointPosition ? cursorBlinker : null,
        ));
      }

      editWidgets.add(
        SentenceSegmentEdit(
          sentenceSegment: sentenceSegment,
          textPaneCursor: !isTimingPointPosition ? segmentCursor : null,
          cursorBlinker: cursorBlinker,
        ),
      );
    }

    return Row(children: editWidgets);
  }
}
