import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TextPaneCursor {
  LyricSnippetID lyricSnippetID;
  TextPaneCursor(this.lyricSnippetID);

  TextPaneCursor._privateConstructor(
    this.lyricSnippetID,
  );
  static final TextPaneCursor _empty = TextPaneCursor._privateConstructor(LyricSnippetID.empty);
  static TextPaneCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  List<TextPaneCursor?> getRangeDividedCursors(LyricSnippet lyricSnippet, List<SegmentRange> rangeList) {
    return [];
  }

  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList) {
    return [];
  }

  TextPaneCursor? shiftLeftBySentenceSegmentList(SentenceSegmentList sentenceSegmentList) {
    return this;
  }

  TextPaneCursor? shiftLeftBySentenceSegment(SentenceSegment sentenceSegment) {
    return this;
  }
}
