import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';

class SegmentSelectionCursor extends TextPaneCursor {
  SegmentRange segmentRange;
  bool isRangeSelection = false;

  SegmentSelectionCursor({
    required LyricSnippet lyricSnippet,
    required SeekPosition seekPosition,
    required this.segmentRange,
    required this.isRangeSelection,
  }) : super(lyricSnippet, seekPosition);

  SegmentSelectionCursor._privateConstructor(
    super.lyricSnippet,
    super.seekPosition,
    this.segmentRange,
    this.isRangeSelection,
  );
  static final SegmentSelectionCursor _empty = SegmentSelectionCursor._privateConstructor(
    LyricSnippet.empty,
    SeekPosition.empty,
    SegmentRange.empty,
    false,
  );
  static SegmentSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  SegmentSelectionCursor defaultCursor() {
    SentenceSegmentIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    return SegmentSelectionCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: SegmentRange(segmentIndex, segmentIndex),
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    SegmentRange nextSegmentRange = segmentRange.copyWith();

    if (!isRangeSelection) {
      SentenceSegmentIndex currentIndex = segmentRange.startIndex;
      SentenceSegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < SentenceSegmentIndex(0)) {
        return this;
      }
      nextSegmentRange.startIndex = nextIndex;

      nextSegmentRange.endIndex = segmentRange.endIndex - 1;
    } else {
      SentenceSegmentIndex currentIndex = segmentRange.endIndex;
      SentenceSegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < segmentRange.startIndex) {
        return this;
      }
      nextSegmentRange.startIndex = segmentRange.startIndex;
      nextSegmentRange.endIndex = nextIndex;
    }

    return SegmentSelectionCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: nextSegmentRange,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursor moveRightCursor() {
    SegmentRange nextSegmentRange = segmentRange.copyWith();

    SentenceSegmentIndex currentIndex = segmentRange.endIndex;
    SentenceSegmentIndex nextIndex = currentIndex + 1;
    if (nextIndex.index >= lyricSnippet.sentenceSegments.length) {
      return this;
    }

    nextSegmentRange.endIndex = nextIndex;
    if (!isRangeSelection) {
      nextSegmentRange.startIndex = segmentRange.startIndex + 1;
    }

    return SegmentSelectionCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: nextSegmentRange,
      isRangeSelection: isRangeSelection,
    );
  }

  TextPaneCursor exitSegmentSelectionMode() {
    return SentenceSelectionCursor.defaultCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
    );
  }

  TextPaneCursor switchToRangeSelection() {
    bool isRangeSelection = !this.isRangeSelection;
    return copyWith(isRangeSelection: isRangeSelection);
  }

  @override
  List<TextPaneCursor?> getRangeDividedCursors(LyricSnippet lyricSnippet, List<SegmentRange> rangeList) {
    SegmentSelectionCursor cursor = copyWith();
    List<SegmentSelectionCursor?> separatedCursors = List.filled(rangeList.length, null);

    int startRangeIndex = rangeList.indexWhere((SegmentRange segmentRange) {
      return segmentRange.isInRange(cursor.segmentRange.startIndex);
    });
    int endRangeIndex = rangeList.indexWhere((SegmentRange segmentRange) {
      return segmentRange.isInRange(cursor.segmentRange.endIndex);
    });

    int shiftLength = 0;
    for (int index = 0; index <= endRangeIndex; index++) {
      SentenceSegmentIndex startIndex = rangeList[index].startIndex - shiftLength;
      SentenceSegmentIndex endIndex = rangeList[index].endIndex - shiftLength;
      if (index == startRangeIndex) {
        startIndex = cursor.segmentRange.startIndex - shiftLength;
      }
      if (index == endRangeIndex) {
        endIndex = cursor.segmentRange.endIndex - shiftLength;
      }

      if (startRangeIndex <= index && index <= endRangeIndex) {
        separatedCursors[index] = cursor.copyWith(
          segmentRange: SegmentRange(startIndex, endIndex),
        );
      }
      shiftLength += rangeList[index].length;
    }

    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList) {
    SegmentSelectionCursor cursor = copyWith();
    List<SegmentSelectionCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    SegmentSelectionCursor initialCursor = SegmentSelectionCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: SegmentRange(SentenceSegmentIndex(0), SentenceSegmentIndex(0)),
      isRangeSelection: isRangeSelection,
    );
    for (int index = 0; index < sentenceSegmentList.length; index++) {
      SentenceSegmentIndex segmentIndex = SentenceSegmentIndex(index);
      if (cursor.segmentRange.isInRange(segmentIndex)) {
        separatedCursors[index] = initialCursor.copyWith();
      }
    }
    return separatedCursors;
  }

  @override
  SegmentSelectionCursor shiftLeftBySentenceSegmentList(SentenceSegmentList sentenceSegmentList) {
    if (segmentRange.startIndex.index - 1 < 0 || segmentRange.endIndex.index - 1 < 0) {
      return SegmentSelectionCursor.empty;
    }
    SentenceSegmentIndex startIndex = segmentRange.startIndex - sentenceSegmentList.segmentLength;
    SentenceSegmentIndex endIndex = segmentRange.endIndex - sentenceSegmentList.segmentLength;
    SegmentRange newRange = SegmentRange(startIndex, endIndex);
    return copyWith(segmentRange: newRange);
  }

  @override
  SegmentSelectionCursor shiftLeftBySentenceSegment(SentenceSegment sentenceSegment) {
    if (segmentRange.startIndex.index - 1 < 0 || segmentRange.endIndex.index - 1 < 0) {
      return SegmentSelectionCursor.empty;
    }
    SentenceSegmentIndex startIndex = segmentRange.startIndex - 1;
    SentenceSegmentIndex endIndex = segmentRange.endIndex - 1;
    SegmentRange newRange = SegmentRange(startIndex, endIndex);
    return copyWith(segmentRange: newRange);
  }

  SegmentSelectionCursor copyWith({
    LyricSnippet? lyricSnippet,
    SeekPosition? seekPosition,
    SegmentRange? segmentRange,
    bool? isRangeSelection,
  }) {
    return SegmentSelectionCursor(
      lyricSnippet: lyricSnippet ?? this.lyricSnippet,
      seekPosition: seekPosition ?? this.seekPosition,
      segmentRange: segmentRange ?? this.segmentRange,
      isRangeSelection: isRangeSelection ?? this.isRangeSelection,
    );
  }

  @override
  String toString() {
    return 'SegmentSelectionCursor(ID: $lyricSnippet, segmentIndex: $segmentRange)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SegmentSelectionCursor otherSentenceSegments = other as SegmentSelectionCursor;
    if (lyricSnippet != otherSentenceSegments.lyricSnippet) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (segmentRange != otherSentenceSegments.segmentRange) return false;
    if (isRangeSelection != otherSentenceSegments.isRangeSelection) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippet.hashCode ^ seekPosition.hashCode ^ segmentRange.hashCode ^ isRangeSelection.hashCode;
}
