import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/sentence_segment_list_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/timing_point_edit.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:tuple/tuple.dart';

class LyricSnippetEdit extends StatelessWidget {
  final LyricSnippet lyricSnippet;
  final SeekPosition seekPosition;
  final TextPaneCursor textPaneCursor;
  final CursorBlinker cursorBlinker;
  LyricSnippetEdit(this.lyricSnippet, this.seekPosition, this.textPaneCursor, this.cursorBlinker);

  @override
  Widget build(BuildContext context) {
    List<Widget> annotationExistenceEdits = [];
    List<Tuple2<SegmentRange, Annotation?>> rangeList = lyricSnippet.getAnnotationExistenceRangeList();

    for (int index = 0; index < rangeList.length; index++) {
      SegmentRange segmentRange = rangeList[index].item1;
      Annotation? annotation = rangeList[index].item2;

      SentenceSegmentList? sentenceSubList = lyricSnippet.getSentenceSegmentList(segmentRange);
      SentenceSegmentList? annotationSubList = annotation?.getSentenceSegmentList(segmentRange);

      TextPaneCursor? useCursor;
      bool isTimingPointPosition = false;
      if (index == incursorIndex) {
        useCursor = adjustedCursor;
        if (adjustedCursor is SentenceSelectionCursor && adjustedCursor.charPosition.position == 0) {
          isTimingPointPosition = true;
        }
      }

      if (index > 0) {
        annotationExistenceEdits.add(Column(
          children: [
            TimingPointEdit(
              timingPoint: false,
              cursorBlinker: isTimingPointPosition ? cursorBlinker : null,
            ),
            TimingPointEdit(
              timingPoint: false,
              cursorBlinker: isTimingPointPosition ? cursorBlinker : null,
            ),
          ],
        ));
      }

      Widget sentenceEdit = getSentenceEdit(
        sentenceSubList,
        !isTimingPointPosition ? useCursor : null,
        cursorBlinker,
      );
      Widget annotationEdit = getAnnotationEdit(
        annotationSubList,
        !isTimingPointPosition ? useCursor : null,
        cursorBlinker,
      );
      annotationExistenceEdits.add(Column(children: [
        sentenceEdit,
        annotationEdit,
      ]));
    }

    return Row(children: annotationExistenceEdits);
  }

  Widget getSentenceEdit(
    SentenceSegmentList sentenceSegmentList,
    TextPaneCursor? textPaneCursor,
    CursorBlinker? cursorBlinker,
  ) {
    if (textPaneCursor is! SentenceSelectionCursor && textPaneCursor is! SegmentSelectionCursor) {
      textPaneCursor = null;
      cursorBlinker = null;
    }

    return SentenceSegmentListEdit(
      sentenceSegmentList: sentenceSegmentList,
      textPaneCursor: textPaneCursor,
      cursorBlinker: cursorBlinker,
    );
  }

  Widget getAnnotationEdit(
    SentenceSegmentList? sentenceSegmentList,
    TextPaneCursor? textPaneCursor,
    CursorBlinker? cursorBlinker,
  ) {
    if (textPaneCursor is! AnnotationSelectionCursor) {
      textPaneCursor = null;
      cursorBlinker = null;
    }

    Widget annotationEdit = Container();
    if (sentenceSegmentList != null) {
      annotationEdit = SentenceSegmentListEdit(
        sentenceSegmentList: sentenceSegmentList,
        textPaneCursor: textPaneCursor,
        cursorBlinker: cursorBlinker,
      );
    }
    return annotationEdit;
  }
}
