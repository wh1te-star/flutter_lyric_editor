import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/lyric_snippet_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/sentence_segment_list_edit.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/timing_point_edit.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/utility_functions.dart';
import 'package:tuple/tuple.dart';

class SentenceSelectionEdit extends LyricSnippetEdit<SentenceSelectionCursor> {
  const SentenceSelectionEdit(super.lyricSnippet, super.seekPosition, super.extPaneCursor, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> sentenceRowWidgets = [];
    List<Widget> annotationRowWidgets = [];
    List<Tuple2<SegmentRange, Annotation?>> rangeList = lyricSnippet.getRangeListForAnnotations(lyricSnippet.annotationMap.map, lyricSnippet.sentenceSegments.length);
    int highlightSegmentIndex = lyricSnippet.timing.getSegmentIndexFromSeekPosition(seekPosition);

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
    }

    return Column(
      children: [
        Row(children: annotationRowWidgets),
        Row(children: sentenceRowWidgets),
      ],
    );
  }
}

    /*
    for (int index = 0; index < rangeList.length; index++) {
      Tuple2<SegmentRange, Annotation?> element = rangeList[index];
      SegmentRange segmentRange = element.item1;
      Annotation? annotation = element.item2;

      if (segmentRange.isEmpty) {
        continue;
      }

      List<SentenceSegment> currentSegmentPartSentence = lyricSnippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1);
      String sentenceString = currentSegmentPartSentence.map((SentenceSegment segment) => segment.word).join('');
      String sentenceTimingPointString = "\xa0${LyricSnippetEdit.timingPointChar}\xa0" * (segmentRange.endIndex - segmentRange.startIndex);
      double sentenceRowWidth = getSizeFromTextStyle(sentenceString, textStyle).width + getSizeFromTextStyle(sentenceTimingPointString, textStyle).width + 10;
      int segmentCharLength = 0;

      if (annotation == null) {
        sentenceRowWidgets += sentenceLineWidgets(
          currentSegmentPartSentence,
          false,
          !textPaneCursor.isAnnotationSelection ? textPaneCursor : TextPaneCursor.emptyValue,
          highlightSegmentIndex,
          textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
          textStyle,
          textStyleIncursor,
          textStyle,
          textStyleIncursor,
        );

        if (!snippet.annotationMap.isEmpty) {
          annotationRowWidgets += sentenceLineWidgets(
            currentSegmentPartSentence,
            true,
            textPaneCursor.isAnnotationSelection ? textPaneCursor : TextPaneCursor.emptyValue,
            -1,
            textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
            annotationDummyTextStyle,
            annotationDummyTextStyle,
            annotationDummyTextStyle,
            annotationDummyTextStyle,
          );
        }

        segmentCharLength = currentSegmentPartSentence.map((segment) => segment.word.length).reduce((a, b) => a + b);
      } else {
        List<SentenceSegment> currentSegmentPartAnnotation = annotation.sentenceSegments;
        String annotationString = currentSegmentPartAnnotation.map((SentenceSegment segment) => segment.word).join('');
        String annotationTimingPointString = "\xa0${TextPaneProvider.timingPointChar}\xa0" * (annotation.sentenceSegments.length - 1);
        double annotationRowWidth = getSizeFromTextStyle(annotationString, annotationTextStyle).width + getSizeFromTextStyle(annotationTimingPointString, annotationTextStyle).width + 10;

        double rowWidth = sentenceRowWidth > annotationRowWidth ? sentenceRowWidth : annotationRowWidth;

        List<Widget> sentenceRow = sentenceLineWidgets(
          currentSegmentPartSentence,
          false,
          !textPaneCursor.isAnnotationSelection ? textPaneCursor : TextPaneCursor.emptyValue,
          highlightSegmentIndex,
          textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
          textStyle,
          textStyleIncursor,
          textStyle,
          textStyleIncursor,
        );

        sentenceRowWidgets += [
          SizedBox(
            width: rowWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: sentenceRow,
            ),
          ),
        ];

        if (!lyricSnippet.annotationMap.isEmpty) {
          int annotationHighlightSegmentIndex = textPaneCursor.annotationSegmentRange == segmentRange ? annotation.timing.getSegmentIndexFromSeekPosition(musicPlayerService.seekPosition) : -1;
          List<Widget> annotationRow = sentenceLineWidgets(
            currentSegmentPartAnnotation,
            true,
            textPaneCursor.isAnnotationSelection ? textPaneCursor : TextPaneCursor.emptyValue,
            annotationHighlightSegmentIndex,
            textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
            annotationTextStyle,
            annotationTextStyleIncursor,
            annotationTextStyle,
            annotationTextStyleIncursor,
          );

          if (!snippet.annotationMap.isEmpty) {
            annotationRowWidgets += [
              SizedBox(
                width: rowWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: annotationRow,
                ),
              ),
            ];
          }
        }

        if (!textPaneCursor.isAnnotationSelection) {
          segmentCharLength = currentSegmentPartSentence.map((segment) => segment.word.length).reduce((a, b) => a + b);
        } else {
          segmentCharLength = currentSegmentPartAnnotation.map((segment) => segment.word.length).reduce((a, b) => a + b);
        }
      }

      if (index < rangeList.length - 1) {
        sentenceRowWidgets.add(
          Text(
            "\xa0${TextPaneProvider.annotationEdgeChar}\xa0",
            style: textPaneCursor.isSegmentSelectionMode == false && textPaneCursor.isAnnotationSelection == false && sentenceString.length == textPaneCursor.charPosition ? textStyleIncursor : textStyle,
          ),
        );
        annotationRowWidgets.add(
          Text(
            "\xa0${TextPaneProvider.annotationEdgeChar}\xa0",
            style: textStyle,
          ),
        );
      }

      highlightSegmentIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
      if (!textPaneCursor.isAnnotationSelection) {
        cursorPositionInfo.index -= segmentCharLength;
        textPaneCursor.charPosition -= segmentCharLength;
        textPaneCursor.annotationSegmentRange.startIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
        textPaneCursor.annotationSegmentRange.endIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
      } else {
        textPaneCursor.annotationSegmentRange.startIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
        textPaneCursor.annotationSegmentRange.endIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: annotationRowWidgets,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: sentenceRowWidgets,
        ),
      ],
    );
    */
