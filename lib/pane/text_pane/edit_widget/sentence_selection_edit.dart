import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/lyric_snippet_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/sentence_segment_list_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/timing_point_edit.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:tuple/tuple.dart';

class SentenceSelectionEdit extends LyricSnippetEdit<SentenceSelectionCursor> {
  const SentenceSelectionEdit(super.lyricSnippet, super.seekPosition, super.textPaneCursor, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> sentenceRowWidgets = [];
    List<Widget> annotationRowWidgets = [];
    List<Tuple2<SegmentRange, Annotation?>> rangeList = lyricSnippet.getAnnotationExistenceRangeList(lyricSnippet.annotationMap.map, lyricSnippet.sentenceSegments.length);

    for (int index = 0; index < rangeList.length; index++) {
      SegmentRange segmentRange = rangeList[index].item1;
      Annotation? annotation = rangeList[index].item2;
      sentenceRowWidgets.add(SentenceSegmentListEdit(
        sentenceSegmentList: lyricSnippet.getSentenceSegmentList(segmentRange),

      ));
      if (index < rangeList.length - 1) {
        sentenceRowWidgets.add(TimingPointEdit());
        annotationRowWidgets.add(TimingPointEdit());
      }

      cursorSegmentIndex -= segmentRange.length;
    }

    return Column(
      children: [
        Row(children: annotationRowWidgets),
        Row(children: sentenceRowWidgets),
      ],
    );
  }
}
