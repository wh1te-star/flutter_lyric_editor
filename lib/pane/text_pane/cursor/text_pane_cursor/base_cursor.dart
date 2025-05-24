import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/invalid_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/word_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_insertion_position_info.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/service/timing_service.dart';

class BaseCursor extends TextPaneCursor {
  InsertionPosition insertionPosition;
  Option option;

  BaseCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.insertionPosition,
    required this.option,
  }) : super(sentence, seekPosition);

  BaseCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.insertionPosition,
    this.option,
  );
  static final BaseCursor _empty = BaseCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static BaseCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory BaseCursor.defaultCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
  }) {
    WordIndex wordIndex = sentence.getWordIndexFromSeekPosition(seekPosition);
    InsertionPosition insertionPosition = sentence.timetable.leftTiming(wordIndex).insertionPosition + 1;
    return BaseCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      insertionPosition: insertionPosition,
      option: Option.former,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    InsertionPositionInfo insertionPositionInfo = sentence.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo is! InvalidInsertionPositionInfo, "An unexpected state was occurred for the insertion position info.");

    WordIndex highlightWordIndex = sentence.getWordIndexFromSeekPosition(seekPosition);
    InsertionPosition nextInsertionPosition = InsertionPosition.empty;
    if (insertionPositionInfo is WordInsertionPositionInfo) {
      WordIndex wordIndex = insertionPositionInfo.wordIndex;
      assert(wordIndex == highlightWordIndex, "An unexpected state was occurred.");
      nextInsertionPosition = insertionPosition - 1;
      if (nextInsertionPosition <= InsertionPosition(0)) {
        return this;
      }
    }

    if (insertionPositionInfo is TimingInsertionPositionInfo) {
      if (option == Option.latter) {
        return copyWith(option: Option.former);
      }

      TimingIndex rightTimingIndex = sentence.timetable.rightTimingIndex(highlightWordIndex);
      TimingIndex timingIndex = insertionPositionInfo.timingIndex;
      if (timingIndex == rightTimingIndex) {
        nextInsertionPosition = insertionPosition - 1;
      } else {
        if (timingIndex.index - 1 <= 0) {
          return this;
        }
        Timing previousTiming = sentence.timings[timingIndex.index - 1];
        nextInsertionPosition = previousTiming.insertionPosition;
      }
    }

    InsertionPositionInfo nextInsertionPositionInfo = sentence.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo is! InvalidInsertionPositionInfo, "An unexpected state was occurred for the insertion position info.");
    if (nextInsertionPositionInfo is WordInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.none);
    }
    if (nextInsertionPositionInfo is TimingInsertionPositionInfo) {
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
    InsertionPositionInfo insertionPositionInfo = sentence.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo is! InvalidInsertionPositionInfo, "An unexpected state was occurred for the insertion position info.");

    WordIndex highlightWordIndex = sentence.getWordIndexFromSeekPosition(seekPosition);
    InsertionPosition nextInsertionPosition = InsertionPosition.empty;
    if (insertionPositionInfo is WordInsertionPositionInfo) {
      WordIndex wordIndex = insertionPositionInfo.wordIndex;
      assert(wordIndex == highlightWordIndex, "An unexpected state was occurred.");
      nextInsertionPosition = insertionPosition + 1;
      if (nextInsertionPosition >= InsertionPosition(sentence.sentence.length)) {
        return this;
      }
    }

    if (insertionPositionInfo is TimingInsertionPositionInfo) {
      if (insertionPositionInfo.duplicate && option == Option.former) {
        return copyWith(option: Option.latter);
      }

      TimingIndex leftTimingIndex = sentence.timetable.leftTimingIndex(highlightWordIndex);
      TimingIndex timingIndex = insertionPositionInfo.timingIndex;
      if (insertionPositionInfo.duplicate) timingIndex = timingIndex + 1;
      if (timingIndex == leftTimingIndex) {
        nextInsertionPosition = insertionPosition + 1;
      } else {
        TimingIndex nextTimingIndex = timingIndex + 1;
        if (nextTimingIndex.index >= sentence.timings.length - 1) {
          return this;
        }
        Timing nextTiming = sentence.timings[nextTimingIndex.index];
        nextInsertionPosition = nextTiming.insertionPosition;
      }
    }

    InsertionPositionInfo nextInsertionPositionInfo = sentence.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo is! InvalidInsertionPositionInfo, "An unexpected state was occurred for the insertion position info.");
    if (nextInsertionPositionInfo is WordInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.none);
    }
    if (nextInsertionPositionInfo is TimingInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.former);
    }

    return this;
  }

  TextPaneCursor enterWordMode() {
    return WordCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      wordRange: WordRange(WordIndex(0), WordIndex(0)),
      isExpandMode: false,
    );
  }

  @override
  List<TextPaneCursor?> getWordRangeDividedCursors(Sentence sentence, List<WordRange> wordRangeList) {
    List<BaseCursor?> separatedCursors = List.filled(wordRangeList.length, null);
    BaseCursor shiftedCursor = copyWith();
    for (int index = 0; index < wordRangeList.length; index++) {
      WordRange wordRange = wordRangeList[index];
      WordList? sentenceSubList = sentence.getWordList(wordRange);
      BaseCursor? nextCursor = shiftedCursor.shiftLeftByWordList(sentenceSubList);
      if (nextCursor == null) {
        separatedCursors[index] = shiftedCursor;
        break;
      }
      shiftedCursor = nextCursor;
    }
    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getWordDividedCursors(WordList wordList) {
    List<BaseCursor?> separatedCursors = List.filled(wordList.length, null);
    BaseCursor shiftedCursor = copyWith();
    for (int index = 0; index < wordList.length; index++) {
      Word word = wordList[index];
      BaseCursor? nextCursor = shiftedCursor.shiftLeftByWord(word);
      if (nextCursor == null) {
        separatedCursors[index] = shiftedCursor;
        break;
      }
      shiftedCursor = nextCursor;
    }
    return separatedCursors;
  }

  @override
  BaseCursor? shiftLeftByWordList(WordList wordList) {
    if (insertionPosition.position - wordList.charCount < 0) {
      return null;
    }
    InsertionPosition newInsertionPosition = insertionPosition - wordList.charCount;
    return copyWith(insertionPosition: newInsertionPosition);
  }

  @override
  BaseCursor? shiftLeftByWord(Word word) {
    if (insertionPosition.position - word.word.length < 0) {
      return null;
    }
    InsertionPosition newInsertionPosition = insertionPosition - word.word.length;
    return copyWith(insertionPosition: newInsertionPosition);
  }

  BaseCursor copyWith({
    Sentence? sentence,
    SeekPosition? seekPosition,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return BaseCursor(
      sentence: sentence ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      insertionPosition: insertionPosition ?? this.insertionPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'BaseCursor(position: ${insertionPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BaseCursor otherWords = other as BaseCursor;
    if (sentence != otherWords.sentence) return false;
    if (seekPosition != otherWords.seekPosition) return false;
    if (insertionPosition != otherWords.insertionPosition) return false;
    if (option != otherWords.option) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ insertionPosition.hashCode ^ option.hashCode;
}
