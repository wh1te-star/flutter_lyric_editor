import 'dart:typed_data';

import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SegmentSelectionCursor extends TextPaneCursor {
  SegmentRange segmentRange;
  bool isRangeSelection = false;

  SegmentSelectionCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
    required this.segmentRange,
    required this.isRangeSelection,
  }) : super(lyricSnippetMap, lyricSnippetID, seekPosition) {
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");
  }

  SegmentSelectionCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.seekPosition,
    this.segmentRange,
    this.isRangeSelection,
  );
  static final SegmentSelectionCursor _empty = SegmentSelectionCursor._privateConstructor(
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    SeekPosition.empty,
    SegmentRange.empty,
    false,
  );
  static SegmentSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  bool isIDContained() {
    LyricSnippet? lyricSnippet = lyricSnippetMap[lyricSnippetID];
    if (lyricSnippet == null) {
      return false;
    }
    return true;
  }

  @override
  SegmentSelectionCursor defaultCursor(LyricSnippetID lyricSnippetID) {
    LyricSnippet lyricSnippet = lyricSnippetMap.getLyricSnippetByID(lyricSnippetID);
    SentenceSegmentIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    return SegmentSelectionCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: SegmentRange(segmentIndex, segmentIndex),
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursor moveUpCursor() {
    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index <= 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index - 1];
    return defaultCursor(nextLyricSnippetID);
  }

  @override
  TextPaneCursor moveDownCursor() {
    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index + 1 >= lyricSnippetMap.length) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index + 1];
    return defaultCursor(nextLyricSnippetID);
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
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
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
    if (nextIndex.index >= lyricSnippetMap[lyricSnippetID]!.sentenceSegments.length) {
      return this;
    }

    nextSegmentRange.endIndex = nextIndex;
    if (!isRangeSelection) {
      nextSegmentRange.startIndex = segmentRange.startIndex + 1;
    }

    return SegmentSelectionCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: nextSegmentRange,
      isRangeSelection: isRangeSelection,
    );
  }

  @override
  TextPaneCursor updateCursor(
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  ) {
    return SegmentSelectionCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: segmentRange,
      isRangeSelection: isRangeSelection,
    );
  }

  TextPaneCursor exitSegmentSelectionMode() {
    return SentenceSelectionCursor.defaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
    );
  }

  TextPaneCursor switchToRangeSelection() {
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
