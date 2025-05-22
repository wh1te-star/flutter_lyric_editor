import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/video_pane/colored_text_painter.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

class ColoredCaption extends StatelessWidget {
  static const String fontFamily = "Times New Roman";
  static const double fontSize = 40.0;
  final LyricSnippet lyricSnippet;
  final SeekPosition seekPosition;
  final Color color;

  const ColoredCaption(this.lyricSnippet, this.seekPosition, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> coloredSentenceSegments = [];
    for (int index = 0; index < lyricSnippet.sentenceSegments.length; index++) {
      coloredSentenceSegments.add(getColoredSentenceSegment(lyricSnippet, seekPosition, color, index));
    }
    return Wrap(
      children: coloredSentenceSegments,
    );
  }

  Widget getColoredSentenceSegment(
    LyricSnippet lyricSnippet,
    SeekPosition seekPosition,
    Color color,
    int index,
  ) {
    SentenceSegment sentenceSegment = lyricSnippet.sentenceSegments[index];
    double progress = getProgress(lyricSnippet, index);
    return CustomPaint(
      painter: ColoredTextPainter(
        text: sentenceSegment.word,
        progress: progress,
        fontBaseColor: color,
        fontFamily: fontFamily,
        fontSize: fontSize,
        firstOutlineWidth: 2,
        secondOutlineWidth: 4,
      ),
      size: getSizeFromFontInfo(sentenceSegment.word, fontSize, fontFamily),
    );
  }

  double getProgress(LyricSnippet lyricSnippet, int index) {
    SentenceSegmentIndex seekSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    if (seekSegmentIndex.isEmpty) {
      if (seekPosition <= lyricSnippet.startTimestamp) {
        return 0.0;
      }
      if (lyricSnippet.endTimestamp <= seekPosition) {
        return 1.0;
      }
      assert(false);
    }

    if (index == seekSegmentIndex.index) {
      return lyricSnippet.getSegmentProgress(seekPosition);
    }
    if (index < seekSegmentIndex.index) {
      return 1.0;
    }
    return 0.0;
  }
}
