import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/pane/video_pane/colored_text_painter.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

class AnnotationRangeCaption extends StatelessWidget {
  static const String fontFamily = "Times New Roman";
  static const double fontSize = 40.0;
  final LyricSnippet lyricSnippet;
  final SeekPosition seekPosition;
  final Color color;

  const AnnotationRangeCaption(this.lyricSnippet, this.seekPosition, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> annotationRangeWidgets = complementAnnotationRange(lyricSnippet.annotationMap.keys.toList()).map((SegmentRange segmentRange) {
      String rangeWords = lyricSnippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1).map((sentenceSegment) => sentenceSegment.word).join('');
      if (lyricSnippet.annotationMap.map.containsKey(segmentRange)) {
        rangeWords = lyricSnippet.annotationMap.map[segmentRange]!.sentence;
      }
      return CustomPaint(
        painter: ColoredTextPainter(
          text: rangeWords,
          progress: 0.5,
          fontBaseColor: color,
          fontFamily: fontFamily,
          fontSize: fontSize,
          firstOutlineWidth: 2,
          secondOutlineWidth: 4,
        ),
        size: getSizeFromFontInfo(rangeWords, fontSize, fontFamily),
      );
    }).toList();

    return Wrap(children: annotationRangeWidgets);
  }

  List<SegmentRange> complementAnnotationRange(List<SegmentRange> ranges) {
    final int segmentLength = lyricSnippet.sentenceSegments.length;
    List<SegmentRange> complementedRange = [];
    int currentStartIndex = 0;
    for (SegmentRange range in ranges) {
      int startIndex = range.startIndex;
      int endIndex = range.endIndex;
      if (currentStartIndex <= startIndex - 1) {
        complementedRange.add(SegmentRange(currentStartIndex, startIndex - 1));
      }
      complementedRange.add(range);
      currentStartIndex = endIndex + 1;
    }
    if (currentStartIndex <= segmentLength - 1) {
      complementedRange.add(SegmentRange(currentStartIndex, segmentLength - 1));
    }
    return complementedRange;
  }
}
