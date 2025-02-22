import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/text_pane_provider.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:tuple/tuple.dart';

class LyricSnippetEdit extends StatelessWidget {
  static const String fontFamily = "Times New Roman";
  static const double fontSize = 40.0;
  final LyricSnippet lyricSnippet;
  final SeekPosition seekPosition;
  final TextPaneCursor textPaneCursor;

  const LyricSnippetEdit(this.lyricSnippet, this.seekPosition, this.textPaneCursor, {super.key});

  @override
  Widget build(BuildContext context) {
    int segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    return snippetEditLine(lyricSnippet, seekPosition, textPaneCursor);
  }

  Widget snippetEditLine(LyricSnippet snippet, SeekPosition seekPosition, TextPaneCursor textPaneCursor) {
    TextStyle textStyle = const TextStyle(
      color: Colors.black,
    );
    TextStyle textStyleIncursor = TextStyle(
      color: textPaneProvider.cursorBlinker.isCursorVisible ? Colors.white : Colors.black,
      background: textPaneProvider.cursorBlinker.isCursorVisible ? (Paint()..color = Colors.black) : null,
    );
    TextStyle annotationTextStyle = const TextStyle(
      color: Colors.black,
    );
    TextStyle annotationDummyTextStyle = const TextStyle(
      color: Colors.transparent,
    );
    TextStyle annotationTextStyleIncursor = TextStyle(
      color: Colors.white,
      background: Paint()..color = Colors.black,
    );
    List<Widget> sentenceRowWidgets = [];
    List<Widget> annotationRowWidgets = [];
    List<Tuple2<SegmentRange, Annotation?>> rangeList = getRangeListForAnnotations(snippet.annotationMap.map, snippet.sentenceSegments.length);
    int highlightSegmentIndex = snippet.timing.getSegmentIndexFromSeekPosition(musicPlayerService.seekPosition);

    TextPaneCursor cursor = textPaneProvider.cursor.copyWith();

    for (int index = 0; index < rangeList.length; index++) {
      Tuple2<SegmentRange, Annotation?> element = rangeList[index];
      SegmentRange segmentRange = element.item1;
      Annotation? annotation = element.item2;

      if (segmentRange.isEmpty) {
        continue;
      }

      List<SentenceSegment> currentSegmentPartSentence = snippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1);
      String sentenceString = currentSegmentPartSentence.map((SentenceSegment segment) => segment.word).join('');
      String sentenceTimingPointString = "\xa0${TextPaneProvider.timingPointChar}\xa0" * (segmentRange.endIndex - segmentRange.startIndex);
      double sentenceRowWidth = getSizeFromTextStyle(sentenceString, textStyle).width + getSizeFromTextStyle(sentenceTimingPointString, textStyle).width + 10;
      int segmentCharLength = 0;

      if (annotation == null) {
        sentenceRowWidgets += sentenceLineWidgets(
          currentSegmentPartSentence,
          false,
          !cursor.isAnnotationSelection ? cursor : TextPaneCursor.emptyValue,
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
            cursor.isAnnotationSelection ? cursor : TextPaneCursor.emptyValue,
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
          !cursor.isAnnotationSelection ? cursor : TextPaneCursor.emptyValue,
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

        if (!snippet.annotationMap.isEmpty) {
          int annotationHighlightSegmentIndex = textPaneProvider.cursor.annotationSegmentRange == segmentRange ? annotation.timing.getSegmentIndexFromSeekPosition(musicPlayerService.seekPosition) : -1;
          List<Widget> annotationRow = sentenceLineWidgets(
            currentSegmentPartAnnotation,
            true,
            cursor.isAnnotationSelection ? cursor : TextPaneCursor.emptyValue,
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

        if (!cursor.isAnnotationSelection) {
          segmentCharLength = currentSegmentPartSentence.map((segment) => segment.word.length).reduce((a, b) => a + b);
        } else {
          segmentCharLength = currentSegmentPartAnnotation.map((segment) => segment.word.length).reduce((a, b) => a + b);
        }
      }

      if (index < rangeList.length - 1) {
        sentenceRowWidgets.add(
          Text(
            "\xa0${TextPaneProvider.annotationEdgeChar}\xa0",
            style: cursor.isSegmentSelectionMode == false && cursor.isAnnotationSelection == false && sentenceString.length == cursor.charPosition ? textStyleIncursor : textStyle,
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
      if (!cursor.isAnnotationSelection) {
        cursorPositionInfo.index -= segmentCharLength;
        cursor.charPosition -= segmentCharLength;
        cursor.annotationSegmentRange.startIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
        cursor.annotationSegmentRange.endIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
      } else {
        cursor.annotationSegmentRange.startIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
        cursor.annotationSegmentRange.endIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
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
  }
}
