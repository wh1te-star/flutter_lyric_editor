import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';

abstract class TextPaneCursor {
  Sentence lyricSnippet;
  SeekPosition seekPosition;

  TextPaneCursor(this.lyricSnippet, this.seekPosition);

  TextPaneCursor moveLeftCursor();
  TextPaneCursor moveRightCursor();

  List<TextPaneCursor?> getRangeDividedCursors(Sentence lyricSnippet, List<Phrase> rangeList);
  List<TextPaneCursor?> getSegmentDividedCursors(WordList sentenceSegmentList);
}
