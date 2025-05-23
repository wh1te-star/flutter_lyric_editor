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

  List<TextPaneCursor?> getPhrasePositionDividedCursors(Sentence sentence, List<PhrasePosition> phrasePositionList);
  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList);
}
