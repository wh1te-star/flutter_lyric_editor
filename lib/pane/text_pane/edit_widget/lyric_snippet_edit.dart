import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/sentence_segment_list_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/timing_point_edit.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:tuple/tuple.dart';

class LyricSnippetEdit extends StatelessWidget {
  final Sentence lyricSnippet;
  final SeekPosition seekPosition;
  final TextPaneCursor? textPaneCursor;
  final CursorBlinker cursorBlinker;
  LyricSnippetEdit(this.lyricSnippet, this.seekPosition, this.textPaneCursor, this.cursorBlinker);

  @override
  Widget build(BuildContext context) {
    List<Widget> annotationExistenceEdits = [];
    List<Tuple2<Phrase, Reading?>> rangeAnnotationEntry = lyricSnippet.getAnnotationExistenceRangeList();
    List<Phrase> rangeList = rangeAnnotationEntry.map((Tuple2<Phrase, Reading?> entry) {
      return entry.item1;
    }).toList();
    List<TextPaneCursor?> cursorList = List.filled(rangeList.length, null);
    if (textPaneCursor != null) {
      cursorList = textPaneCursor!.getRangeDividedCursors(lyricSnippet, rangeList);
    }

    for (int index = 0; index < rangeAnnotationEntry.length; index++) {
      Phrase segmentRange = rangeAnnotationEntry[index].item1;
      Reading? annotation = rangeAnnotationEntry[index].item2;

      WordList? sentenceSubList = lyricSnippet.getSentenceSegmentList(segmentRange);
      WordList? annotationSubList = annotation?.timeline.wordList;

      TextPaneCursor? cursor = cursorList[index];
      bool isTimingPointPosition = false;
      if (cursor is SentenceSelectionCursor && cursor.insertionPosition == InsertionPosition(0)) {
        isTimingPointPosition = true;
      }
      if (cursor is AnnotationSelectionCursor && cursor.insertionPosition == InsertionPosition(0)) {
        isTimingPointPosition = true;
      }

      CursorBlinker? timingPointCursorBlinker;
      CursorBlinker? sentenceSegmentCursorBlinker;
      TextPaneCursor? sentenceSegmentCursor;
      if (isTimingPointPosition) {
        timingPointCursorBlinker = cursorBlinker;
      } else {
        sentenceSegmentCursorBlinker = cursorBlinker;
        sentenceSegmentCursor = cursor;
      }

      if (index > 0) {
        annotationExistenceEdits.add(Column(
          children: [
            TimingPointEdit(
              timingPoint: false,
              cursorBlinker: timingPointCursorBlinker,
            ),
            TimingPointEdit(
              timingPoint: false,
              cursorBlinker: timingPointCursorBlinker,
            ),
          ],
        ));
      }

      Widget sentenceEdit = getSentenceEdit(
        sentenceSubList,
        sentenceSegmentCursor,
        sentenceSegmentCursorBlinker,
      );
      Widget annotationEdit = getAnnotationEdit(
        annotationSubList,
        sentenceSegmentCursor,
        sentenceSegmentCursorBlinker,
      );
      annotationExistenceEdits.add(Column(children: [
        annotationEdit,
        sentenceEdit,
      ]));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: annotationExistenceEdits,
    );
  }

  Widget getSentenceEdit(
    WordList sentenceSegmentList,
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
    WordList? sentenceSegmentList,
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
