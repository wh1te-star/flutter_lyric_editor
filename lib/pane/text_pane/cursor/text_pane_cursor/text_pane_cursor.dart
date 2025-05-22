import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_range.dart';

abstract class TextPaneCursor {
  LyricSnippet lyricSnippet;
  SeekPosition seekPosition;

  TextPaneCursor(this.lyricSnippet, this.seekPosition);

  TextPaneCursor moveLeftCursor();
  TextPaneCursor moveRightCursor();

  List<TextPaneCursor?> getRangeDividedCursors(LyricSnippet lyricSnippet, List<SegmentRange> rangeList);
  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList);
}
