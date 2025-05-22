import 'package:lyric_editor/lyric_data/reading/reading.dart';
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
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class ReadingSelectionCursor extends TextPaneCursor {
  PhrasePosition phrase;
  InsertionPosition insertionPosition;
  Option option;

  ReadingSelectionCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.phrase,
    required this.insertionPosition,
    required this.option,
  }) : super(sentence, seekPosition) {
    assert(doesSeekPositionPointReading(), "The passed seek position does not point to any reading.");
  }

  bool doesSeekPositionPointReading() {
    PhrasePosition readingPhrase = sentence.getPhraseFromSeekPosition(seekPosition);
    return readingPhrase.isNotEmpty;
  }

  ReadingSelectionCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.phrase,
    this.insertionPosition,
    this.option,
  );
  static final ReadingSelectionCursor _empty = ReadingSelectionCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    PhrasePosition.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static ReadingSelectionCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory ReadingSelectionCursor.defaultCursor({
    required Sentence lyricSnippet,
    required SeekPosition seekPosition,
  }) {
    PhrasePosition readingPhrase = lyricSnippet.getPhraseFromSeekPosition(seekPosition);
    Reading reading = lyricSnippet.readingMap[readingPhrase]!;
    WordIndex segmentIndex = reading.getSegmentIndexFromSeekPosition(seekPosition);

    return ReadingSelectionCursor(
      sentence: lyricSnippet,
      seekPosition: seekPosition,
      phrase: readingPhrase,
      insertionPosition: reading.timeline.leftTiming(segmentIndex).insertionPosition + 1,
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
  List<TextPaneCursor?> getPhraseDividedCursors(Sentence lyricSnippet, List<PhrasePosition> rangeList) {
    List<ReadingSelectionCursor?> separatedCursors = List.filled(rangeList.length, null);
    ReadingSelectionCursor cursor = copyWith();
    for (int index = 0; index < rangeList.length; index++) {
      PhrasePosition segmentRange = rangeList[index];
      if (segmentRange == cursor.phrase) {
        separatedCursors[index] = cursor;
        break;
      }
    }
    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getWordDividedCursors(WordList sentenceSegmentList) {
    List<ReadingSelectionCursor?> separatedCursors = List.filled(sentenceSegmentList.length, null);
    return separatedCursors;
  }

  @override
  ReadingSelectionCursor? shiftLeftBySentenceSegmentList(WordList sentenceSegmentList) {
    return this;
  }

  @override
  ReadingSelectionCursor? shiftLeftBySentenceSegment(Word sentenceSegment) {
    return this;
  }

  ReadingSelectionCursor copyWith({
    Sentence? sentence,
    SeekPosition? seekPosition,
    PhrasePosition? phrase,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return ReadingSelectionCursor(
      sentence: sentence ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      phrase: phrase ?? this.phrase,
      insertionPosition: insertionPosition ?? this.insertionPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'ReadingSelectionCursor($sentence, phrase: $phrase, position: ${insertionPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final ReadingSelectionCursor otherSentenceSegments = other as ReadingSelectionCursor;
    if (sentence != otherSentenceSegments.sentence) return false;
    if (seekPosition != otherSentenceSegments.seekPosition) return false;
    if (phrase != otherSentenceSegments.phrase) return false;
    if (insertionPosition != otherSentenceSegments.insertionPosition) return false;
    if (option != otherSentenceSegments.option) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ phrase.hashCode ^ insertionPosition.hashCode ^ option.hashCode;
}
