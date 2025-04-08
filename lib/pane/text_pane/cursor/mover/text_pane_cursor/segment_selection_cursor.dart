import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SegmentSelectionCursor extends TextPaneCursor {
  SegmentRange segmentRange;

  SegmentSelectionCursor(
    super.lyricSnippetID,
    super.cursorBlinker,
    this.segmentRange,
  );

  SegmentSelectionCursor._privateConstructor(
    super.lyricSnippetID,
    super.cursorBlinker,
    this.segmentRange,
  );
  static final SegmentSelectionCursor _empty = SegmentSelectionCursor._privateConstructor(
    LyricSnippetID.empty,
    CursorBlinker.empty,
    SegmentRange.empty,
  );
  static SegmentSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  List<TextPaneCursor?> getRangeDividedCursors(LyricSnippet lyricSnippet, List<SegmentRange> rangeList) {
    SegmentSelectionCursor cursor = copyWith();
    List<SegmentSelectionCursor?> separatedCursors = List.filled(rangeList.length, null);

    int startRangeIndex = rangeList.indexWhere((SegmentRange segmentRange) {
      return segmentRange.isInRange(segmentRange.startIndex);
    });
    int endRangeIndex = rangeList.indexWhere((SegmentRange segmentRange) {
      return segmentRange.isInRange(segmentRange.endIndex);
    });

    if (startRangeIndex == endRangeIndex) {
      separatedCursors[startRangeIndex] = copyWith();
      return separatedCursors;
    }

    separatedCursors[startRangeIndex] = cursor.copyWith(
      segmentRange: SegmentRange(
        cursor.segmentRange.startIndex,
        rangeList[startRangeIndex].endIndex,
      ),
    );
    for (int index = startRangeIndex + 1; index <= endRangeIndex - 1; index++) {
      separatedCursors[index] = cursor.copyWith(segmentRange: rangeList[index]);
    }
    separatedCursors[startRangeIndex] = cursor.copyWith(
      segmentRange: SegmentRange(
        rangeList[startRangeIndex].startIndex,
        cursor.segmentRange.endIndex,
      ),
    );

    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList) {
    SegmentSelectionCursor cursor = copyWith();
    List<SegmentSelectionCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    SegmentSelectionCursor defaultCursor = SegmentSelectionCursor(
      lyricSnippetID,
      cursorBlinker,
      SegmentRange(SegmentIndex(0), SegmentIndex(0)),
    );
    for (int index = 0; index < sentenceSegmentList.length; index++) {
      SegmentIndex segmentIndex = SegmentIndex(index);
      if (cursor.segmentRange.isInRange(segmentIndex)) {
        separatedCursors[index] = defaultCursor.copyWith();
      }
    }
    return separatedCursors;
  }

  @override
  SegmentSelectionCursor shiftLeftBySentenceSegmentList(SentenceSegmentList sentenceSegmentList) {
    if (segmentRange.startIndex.index - 1 < 0 || segmentRange.endIndex.index - 1 < 0) {
      return SegmentSelectionCursor.empty;
    }
    SegmentIndex startIndex = segmentRange.startIndex - sentenceSegmentList.segmentLength;
    SegmentIndex endIndex = segmentRange.endIndex - sentenceSegmentList.segmentLength;
    SegmentRange newRange = SegmentRange(startIndex, endIndex);
    return copyWith(segmentRange: newRange);
  }

  @override
  SegmentSelectionCursor shiftLeftBySentenceSegment(SentenceSegment sentenceSegment) {
    if (segmentRange.startIndex.index - 1 < 0 || segmentRange.endIndex.index - 1 < 0) {
      return SegmentSelectionCursor.empty;
    }
    SegmentIndex startIndex = segmentRange.startIndex - 1;
    SegmentIndex endIndex = segmentRange.endIndex - 1;
    SegmentRange newRange = SegmentRange(startIndex, endIndex);
    return copyWith(segmentRange: newRange);
  }

  SegmentSelectionCursor copyWith({
    LyricSnippetID? lyricSnippetID,
    CursorBlinker? cursorBlinker,
    SegmentRange? segmentRange,
  }) {
    return SegmentSelectionCursor(
      lyricSnippetID ?? this.lyricSnippetID,
      cursorBlinker ?? this.cursorBlinker,
      segmentRange ?? this.segmentRange,
    );
  }

  @override
  String toString() {
    return 'SegmentSelectionCursor(ID: ${lyricSnippetID.id}, segmentIndex: $segmentRange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SegmentSelectionCursor otherSentenceSegments = other as SegmentSelectionCursor;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (cursorBlinker != otherSentenceSegments.cursorBlinker) return false;
    if (segmentRange != otherSentenceSegments.segmentRange) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetID.hashCode ^ cursorBlinker.hashCode ^ segmentRange.hashCode;
}
