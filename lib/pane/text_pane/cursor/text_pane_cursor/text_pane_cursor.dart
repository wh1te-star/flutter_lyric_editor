import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/phrase_position.dart';

abstract class TextPaneCursor {
  LyricSnippet lyricSnippet;
  SeekPosition seekPosition;

  TextPaneCursor(this.lyricSnippet, this.seekPosition);

  TextPaneCursor moveLeftCursor();
  TextPaneCursor moveRightCursor();

  List<TextPaneCursor?> getRangeDividedCursors(LyricSnippet lyricSnippet, List<SegmentRange> rangeList);
  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList);
}
