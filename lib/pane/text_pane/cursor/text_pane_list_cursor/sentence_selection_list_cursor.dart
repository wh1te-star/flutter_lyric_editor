import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet_map.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/annotation_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_list_cursor/text_pane_list_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_point_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/position/timing_point_index.dart';
import 'package:lyric_editor/service/timing_service.dart';

class SentenceSelectionListCursor extends TextPaneListCursor {
  InsertionPosition charPosition;
  Option option;

  SentenceSelectionCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
    required this.charPosition,
    required this.option,
  }) : super(lyricSnippetMap, lyricSnippetID, seekPosition) {
    assert(isIDContained(), "The passed lyricSnippetID does not point to a lyric snippet in lyricSnippetMap.");
  }

  bool isIDContained() {
    if (lyricSnippetMap.isEmpty) {
      return true;
    }
    LyricSnippet? lyricSnippet = lyricSnippetMap[lyricSnippetID];
    if (lyricSnippet == null) {
      return false;
    }
    return true;
  }

  SentenceSelectionCursor._privateConstructor(
    super.lyricSnippetMap,
    super.lyricSnippetID,
    super.seekPosition,
    this.charPosition,
    this.option,
  );
  static final SentenceSelectionCursor _empty = SentenceSelectionCursor._privateConstructor(
    LyricSnippetMap.empty,
    LyricSnippetID.empty,
    SeekPosition.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static SentenceSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory SentenceSelectionCursor.defaultCursor({
    required LyricSnippetMap lyricSnippetMap,
    required LyricSnippetID lyricSnippetID,
    required SeekPosition seekPosition,
  }) {
    if (lyricSnippetMap.isEmpty) {
      return SentenceSelectionCursor(
        lyricSnippetMap: LyricSnippetMap.empty,
        lyricSnippetID: LyricSnippetID.empty,
        seekPosition: SeekPosition.empty,
        charPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }
    LyricSnippet lyricSnippet = lyricSnippetMap.getLyricSnippetByID(lyricSnippetID);
    SentenceSegmentIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition charPosition = lyricSnippet.timing.leftTimingPoint(segmentIndex).charPosition + 1;
    return SentenceSelectionCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      charPosition: charPosition,
      option: Option.former,
    );
  }

  @override
  TextPaneCursor moveUpCursor() {
    LyricSnippet lyricSnippet = lyricSnippetMap[lyricSnippetID]!;
    SegmentRange annotationIndex = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    if (annotationIndex.isNotEmpty) {
      return AnnotationSelectionCursor.defaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: lyricSnippetID,
        seekPosition: seekPosition,
      );
    }

    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index <= 0) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index - 1];
    return SentenceSelectionCursor.defaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneCursor moveDownCursor() {
    int index = lyricSnippetMap.keys.toList().indexWhere((LyricSnippetID id) {
      return id == lyricSnippetID;
    });
    if (index >= lyricSnippetMap.length) {
      return this;
    }

    LyricSnippetID nextLyricSnippetID = lyricSnippetMap.keys.toList()[index + 1];
    LyricSnippet nextLyricSnippet = lyricSnippetMap[nextLyricSnippetID]!;

    SegmentRange annotationIndex = nextLyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    if (annotationIndex.isNotEmpty) {
      return AnnotationSelectionCursor.defaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: lyricSnippetID,
        seekPosition: seekPosition,
      );
    }

    return SentenceSelectionCursor.defaultCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: nextLyricSnippetID,
      seekPosition: seekPosition,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    LyricSnippet lyricSnippet = lyricSnippetMap[lyricSnippetID]!;

    InsertionPosition insertionPosition = charPosition;
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
      if (option == Option.latter) {
        return copyWith(option: Option.former);
      }

      TimingPointIndex rightTimingPointIndex = lyricSnippet.timing.rightTimingPointIndex(highlightSegmentIndex);
      TimingPointIndex timingPointIndex = insertionPositionInfo.timingPointIndex;
      if (timingPointIndex == rightTimingPointIndex) {
        nextInsertionPosition = charPosition - 1;
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
      return copyWith(charPosition: nextInsertionPosition, option: Option.segment);
    }
    if (nextInsertionPositionInfo is TimingPointInsertionPositionInfo) {
      Option nextOption = Option.former;
      if (nextInsertionPositionInfo.duplicate) {
        nextOption = Option.latter;
      }
      return copyWith(charPosition: nextInsertionPosition, option: nextOption);
    }

    return this;
  }

  @override
  TextPaneCursor moveRightCursor() {
    LyricSnippet lyricSnippet = lyricSnippetMap[lyricSnippetID]!;

    InsertionPosition insertionPosition = charPosition;
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
      if (insertionPositionInfo.duplicate && option == Option.former) {
        return copyWith(option: Option.latter);
      }

      TimingPointIndex leftTimingPointIndex = lyricSnippet.timing.leftTimingPointIndex(highlightSegmentIndex);
      TimingPointIndex timingPointIndex = insertionPositionInfo.timingPointIndex;
      if (insertionPositionInfo.duplicate) timingPointIndex = timingPointIndex + 1;
      if (timingPointIndex == leftTimingPointIndex) {
        nextInsertionPosition = charPosition + 1;
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
      return copyWith(charPosition: nextInsertionPosition, option: Option.segment);
    }
    if (nextInsertionPositionInfo is TimingPointInsertionPositionInfo) {
      return copyWith(charPosition: nextInsertionPosition, option: Option.former);
    }

    return this;
  }

  @override
  TextPaneCursor updateCursor(
    LyricSnippetMap lyricSnippetMap,
    LyricSnippetID lyricSnippetID,
    SeekPosition seekPosition,
  ) {
    if (lyricSnippetMap.isEmpty) {
      return SentenceSelectionCursor(
        lyricSnippetMap: LyricSnippetMap.empty,
        lyricSnippetID: LyricSnippetID.empty,
        seekPosition: seekPosition,
        charPosition: InsertionPosition.empty,
        option: Option.former,
      );
    }

    if (!lyricSnippetMap.containsKey(lyricSnippetID)) {
      lyricSnippetID = lyricSnippetMap.keys.first;
    }
    LyricSnippet lyricSnippet = lyricSnippetMap[lyricSnippetID]!;
    SentenceSegmentIndex currentSeekSegmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPositionInfo? nextSnippetPositionInfo = lyricSnippet.getInsertionPositionInfo(charPosition);
    if (nextSnippetPositionInfo == null || nextSnippetPositionInfo is SentenceSegmentInsertionPositionInfo && nextSnippetPositionInfo.sentenceSegmentIndex != currentSeekSegmentIndex) {
      return SentenceSelectionCursor.defaultCursor(
        lyricSnippetMap: lyricSnippetMap,
        lyricSnippetID: lyricSnippetID,
        seekPosition: seekPosition,
      );
    }

    return SentenceSelectionCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      charPosition: charPosition,
      option: option,
    );
  }

  TextPaneCursor enterSegmentSelectionMode() {
    return SegmentSelectionCursor(
      lyricSnippetMap: lyricSnippetMap,
      lyricSnippetID: lyricSnippetID,
      seekPosition: seekPosition,
      segmentRange: SegmentRange(SentenceSegmentIndex(0), SentenceSegmentIndex(0)),
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
    LyricSnippetMap? lyricSnippetMap,
    LyricSnippetID? lyricSnippetID,
    SeekPosition? seekPosition,
    InsertionPosition? charPosition,
    Option? option,
  }) {
    return SentenceSelectionCursor(
      lyricSnippetMap: lyricSnippetMap ?? this.lyricSnippetMap,
      lyricSnippetID: lyricSnippetID ?? this.lyricSnippetID,
      seekPosition: seekPosition ?? this.seekPosition,
      charPosition: charPosition ?? this.charPosition,
      option: option ?? this.option,
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
    if (lyricSnippetMap != otherSentenceSegments.lyricSnippetMap) return false;
    if (lyricSnippetID != otherSentenceSegments.lyricSnippetID) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (charPosition != otherSentenceSegments.charPosition) return false;
    if (option != otherSentenceSegments.option) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippetMap.hashCode ^ lyricSnippetID.hashCode ^ seekPosition.hashCode ^ charPosition.hashCode ^ option.hashCode;
}
