import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_range.dart';

abstract class TextPaneCursor {
  Sentence sentence;
  SeekPosition seekPosition;

  TextPaneCursor(this.sentence, this.seekPosition);

  TextPaneCursor moveLeftCursor();
  TextPaneCursor moveRightCursor();

  List<TextPaneCursor?> getWordRangeDividedCursors(Sentence sentence, List<WordRange> wordRangeList);
  List<TextPaneCursor?> getWordDividedCursors(WordList wordList);
}
