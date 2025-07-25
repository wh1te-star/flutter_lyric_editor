import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/video_pane/colored_text_painter.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/position/seek_position_info/invalid_seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/timing_seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/word_seek_position_info.dart';
import 'package:lyric_editor/position/sentence_side_enum.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

class ColoredCaption extends StatelessWidget {
  static const String fontFamily = "Times New Roman";
  static const double fontSize = 40.0;
  final Sentence sentence;
  final SeekPosition seekPosition;
  final Color color;

  const ColoredCaption(this.sentence, this.seekPosition, this.color,
      {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> coloredWords = [];
    for (int index = 0; index < sentence.words.length; index++) {
      WordIndex wordIndex = WordIndex(index);
      coloredWords
          .add(getColoredWord(sentence, seekPosition, color, wordIndex));
    }
    return Wrap(
      children: coloredWords,
    );
  }

  Widget getColoredWord(
    Sentence sentence,
    SeekPosition seekPosition,
    Color color,
    WordIndex wordIndex,
  ) {
    /*
    double leftPadding = 0.0;
    if(wordIndex.index == 0){
      leftPadding = 20.0;
    }
    */
    double rightPadding = 0.0;
    if(wordIndex.index == sentence.words.length - 1){
      rightPadding = 20.0;
    }
    Word word = sentence.words[wordIndex];

    SeekPositionInfo seekPositionInfo =
        sentence.getSeekPositionInfoBySeekPosition(seekPosition.absolute);
    double progress = getProgress(sentence, wordIndex, seekPositionInfo);
    return CustomPaint(
      painter: ColoredTextPainter(
        text: word.word,
        progress: progress,
        fontBaseColor: color,
        fontFamily: fontFamily,
        fontSize: fontSize,
        firstOutlineWidth: 2,
        secondOutlineWidth: 4,
      ),
      size: getSizeFromFontInfo(word.word, fontSize, fontFamily) +
          Offset(rightPadding, 60.0),
    );
  }

  double getProgress(Sentence sentence, WordIndex wordIndex,
      SeekPositionInfo seekPositionInfo) {
    if (seekPositionInfo is InvalidSeekPositionInfo) {
      InvalidSeekPositionInfo info = seekPositionInfo;
      if (info.sentenceSide == SentenceSide.start) {
        return 0.0;
      } else {
        return 1.0;
      }
    }

    if (seekPositionInfo is TimingSeekPositionInfo) {
      TimingSeekPositionInfo info = seekPositionInfo;
      TimingIndex timingIndex = info.timingIndex;
      if (wordIndex.index < timingIndex.index) {
        return 1.0;
      } else {
        return 0.0;
      }
    }

    if (seekPositionInfo is WordSeekPositionInfo) {
      WordSeekPositionInfo info = seekPositionInfo;
      WordIndex seekingWordIndex = info.wordIndex;
      if (wordIndex < seekingWordIndex) {
        return 1.0;
      }
      if (wordIndex > seekingWordIndex) {
        return 0.0;
      }

      AbsoluteSeekPosition leftSeekPosition =
          sentence.getLeftTiming(wordIndex).seekPosition.absolute;
      AbsoluteSeekPosition rightSeekPosition =
          sentence.getRightTiming(wordIndex).seekPosition.absolute;
      double numerator = seekPosition.absolute.position.toDouble() -
          leftSeekPosition.position.toDouble();
      double denominator = rightSeekPosition.position.toDouble() -
          leftSeekPosition.position.toDouble();
      return numerator / denominator;
    }
    assert(false, "An unexpected type of the seek position info type.");
    return -1.0;
  }
}
