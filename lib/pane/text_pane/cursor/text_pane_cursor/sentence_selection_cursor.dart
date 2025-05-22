import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_point_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/position/timing_point_index.dart';
import 'package:lyric_editor/service/timing_service.dart';

class SentenceSelectionCursor extends TextPaneCursor {
  InsertionPosition insertionPosition;
  Option option;

  SentenceSelectionCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.insertionPosition,
    required this.option,
  }) : super(sentence, seekPosition);

  SentenceSelectionCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.insertionPosition,
    this.option,
  );
  static final SentenceSelectionCursor _empty = SentenceSelectionCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static SentenceSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory SentenceSelectionCursor.defaultCursor({
    required Sentence lyricSnippet,
    required SeekPosition seekPosition,
  }) {
    WordIndex segmentIndex = lyricSnippet.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition insertionPosition = lyricSnippet.timeline.leftTiming(segmentIndex).insertionPosition + 1;
    return SentenceSelectionCursor(
      sentence: lyricSnippet,
      seekPosition: seekPosition,
      insertionPosition: insertionPosition,
      option: Option.former,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    InsertionPositionInfo? insertionPositionInfo = sentence.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");

    WordIndex highlightSegmentIndex = sentence.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition nextInsertionPosition = InsertionPosition.empty;
    if (insertionPositionInfo is SentenceSegmentInsertionPositionInfo) {
      WordIndex segmentIndex = insertionPositionInfo.sentenceSegmentIndex;
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

      TimingIndex rightTimingPointIndex = sentence.timeline.rightTimingIndex(highlightSegmentIndex);
      TimingIndex timingPointIndex = insertionPositionInfo.timingPointIndex;
      if (timingPointIndex == rightTimingPointIndex) {
        nextInsertionPosition = insertionPosition - 1;
      } else {
        if (timingPointIndex.index - 1 <= 0) {
          return this;
        }
        Timing previousTimingPoint = sentence.timingPoints[timingPointIndex.index - 1];
        nextInsertionPosition = previousTimingPoint.insertionPosition;
      }
    }

    InsertionPositionInfo? nextInsertionPositionInfo = sentence.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");
    if (nextInsertionPositionInfo is SentenceSegmentInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.segment);
    }
    if (nextInsertionPositionInfo is TimingPointInsertionPositionInfo) {
      Option nextOption = Option.former;
      if (nextInsertionPositionInfo.duplicate) {
        nextOption = Option.latter;
      }
      return copyWith(insertionPosition: nextInsertionPosition, option: nextOption);
    }

    return this;
  }

  @override
  TextPaneCursor moveRightCursor() {
    InsertionPositionInfo? insertionPositionInfo = sentence.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");

    WordIndex highlightSegmentIndex = sentence.getSegmentIndexFromSeekPosition(seekPosition);
    InsertionPosition nextInsertionPosition = InsertionPosition.empty;
    if (insertionPositionInfo is SentenceSegmentInsertionPositionInfo) {
      WordIndex segmentIndex = insertionPositionInfo.sentenceSegmentIndex;
      assert(segmentIndex == highlightSegmentIndex, "An unexpected state was occurred.");
      nextInsertionPosition = insertionPosition + 1;
      if (nextInsertionPosition >= InsertionPosition(sentence.sentence.length)) {
        return this;
      }
    }

    if (insertionPositionInfo is TimingPointInsertionPositionInfo) {
      if (insertionPositionInfo.duplicate && option == Option.former) {
        return copyWith(option: Option.latter);
      }

      TimingIndex leftTimingPointIndex = sentence.timeline.leftTimingIndex(highlightSegmentIndex);
      TimingIndex timingPointIndex = insertionPositionInfo.timingPointIndex;
      if (insertionPositionInfo.duplicate) timingPointIndex = timingPointIndex + 1;
      if (timingPointIndex == leftTimingPointIndex) {
        nextInsertionPosition = insertionPosition + 1;
      } else {
        TimingIndex nextTimingPointIndex = timingPointIndex + 1;
        if (nextTimingPointIndex.index >= sentence.timingPoints.length - 1) {
          return this;
        }
        Timing nextTimingPoint = sentence.timingPoints[nextTimingPointIndex.index];
        nextInsertionPosition = nextTimingPoint.insertionPosition;
      }
    }

    InsertionPositionInfo? nextInsertionPositionInfo = sentence.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");
    if (nextInsertionPositionInfo is SentenceSegmentInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.segment);
    }
    if (nextInsertionPositionInfo is TimingPointInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.former);
    }

    return this;
  }

  TextPaneCursor enterSegmentSelectionMode() {
    return SegmentSelectionCursor(
      lyricSnippet: sentence,
      seekPosition: seekPosition,
      segmentRange: PhrasePosition(WordIndex(0), WordIndex(0)),
      isRangeSelection: false,
    );
  }

  @override
  List<TextPaneCursor?> getPhraseDividedCursors(Sentence lyricSnippet, List<PhrasePosition> rangeList) {
    List<SentenceSelectionCursor?> separatedCursors = List.filled(rangeList.length, null);
    SentenceSelectionCursor shiftedCursor = copyWith();
    for (int index = 0; index < rangeList.length; index++) {
      PhrasePosition segmentRange = rangeList[index];
      WordList? sentenceSubList = lyricSnippet.getSentenceSegmentList(segmentRange);
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
  List<TextPaneCursor?> getWordDividedCursors(WordList sentenceSegmentList) {
    List<SentenceSelectionCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    SentenceSelectionCursor shiftedCursor = copyWith();
    for (int index = 0; index < sentenceSegmentList.length; index++) {
      Word sentenceSegment = sentenceSegmentList[index];
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
  SentenceSelectionCursor? shiftLeftBySentenceSegmentList(WordList sentenceSegmentList) {
    if (insertionPosition.position - sentenceSegmentList.charLength < 0) {
      return null;
    }
    InsertionPosition newInsertionPosition = insertionPosition - sentenceSegmentList.charLength;
    return copyWith(insertionPosition: newInsertionPosition);
  }

  @override
  SentenceSelectionCursor? shiftLeftBySentenceSegment(Word sentenceSegment) {
    if (insertionPosition.position - sentenceSegment.word.length < 0) {
      return null;
    }
    InsertionPosition newInsertionPosition = insertionPosition - sentenceSegment.word.length;
    return copyWith(insertionPosition: newInsertionPosition);
  }

  SentenceSelectionCursor copyWith({
    Sentence? lyricSnippet,
    SeekPosition? seekPosition,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return SentenceSelectionCursor(
      sentence: lyricSnippet ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      insertionPosition: insertionPosition ?? this.insertionPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'SentenceSelectionCursor(position: ${insertionPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSelectionCursor otherSentenceSegments = other as SentenceSelectionCursor;
    if (sentence != otherSentenceSegments.sentence) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (insertionPosition != otherSentenceSegments.insertionPosition) return false;
    if (option != otherSentenceSegments.option) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ insertionPosition.hashCode ^ option.hashCode;
}
