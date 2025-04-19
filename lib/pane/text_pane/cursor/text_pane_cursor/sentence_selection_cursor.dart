import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SentenceSelectionCursor extends TextPaneCursor {
  InsertionPosition charPosition;
  Option option;

  SentenceSelectionCursor(
    super.lyricSnippetID,
    super.cursorBlinker,
    this.charPosition,
    this.option,
  );

  SentenceSelectionCursor._privateConstructor(
    super.lyricSnippetID,
    super.cursorBlinker,
    this.charPosition,
    this.option,
  );
  static final SentenceSelectionCursor _empty = SentenceSelectionCursor._privateConstructor(
    LyricSnippetID.empty,
    CursorBlinker.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static SentenceSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  List<TextPaneCursor?> getRangeDividedCursors(LyricSnippet lyricSnippet, List<SegmentRange> rangeList) {
    List<SentenceSelectionCursor?> separatedCursors = List.filled(rangeList.length, null);
    SentenceSelectionCursor shiftedCursor = copyWith();
    for (int index = 0; index < rangeList.length; index++) {
      SegmentRange segmentRange = rangeList[index];
      SentenceSegmentList? sentenceSubList = lyricSnippet.getSentenceSegmentList(segmentRange);
      SentenceSelectionCursor? nextCursor = shiftedCursor.shiftLeftBySentenceSegmentList(sentenceSubList);
      if (nextCursor == null) {
        separatedCursors[index] = shiftedCursor;
        break;
      }
      shiftedCursor = nextCursor;
    }
    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList) {
    List<SentenceSelectionCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    SentenceSelectionCursor shiftedCursor = copyWith();
    for (int index = 0; index < sentenceSegmentList.length; index++) {
      SentenceSegment sentenceSegment = sentenceSegmentList[index];
      SentenceSelectionCursor? nextCursor = shiftedCursor.shiftLeftBySentenceSegment(sentenceSegment);
      if (nextCursor == null) {
        separatedCursors[index] = shiftedCursor;
        break;
      }
      shiftedCursor = nextCursor;
    }
    return separatedCursors;
  }

  @override
  SentenceSelectionCursor? shiftLeftBySentenceSegmentList(SentenceSegmentList sentenceSegmentList) {
    if (charPosition.position - sentenceSegmentList.charLength < 0) {
      return null;
    }
    InsertionPosition newCharPosition = charPosition - sentenceSegmentList.charLength;
    return copyWith(charPosition: newCharPosition);
  }

  @override
  SentenceSelectionCursor? shiftLeftBySentenceSegment(SentenceSegment sentenceSegment) {
    if (charPosition.position - sentenceSegment.word.length < 0) {
      return null;
    }
    InsertionPosition newCharPosition = charPosition - sentenceSegment.word.length;
    return copyWith(charPosition: newCharPosition);
  }

  SentenceSelectionCursor copyWith({
    LyricSnippetID? lyricSnippetID,
    CursorBlinker? cursorBlinker,
    InsertionPosition? charPosition,
    Option? option,
  }) {
    return SentenceSelectionCursor(
      lyricSnippetID ?? this.lyricSnippetID,
      cursorBlinker ?? this.cursorBlinker,
      charPosition ?? this.charPosition,
      option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'SentenceSelectionCursor(ID: ${lyricSnippetID.id}, position: ${charPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSelectionCursor otherSentenceSegments = other as SentenceSelectionCursor;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (cursorBlinker != otherSentenceSegments.cursorBlinker) return false;
    if (charPosition != otherSentenceSegments.charPosition) return false;
    if (option != otherSentenceSegments.option) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetID.hashCode ^ cursorBlinker.hashCode ^ charPosition.hashCode ^ option.hashCode;
}
