import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/pane/video_pane/colored_text_painter.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

class ColoredCaption extends StatelessWidget {
  static const String fontFamily = "Times New Roman";
  static const double fontSize = 40.0;
  final LyricSnippet lyricSnippet;
  final SeekPosition seekPosition;

  ColoredCaption(this.lyricSnippet, this.seekPosition);

  @override
  Widget build(BuildContext context) {
    int segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    return Wrap(
      children: lyricSnippet.sentenceSegments.asMap().entries.map((MapEntry<int, SentenceSegment> entry) {
        int index = entry.key;
        SentenceSegment sentenceSegment = entry.value;
        double progress = 0.0;
        if (index == segmentIndex) {
          progress = lyricSnippet.getSegmentProgress(seekPosition);
        }else if (index < segmentIndex) {
          progress = 1.0;
        }
        return CustomPaint(
          painter: ColoredTextPainter(
            text: sentenceSegment.word,
            progress: progress,
            fontBaseColor: Colors.greenAccent,
            fontFamily: fontFamily,
            fontSize: fontSize,
            firstOutlineWidth: 2,
            secondOutlineWidth: 4,
          ),
          size: getSizeFromFontInfo(sentenceSegment.word, fontSize, fontFamily),
        );
      }).toList(),
    );
  }
}
