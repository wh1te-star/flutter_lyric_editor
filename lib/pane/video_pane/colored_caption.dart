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
  final Sentence sentence;
  final SeekPosition seekPosition;
  final Color color;

  const ColoredCaption(this.sentence, this.seekPosition, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> coloredWords = [];
    for (int index = 0; index < sentence.words.length; index++) {
      coloredWords.add(getColoredWord(sentence, seekPosition, color, index));
    }
    return Wrap(
      children: coloredWords,
    );
  }

  Widget getColoredWord(
    Sentence sentence,
    SeekPosition seekPosition,
    Color color,
    int index,
  ) {
    Word word = sentence.words[index];
    double progress = getProgress(sentence, index);
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
      size: getSizeFromFontInfo(word.word, fontSize, fontFamily),
    );
  }

  double getProgress(Sentence sentence, int index) {
    WordIndex seekWordIndex = sentence.getWordIndexFromSeekPosition(seekPosition);
    if (seekWordIndex.isEmpty) {
      if (seekPosition <= sentence.startTimestamp) {
        return 0.0;
      }
      if (sentence.endTimestamp <= seekPosition) {
        return 1.0;
      }
      assert(false);
    }

    if (index == seekWordIndex.index) {
      return sentence.getWordProgress(seekPosition);
    }
    if (index < seekWordIndex.index) {
      return 1.0;
    }
    return 0.0;
  }
}
