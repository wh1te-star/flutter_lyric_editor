import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';

abstract class TextPaneCursor {
  Sentence sentence;
  SeekPosition seekPosition;

  TextPaneCursor(this.sentence, this.seekPosition);

  TextPaneCursor moveLeftCursor();
  TextPaneCursor moveRightCursor();

  List<TextPaneCursor?> getPhraseDividedCursors(Sentence sentence, List<PhrasePosition> phraseList);
  List<TextPaneCursor?> getWordDividedCursors(WordList wordList);
}
