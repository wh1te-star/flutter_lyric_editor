import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/pane/text_pane/cursor/annotation_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/segment_selection_cursor_mover.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor_mover.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_point_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/position/timing_point_index.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SentenceSelectionCursorMover extends TextPaneCursorMover {
  SentenceSelectionCursorMover({
    required super.lyricSnippetMap,
    required super.textPaneCursor,
    required super.cursorBlinker,
    required super.seekPosition,
  }) {
    assert(textPaneCursor is SentenceSelectionCursor, "Wrong type textPaneCursor is passed: SentenceSelectionCursor is expected but ${textPaneCursor.runtimeType} is passed.");
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");
  }

  bool isIDContained() {
    if (lyricSnippetMap.isEmpty || textPaneCursor.isEmpty) {
      return true;
    }
    LyricSnippet? lyricSnippet = lyricSnippetMap[textPaneCursor.lyricSnippetID];
    if (lyricSnippet == null) {
      return false;
    }
    return true;
  }

  factory SentenceSelectionCursorMover.withDefaultCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required CursorBlinker cursorBlinker,
    required SeekPosition seekPosition,
  }) {
    final SentenceSelectionCursor tempCursor = SentenceSelectionCursor(
      lyricSnippetID,
      cursorBlinker,
      InsertionPosition.empty,
      Option.former,
    );
    final SentenceSelectionCursorMover tempMover = SentenceSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: tempCursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
    );
    return tempMover.copyWith(sentenceSelectionCursor: tempMover.defaultCursor(lyricSnippetID));
  }

  @override
  SentenceSelectionCursor defaultCursor(LyricSnippetID lyricSnippetID) {
    if (lyricSnippetMap.isEmpty) {
      return SentenceSelectionCursor(LyricSnippetID.empty, cursorBlinker, InsertionPosition.empty, Option.former);
    }
    LyricSnippet lyricSnippet = lyricSnippetMap.getLyricSnippetByID(lyricSnippetID);
    SentenceSegmentIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition charPosition = lyricSnippet.timing.leftTimingPoint(segmentIndex).charPosition + 1;
    return SentenceSelectionCursor(textPaneCursor.lyricSnippetID, cursorBlinker, charPosition, Option.former);
  }

  @override
  TextPaneCursorMover moveUpCursor() {
    cursorBlinker.restartCursorTimer();

    LyricSnippet lyricSnippet = lyricSnippetMap[textPaneCursor.lyricSnippetID]!;
    SegmentRange annotationIndex = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    if (annotationIndex.isNotEmpty) {
      return AnnotationSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: textPaneCursor.lyricSnippetID,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
    }

    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == textPaneCursor.lyricSnippetID;
    });
    if (index <= 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index - 1];
    return SentenceSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneCursorMover moveDownCursor() {
    cursorBlinker.restartCursorTimer();

    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == textPaneCursor.lyricSnippetID;
    });
    if (index <= 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index + 1];
    LyricSnippet nextLyricSnippet = lyricSnippetMap[nextLyricSnippetID]!;

    SegmentRange annotationIndex = nextLyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    if (annotationIndex.isNotEmpty) {
      return AnnotationSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: textPaneCursor.lyricSnippetID,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
    }

    return SentenceSelectionCursorMover.withDefaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneCursorMover moveLeftCursor() {
    SentenceSelectionCursor cursor = textPaneCursor as SentenceSelectionCursor;
    LyricSnippet lyricSnippet = lyricSnippetMap[cursor.lyricSnippetID]!;

    InsertionPosition insertionPosition = cursor.charPosition;
    InsertionPositionInfo? insertionPositionInfo = lyricSnippet.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");

    debugPrint("seekPositon: $seekPosition");
    SentenceSegmentIndex highlightSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition nextInsertionPosition = InsertionPosition.empty;
    if (insertionPositionInfo is SentenceSegmentInsertionPositionInfo) {
      SentenceSegmentIndex segmentIndex = insertionPositionInfo.sentenceSegmentIndex;
      assert(segmentIndex == highlightSegmentIndex, "An unexpected state was occurred.");
      nextInsertionPosition = insertionPosition - 1;
      if (nextInsertionPosition <= InsertionPosition(0)) {
        return this;
      }
    }

    if (insertionPositionInfo is TimingPointInsertionPositionInfo) {
      if (cursor.option == Option.latter) {
        SentenceSelectionCursor movedCursor = cursor.copyWith(option: Option.former);
        return SentenceSelectionCursorMover(lyricSnippetMap: lyricSnippetMap, textPaneCursor: movedCursor, cursorBlinker: cursorBlinker, seekPosition: seekPosition);
      }

      TimingPointIndex rightTimingPointIndex = lyricSnippet.timing.rightTimingPointIndex(highlightSegmentIndex);
      TimingPointIndex timingPointIndex = insertionPositionInfo.timingPointIndex;
      debugPrint("highlightSegmentIndex: $highlightSegmentIndex, timingPointIndex: $timingPointIndex, rightTimingPointIndex: $rightTimingPointIndex");
      if (timingPointIndex == rightTimingPointIndex) {
        nextInsertionPosition = cursor.charPosition - 1;
      } else {
        if (timingPointIndex.index - 1 < 0) {
          return this;
        }
        TimingPoint previousTimingPoint = lyricSnippet.timingPoints[timingPointIndex.index - 1];
        nextInsertionPosition = previousTimingPoint.charPosition;
      }
    }

    InsertionPositionInfo? nextInsertionPositionInfo = lyricSnippet.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");
    if (nextInsertionPositionInfo is SentenceSegmentInsertionPositionInfo) {
      SentenceSelectionCursor movedCursor = cursor.copyWith(charPosition: nextInsertionPosition, option: Option.segment);
      return SentenceSelectionCursorMover(lyricSnippetMap: lyricSnippetMap, textPaneCursor: movedCursor, cursorBlinker: cursorBlinker, seekPosition: seekPosition);
    }
    if (nextInsertionPositionInfo is TimingPointInsertionPositionInfo) {
      Option nextOption = Option.former;
      if (nextInsertionPositionInfo.duplicate) {
        nextOption = Option.latter;
      }
      SentenceSelectionCursor movedCursor = cursor.copyWith(charPosition: nextInsertionPosition, option: nextOption);
      return SentenceSelectionCursorMover(lyricSnippetMap: lyricSnippetMap, textPaneCursor: movedCursor, cursorBlinker: cursorBlinker, seekPosition: seekPosition);
    }

    return this;
  }

  SentenceSelectionCursorMover increaseCursor(SentenceSelectionCursor cursor) {
    SentenceSelectionCursor movedCursor = cursor.copyWith(charPosition: cursor.charPosition + 1);
    return SentenceSelectionCursorMover(lyricSnippetMap: lyricSnippetMap, textPaneCursor: movedCursor, cursorBlinker: cursorBlinker, seekPosition: seekPosition);
  }

  SentenceSelectionCursorMover moveCursorToNextTimingPoint(SentenceSelectionCursor cursor, LyricSnippet lyricSnippet, TimingPointIndex timingPointIndex) {
    InsertionPosition insertionPosition = cursor.charPosition;
    InsertionPositionInfo? insertionPositionInfo = lyricSnippet.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo is TimingPointInsertionPositionInfo, "An unexpected state was occurred.");

    bool duplicated = (insertionPositionInfo as TimingPointInsertionPositionInfo).duplicate;
    if (duplicated && cursor.option == Option.former) {
      SentenceSelectionCursor movedCursor = cursor.copyWith(option: Option.latter);
      return SentenceSelectionCursorMover(lyricSnippetMap: lyricSnippetMap, textPaneCursor: movedCursor, cursorBlinker: cursorBlinker, seekPosition: seekPosition);
    } else {
      InsertionPosition nextInsertionPosition = lyricSnippet.timingPoints[timingPointIndex.index + 1].charPosition;
      SentenceSelectionCursor movedCursor = cursor.copyWith(charPosition: nextInsertionPosition);
      return SentenceSelectionCursorMover(lyricSnippetMap: lyricSnippetMap, textPaneCursor: movedCursor, cursorBlinker: cursorBlinker, seekPosition: seekPosition);
    }
  }

  @override
  TextPaneCursorMover moveRightCursor() {
    SentenceSelectionCursor cursor = textPaneCursor as SentenceSelectionCursor;
    LyricSnippet lyricSnippet = lyricSnippetMap[cursor.lyricSnippetID]!;

    InsertionPositionInfo? insertionPositionInfo = lyricSnippet.getInsertionPositionInfo(cursor.charPosition);

    if (insertionPositionInfo is SentenceSegmentInsertionPositionInfo) {
      TimingPoint leftTimingPoint = lyricSnippet.timing.leftTimingPoint(insertionPositionInfo.sentenceSegmentIndex);
      TimingPoint rightTimingPoint = lyricSnippet.timing.rightTimingPoint(insertionPositionInfo.sentenceSegmentIndex);
      if (leftTimingPoint.charPosition <= cursor.charPosition && cursor.charPosition < rightTimingPoint.charPosition) {
        return increaseCursor(cursor);
      }
    }

    if (insertionPositionInfo is TimingPointInsertionPositionInfo) {
      SentenceSegmentIndex highlightSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
      TimingPointIndex leftTimingPointIndex = lyricSnippet.timing.leftTimingPointIndex(highlightSegmentIndex);
      TimingPointIndex timingPointIndex = insertionPositionInfo.timingPointIndex;

      if (timingPointIndex == leftTimingPointIndex) {
        return increaseCursor(cursor);
      }
      if (timingPointIndex.index + 1 < lyricSnippet.timingPoints.length - 1) {
        return moveCursorToNextTimingPoint(cursor, lyricSnippet, timingPointIndex);
      }
    }

    return this;
  }

  @override
  TextPaneCursorMover updateCursor(
    LyricSnippetMap lyricSnippetMap,
    CursorBlinker cursorBlinker,
    SeekPosition seekPosition,
  ) {
    cursorBlinker.restartCursorTimer();

    if (lyricSnippetMap.isEmpty) {
      return SentenceSelectionCursorMover(
        lyricSnippetMap: lyricSnippetMap,
        textPaneCursor: SentenceSelectionCursor.empty,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
    }

    LyricSnippetID lyricSnippetID = lyricSnippetMap.keys.first;
    LyricSnippet lyricSnippet = lyricSnippetMap.values.first;
    if (lyricSnippetMap.containsKey(lyricSnippetID)) {
      lyricSnippet = lyricSnippetMap[lyricSnippetID]!;
    }

    SentenceSegmentIndex currentSeekSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPositionInfo? nextSnippetPositionInfo = lyricSnippet.getInsertionPositionInfo((textPaneCursor as SentenceSelectionCursor).charPosition);

    if (nextSnippetPositionInfo == null || nextSnippetPositionInfo is SentenceSegmentInsertionPositionInfo && nextSnippetPositionInfo.sentenceSegmentIndex != currentSeekSegmentIndex) {
      return SentenceSelectionCursorMover.withDefaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: lyricSnippetID,
        cursorBlinker: cursorBlinker,
        seekPosition: seekPosition,
      );
    }

    return SentenceSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: textPaneCursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
    );
  }

  TextPaneCursorMover enterSegmentSelectionMode() {
    SegmentSelectionCursor cursor = SegmentSelectionCursor(
      textPaneCursor.lyricSnippetID,
      cursorBlinker,
      SegmentRange(SentenceSegmentIndex(0), SentenceSegmentIndex(0)),
    );
    return SegmentSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap,
      textPaneCursor: cursor,
      cursorBlinker: cursorBlinker,
      seekPosition: seekPosition,
      isRangeSelection: false,
    );
  }

  SentenceSelectionCursorMover copyWith({
    LyricSnippetMap? lyricSnippetMap,
    SentenceSelectionCursor? sentenceSelectionCursor,
    CursorBlinker? cursorBlinker,
    SeekPosition? seekPosition,
  }) {
    return SentenceSelectionCursorMover(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      textPaneCursor: sentenceSelectionCursor ?? textPaneCursor,
      cursorBlinker: cursorBlinker ?? this.cursorBlinker,
      seekPosition: seekPosition ?? this.seekPosition,
    );
  }

  @override
  String toString() {
    return 'SentenceSelectionCursorMover($lyricSnippetMap, $textPaneCursor, $cursorBlinker, $seekPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSelectionCursorMover otherSentenceSelectionCursorMover = other as SentenceSelectionCursorMover;
    if (lyricSnippetMap != otherSentenceSelectionCursorMover.lyricSnippetMap) return false;
    if (textPaneCursor != otherSentenceSelectionCursorMover.textPaneCursor) return false;
    if (cursorBlinker != otherSentenceSelectionCursorMover.cursorBlinker) return false;
    if (seekPosition != otherSentenceSelectionCursorMover.seekPosition) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ textPaneCursor.hashCode ^ cursorBlinker.hashCode ^ seekPosition.hashCode;
}
