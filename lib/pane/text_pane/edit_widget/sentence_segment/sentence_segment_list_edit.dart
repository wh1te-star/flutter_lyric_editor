import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
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
    List<Widget> sentenceEdits = [];
    List<Widget> annotationEdits = [];
    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;
    for (int index = 0; index < sentenceSegments.length; index++) {
      SentenceSegment sentenceSegment = sentenceSegments[index];
      sentenceEdits.add(
        SentenceSegmentEdit(
          sentenceSegment: sentenceSegment,
          textPaneCursor: TextPaneCursor.empty,
          cursorBlinker: CursorBlinker.empty,
        ),
      );

      if (index < sentenceSegments.length - 1) {
        sentenceEdits.add(TimingPointEdit());
      }
    }

    return Column(
      children: [
        Row(children: annotationEdits),
        Row(children: sentenceEdits),
      ],
    );
  }
}
