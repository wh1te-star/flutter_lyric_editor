import 'dart:typed_data';

import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
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

  bool isRangeSelection;
  SegmentSelectionCursorMover({
    required super.lyricSnippetMap,
    required super.textPaneCursor,
    required super.cursorBlinker,
    required super.seekPosition,
    required this.isRangeSelection,
  }) {
    assert(textPaneCursor is SegmentSelectionCursor, "Wrong type textPaneCursor is passed: SegmentSelectionCursor is expected but ${textPaneCursor.runtimeType} is passed.");
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");
  }

  bool isIDContained() {
    if (textPaneCursor.isEmpty) {
      return true;
    }
    LyricSnippet? lyricSnippet = lyricSnippetMap[textPaneCursor.lyricSnippetID];
    if (lyricSnippet == null) {
      return false;
    }
    return true;
  }

  factory SegmentSelectionCursorMover.withDefaultCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required CursorBlinker cursorBlinker,
    required SeekPosition seekPosition,
    required bool isRangeSelection,
  }) {
    final SegmentSelectionCursor tempCursor = SegmentSelectionCursor(
      lyricSnippetID,
      cursorBlinker,
      SegmentRange.empty,
    );
    final SegmentSelectionCursorMover tempMover = SegmentSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: tempCursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
    return tempMover.copyWith(segmentSelectionCursor: tempMover.defaultCursor(lyricSnippetID));
  }

  @override
  SegmentSelectionCursor defaultCursor(LyricSnippetID lyricSnippetID) {
    LyricSnippet lyricSnippet = lyricSnippetMap.getLyricSnippetByID(lyricSnippetID);
    SentenceSegmentIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    return SegmentSelectionCursor(textPaneCursor.lyricSnippetID, cursorBlinker, SegmentRange(segmentIndex, segmentIndex));
  }

  @override
  TextPaneCursorMover moveUpCursor() {
    cursorBlinker.restartCursorTimer();

    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == textPaneCursor.lyricSnippetID;
    });
    if (index <= 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index - 1];
    return SegmentSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursorMover moveDownCursor() {
    cursorBlinker.restartCursorTimer();

    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == textPaneCursor.lyricSnippetID;
    });
    if (index + 1 >= lyricSnippetMap.length) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index + 1];
    return SegmentSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursorMover moveLeftCursor() {
    SegmentSelectionCursor cursor = textPaneCursor as SegmentSelectionCursor;
    SegmentRange segmentRange = cursor.segmentRange;

    if (!isRangeSelection) {
      SentenceSegmentIndex currentIndex = segmentRange.startIndex;
      SentenceSegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < SentenceSegmentIndex(0)) {
        return this;
      }
      segmentRange.startIndex = nextIndex;

      segmentRange.endIndex = segmentRange.endIndex - 1;
    } else {
      SentenceSegmentIndex currentIndex = segmentRange.endIndex;
      SentenceSegmentIndex nextIndex = currentIndex - 1;
      if (nextIndex < segmentRange.startIndex) {
        return this;
      }
      segmentRange.endIndex = nextIndex;
    }

    return SegmentSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: cursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursorMover moveRightCursor() {
    SegmentSelectionCursor cursor = textPaneCursor as SegmentSelectionCursor;
    SegmentRange segmentRange = cursor.segmentRange;

    SentenceSegmentIndex currentIndex = segmentRange.endIndex;
    SentenceSegmentIndex nextIndex = currentIndex + 1;
    if (nextIndex.index >= lyricSnippetMap[cursor.lyricSnippetID]!.sentenceSegments.length) {
      return this;
    }
    segmentRange.endIndex = nextIndex;
    if (!isRangeSelection) {
      segmentRange.startIndex = segmentRange.startIndex + 1;
    }

    return SegmentSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: cursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursorMover updateCursor(
    LyricSnippetMap lyricSnippetMap,
    CursorBlinker cursorBlinker,
    SeekPosition seekPosition,
  ) {
    cursorBlinker.restartCursorTimer();
    return this;
  }

  TextPaneCursorMover exitSegmentSelectionMode() {
    return SentenceSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: textPaneCursor.lyricSnippetID,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
    );
  }

  TextPaneCursorMover switchToRangeSelection() {
    bool isRangeSelection = !this.isRangeSelection;
    return copyWith(isRangeSelection: isRangeSelection);
  }

  List<TextPaneCursor> getSegmentDividedCursors(LyricSnippet lyricSnippet, SentenceSegmentList sentenceSegmentList) {
    List<SegmentSelectionCursor> separatedCursors = List.filled(sentenceSegmentList.length, SegmentSelectionCursor.empty);
    return separatedCursors;
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
    SegmentSelectionCursor defaultCursor = SegmentSelectionCursor(
      lyricSnippetID,
      cursorBlinker,
      SegmentRange(SentenceSegmentIndex(0), SentenceSegmentIndex(0)),
    );
    for (int index = 0; index < sentenceSegmentList.length; index++) {
      SentenceSegmentIndex segmentIndex = SentenceSegmentIndex(index);
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
