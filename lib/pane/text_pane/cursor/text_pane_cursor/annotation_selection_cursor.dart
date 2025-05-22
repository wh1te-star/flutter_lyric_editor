import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/sentence/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class AnnotationSelectionCursor extends TextPaneCursor {
  Phrase segmentRange;
  InsertionPosition insertionPosition;
  Option option;

  AnnotationSelectionCursor({
    required Sentence lyricSnippet,
    required SeekPosition seekPosition,
    required this.segmentRange,
    required this.insertionPosition,
    required this.option,
  }) : super(lyricSnippet, seekPosition) {
    assert(doesSeekPositionPointAnnotation(), "The passed seek position does not point to any annotation.");
  }

  bool doesSeekPositionPointAnnotation() {
    Phrase annotationSegmentRange = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    return annotationSegmentRange.isNotEmpty;
  }

  AnnotationSelectionCursor._privateConstructor(
    super.lyricSnippet,
    super.seekPosition,
    this.segmentRange,
    this.insertionPosition,
    this.option,
  );
  static final AnnotationSelectionCursor _empty = AnnotationSelectionCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    Phrase.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static AnnotationSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory AnnotationSelectionCursor.defaultCursor({
    required Sentence lyricSnippet,
    required SeekPosition seekPosition,
  }) {
    Phrase annotationSegmentRange = lyricSnippet.getAnnotationRangeFromSeekPosition(seekPosition);
    Reading annotation = lyricSnippet.readingMap[annotationSegmentRange]!;
    WordIndex segmentIndex = annotation.getSegmentIndexFromSeekPosition(seekPosition);

    return AnnotationSelectionCursor(
      lyricSnippet: lyricSnippet,
      seekPosition: seekPosition,
      segmentRange: annotationSegmentRange,
      insertionPosition: annotation.timeline.leftTiming(segmentIndex).insertionPosition + 1,
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
  List<TextPaneCursor?> getRangeDividedCursors(Sentence lyricSnippet, List<Phrase> rangeList) {
    List<AnnotationSelectionCursor?> separatedCursors = List.filled(rangeList.length, null);
    AnnotationSelectionCursor cursor = copyWith();
    for (int index = 0; index < rangeList.length; index++) {
      Phrase segmentRange = rangeList[index];
      if (segmentRange == cursor.segmentRange) {
        separatedCursors[index] = cursor;
        break;
      }
    }
    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getSegmentDividedCursors(WordList sentenceSegmentList) {
    List<AnnotationSelectionCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    return separatedCursors;
  }

  @override
  AnnotationSelectionCursor? shiftLeftBySentenceSegmentList(WordList sentenceSegmentList) {
    return this;
  }

  @override
  AnnotationSelectionCursor? shiftLeftBySentenceSegment(Word sentenceSegment) {
    return this;
  }

  AnnotationSelectionCursor copyWith({
    Sentence? lyricSnippet,
    SeekPosition? seekPosition,
    Phrase? segmentRange,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return AnnotationSelectionCursor(
      lyricSnippet: lyricSnippet ?? this.lyricSnippet,
      seekPosition: seekPosition ?? this.seekPosition,
      segmentRange: segmentRange ?? this.segmentRange,
      insertionPosition: insertionPosition ?? this.insertionPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'AnnotationSelectionCursor($lyricSnippet, segmentRange: $segmentRange, position: ${insertionPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final AnnotationSelectionCursor otherSentenceSegments = other as AnnotationSelectionCursor;
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
