import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
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
    super.lyricSnippetMap,
    super.lyricSnippetID,
    this.charPosition,
    this.option,
  );

  SentenceSelectionCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    this.charPosition,
    this.option,
  );
  static final SentenceSelectionCursor _empty = SentenceSelectionCursor._privateConstructor(
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static SentenceSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  SentenceSelectionCursor defaultCursor(LyricSnippetID lyricSnippetID) {
    if (lyricSnippetMap.isEmpty) {
      return SentenceSelectionCursor(LyricSnippetMap.empty, LyricSnippetID.empty, InsertionPosition.empty, Option.former);
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
      if (timingPointIndex == rightTimingPointIndex) {
        nextInsertionPosition = cursor.charPosition - 1;
      } else {
        if (timingPointIndex.index - 1 <= 0) {
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

  @override
  TextPaneCursorMover moveRightCursor() {
    SentenceSelectionCursor cursor = textPaneCursor as SentenceSelectionCursor;
    LyricSnippet lyricSnippet = lyricSnippetMap[cursor.lyricSnippetID]!;

    InsertionPosition insertionPosition = cursor.charPosition;
    InsertionPositionInfo? insertionPositionInfo = lyricSnippet.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");

    SentenceSegmentIndex highlightSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition nextInsertionPosition = InsertionPosition.empty;
    if (insertionPositionInfo is SentenceSegmentInsertionPositionInfo) {
      SentenceSegmentIndex segmentIndex = insertionPositionInfo.sentenceSegmentIndex;
      assert(segmentIndex == highlightSegmentIndex, "An unexpected state was occurred.");
      nextInsertionPosition = insertionPosition + 1;
      if (nextInsertionPosition >= InsertionPosition(lyricSnippet.sentence.length)) {
        return this;
      }
    }

    if (insertionPositionInfo is TimingPointInsertionPositionInfo) {
      if (insertionPositionInfo.duplicate && cursor.option == Option.former) {
        SentenceSelectionCursor movedCursor = cursor.copyWith(option: Option.latter);
        return SentenceSelectionCursorMover(lyricSnippetMap: lyricSnippetMap, textPaneCursor: movedCursor, cursorBlinker: cursorBlinker, seekPosition: seekPosition);
      }

      TimingPointIndex leftTimingPointIndex = lyricSnippet.timing.leftTimingPointIndex(highlightSegmentIndex);
      TimingPointIndex timingPointIndex = insertionPositionInfo.timingPointIndex;
      if (insertionPositionInfo.duplicate) timingPointIndex = timingPointIndex + 1;
      if (timingPointIndex == leftTimingPointIndex) {
        nextInsertionPosition = cursor.charPosition + 1;
      } else {
        TimingPointIndex nextTimingPointIndex = timingPointIndex + 1;
        if (nextTimingPointIndex.index >= lyricSnippet.timingPoints.length - 1) {
          return this;
        }
        TimingPoint nextTimingPoint = lyricSnippet.timingPoints[nextTimingPointIndex.index];
        nextInsertionPosition = nextTimingPoint.charPosition;
      }
    }

    InsertionPositionInfo? nextInsertionPositionInfo = lyricSnippet.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");
    if (nextInsertionPositionInfo is SentenceSegmentInsertionPositionInfo) {
      SentenceSelectionCursor movedCursor = cursor.copyWith(charPosition: nextInsertionPosition, option: Option.segment);
      return SentenceSelectionCursorMover(lyricSnippetMap: lyricSnippetMap, textPaneCursor: movedCursor, cursorBlinker: cursorBlinker, seekPosition: seekPosition);
    }
    if (nextInsertionPositionInfo is TimingPointInsertionPositionInfo) {
      SentenceSelectionCursor movedCursor = cursor.copyWith(charPosition: nextInsertionPosition, option: Option.former);
      return SentenceSelectionCursorMover(lyricSnippetMap: lyricSnippetMap, textPaneCursor: movedCursor, cursorBlinker: cursorBlinker, seekPosition: seekPosition);
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

    LyricSnippetID lyricSnippetID = textPaneCursor.lyricSnippetID;
    if (!lyricSnippetMap.containsKey(lyricSnippetID)) {
      lyricSnippetID = lyricSnippetMap.keys.first;
    }
    LyricSnippet lyricSnippet = lyricSnippetMap[lyricSnippetID]!;
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
    if (charPosition != otherSentenceSegments.charPosition) return false;
    if (option != otherSentenceSegments.option) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetID.hashCode ^ charPosition.hashCode ^ option.hashCode;
}
