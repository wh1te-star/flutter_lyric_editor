import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/word_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class RubyCursor extends TextPaneCursor {
  SegmentRange segmentRange;
  InsertionPosition insertionPosition;
  Option option;

  RubyCursor({
    required LyricSnippet lyricSnippet,
    required SeekPosition seekPosition,
    required this.segmentRange,
    required this.insertionPosition,
    required this.option,
  }) : super(lyricSnippet, seekPosition) {
    assert(doesSeekPositionPointAnnotation(), "The passed seek position does not point to any annotation.");
  }

  bool doesSeekPositionPointAnnotation() {
    SegmentRange annotationSegmentRange = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    return annotationSegmentRange.isNotEmpty;
  }

  RubyCursor._privateConstructor(
    super.lyricSnippet,
    super.seekPosition,
    this.segmentRange,
    this.insertionPosition,
    this.option,
  );
  static final RubyCursor _empty = RubyCursor._privateConstructor(
    LyricSnippet.empty,
    SeekPosition.empty,
    SegmentRange.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static RubyCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory RubyCursor.defaultCursor({
    required LyricSnippet lyricSnippet,
    required SeekPosition seekPosition,
  }) {
    SegmentRange annotationSegmentRange = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    Annotation annotation = lyricSnippet.annotationMap[annotationSegmentRange]!;
    SentenceSegmentIndex segmentIndex = annotation.getSegmentIndexFromSeekPosition(seekPosition);

    return RubyCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: annotationSegmentRange,
      insertionPosition: annotation.timing.leftTimingPoint(segmentIndex).insertionPosition + 1,
      option: Option.former,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    return this;
  }

  @override
  TextPaneCursor moveRightCursor() {
    return this;
  }

  @override
  List<TextPaneCursor?> getRangeDividedCursors(LyricSnippet lyricSnippet, List<SegmentRange> rangeList) {
    List<RubyCursor?> separatedCursors = List.filled(rangeList.length, null);
    RubyCursor cursor = copyWith();
    for (int index = 0; index < rangeList.length; index++) {
      SegmentRange segmentRange = rangeList[index];
      if (segmentRange == cursor.segmentRange) {
        separatedCursors[index] = cursor;
        break;
      }
    }
    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getSegmentDividedCursors(SentenceSegmentList sentenceSegmentList) {
    List<RubyCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    return separatedCursors;
  }

  @override
  RubyCursor? shiftLeftBySentenceSegmentList(SentenceSegmentList sentenceSegmentList) {
    return this;
  }

  @override
  RubyCursor? shiftLeftBySentenceSegment(SentenceSegment sentenceSegment) {
    return this;
  }

  RubyCursor copyWith({
    LyricSnippet? lyricSnippet,
    SeekPosition? seekPosition,
    SegmentRange? segmentRange,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return RubyCursor(
      lyricSnippet: lyricSnippet ?? this.lyricSnippet,
      seekPosition: seekPosition ?? this.seekPosition,
      segmentRange: segmentRange ?? this.segmentRange,
      insertionPosition: insertionPosition ?? this.insertionPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'RubyCursor($lyricSnippet, segmentRange: $segmentRange, position: ${insertionPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final RubyCursor otherSentenceSegments = other as RubyCursor;
    if (lyricSnippet != otherSentenceSegments.lyricSnippet) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (segmentRange != otherSentenceSegments.segmentRange) return false;
    if (insertionPosition != otherSentenceSegments.insertionPosition) return false;
    if (option != otherSentenceSegments.option) return false;
    return true;
  }

  @override
  int get hashCode => lyricSnippet.hashCode ^ seekPosition.hashCode ^ segmentRange.hashCode ^ insertionPosition.hashCode ^ option.hashCode;
}
