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
  LyricSnippet lyricSnippet;
  SeekPosition seekPosition;
  TextPaneCursor textPaneCursor;
  CursorBlinker cursorBlinker;
  LyricSnippetEdit(this.lyricSnippet, this.seekPosition, this.textPaneCursor, this.cursorBlinker);

  @override
  Widget build(BuildContext context) {
    List<Widget> annotationExistenceEdits = [];
    List<Tuple2<SegmentRange, Annotation?>> rangeList = lyricSnippet.getAnnotationExistenceRangeList(lyricSnippet.annotationMap.map, lyricSnippet.sentenceSegments.length);

    for (int index = 0; index < rangeList.length; index++) {
      SegmentRange segmentRange = rangeList[index].item1;
      Annotation? annotation = rangeList[index].item2;

      debugPrint(segmentRange.toString());
      Widget sentenceEdit = getSentenceEdit(lyricSnippet.getSentenceSegmentList(segmentRange), textPaneCursor, cursorBlinker);
      Widget annotationEdit = getAnnotationEdit(annotation, segmentRange, textPaneCursor, cursorBlinker);
      annotationExistenceEdits.add(Column(children: [
        sentenceEdit,
        annotationEdit,
      ]));

      if (index < rangeList.length - 1) {
        annotationExistenceEdits.add(const Column(
          children: [
            TimingPointEdit(),
            TimingPointEdit(),
          ],
        ));
      }
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
    Annotation? annotation,
    SegmentRange segmentRange,
    TextPaneCursor? textPaneCursor,
    CursorBlinker? cursorBlinker,
  ) {
    if (textPaneCursor is! AnnotationSelectionCursor) {
      textPaneCursor = null;
      cursorBlinker = null;
    }

    Widget annotationEdit = Container();
    if (annotation != null) {
      annotationEdit = SentenceSegmentListEdit(
        sentenceSegmentList: annotation.getSentenceSegmentList(segmentRange),
        textPaneCursor: textPaneCursor,
        cursorBlinker: cursorBlinker,
      );
    }
    return annotationEdit;
  }
}
