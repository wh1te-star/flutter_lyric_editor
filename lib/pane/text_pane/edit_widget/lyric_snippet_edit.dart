import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/sentence_segment_list_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/timing_point_edit.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:tuple/tuple.dart';

class LyricSnippetEdit extends StatelessWidget {
  final LyricSnippet lyricSnippet;
  final SeekPosition seekPosition;
  final TextPaneCursorMover textPaneCursorMover;
  final CursorBlinker cursorBlinker;
  LyricSnippetEdit(this.lyricSnippet, this.seekPosition, this.textPaneCursorMover, this.cursorBlinker);

  @override
  Widget build(BuildContext context) {
    List<Widget> annotationExistenceEdits = [];
    List<Tuple2<SegmentRange, Annotation?>> rangeAnnotationEntry = lyricSnippet.getAnnotationExistenceRangeList();
    List<SegmentRange> rangeList = rangeAnnotationEntry.map((Tuple2<SegmentRange, Annotation?> entry) {
      return entry.item1;
    }).toList();
    List<TextPaneCursor?> cursorList = textPaneCursorMover.getSeparatedCursors(lyricSnippet, rangeList);

    for (int index = 0; index < rangeAnnotationEntry.length; index++) {
      SegmentRange segmentRange = rangeAnnotationEntry[index].item1;
      Annotation? annotation = rangeAnnotationEntry[index].item2;

      SentenceSegmentList? sentenceSubList = lyricSnippet.getSentenceSegmentList(segmentRange);
      SentenceSegmentList? annotationSubList = annotation?.getSentenceSegmentList(segmentRange);

      TextPaneCursor? cursor = cursorList[index];
      bool isTimingPointPosition = false;
      if (cursor != null) {
        if (cursor is SentenceSelectionCursor && cursor.charPosition == InsertionPosition(0)) {
          isTimingPointPosition = true;
        }
        if (cursor is AnnotationSelectionCursor && cursor.charPosition == InsertionPosition(0)) {
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
        !isTimingPointPosition ? cursor : null,
        cursorBlinker,
      );
      Widget annotationEdit = getAnnotationEdit(
        annotationSubList,
        !isTimingPointPosition ? cursor : null,
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
