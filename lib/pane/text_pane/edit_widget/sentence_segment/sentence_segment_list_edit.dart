import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/sentence_segment_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/timing_point_edit.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SentenceSegmentListEdit extends StatelessWidget {
  final SentenceSegmentList sentenceSegmentList;
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
    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;

    TextPaneCursor? adjustedCursor = textPaneCursor;
    for (int index = 0; index < sentenceSegments.length; index++) {
      SentenceSegment sentenceSegment = sentenceSegments[index];

      editWidgets.add(
        SentenceSegmentEdit(
          sentenceSegment: sentenceSegment,
          textPaneCursor: adjustedCursor,
          cursorBlinker: cursorBlinker,
        ),
      );

      if (index < sentenceSegments.length - 1) {
        editWidgets.add(TimingPointEdit());
      }

      adjustedCursor = adjustedCursor?.shiftLeftBySentenceSegment(sentenceSegment);

    }

    return Row(children: editWidgets);
  }
}
