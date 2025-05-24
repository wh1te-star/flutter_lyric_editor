import 'package:lyric_editor/lyric_data/ruby/ruby.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence_map.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/word_insertion_position_info.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class RubyCursor extends TextPaneCursor {
  WordRange wordRange;
  InsertionPosition insertionPosition;
  Option option;

  RubyCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.wordRange,
    required this.insertionPosition,
    required this.option,
  }) : super(sentence, seekPosition) {
    assert(doesSeekPositionPointRuby(), "The passed seek position does not point to any ruby.");
  }

  bool doesSeekPositionPointRuby() {
    WordRange wordRange = sentence.getRubysWordRangeFromSeekPosition(seekPosition);
    return wordRange.isNotEmpty;
  }

  RubyCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.wordRange,
    this.insertionPosition,
    this.option,
  );
  static final RubyCursor _empty = RubyCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    WordRange.empty,
    InsertionPosition.empty,
    Option.former,
  );
  static RubyCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory RubyCursor.defaultCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
  }) {
    WordRange wordRange = sentence.getRubysWordRangeFromSeekPosition(seekPosition);
    Ruby ruby = sentence.rubyMap[wordRange]!;
    WordIndex wordIndex = ruby.getWordIndexFromSeekPosition(seekPosition);

    return RubyCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      wordRange: wordRange,
      insertionPosition: ruby.timetable.leftTiming(wordIndex).insertionPosition + 1,
      option: Option.former,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    Timetable rubyTimetable = sentence.rubyMap[wordRange]!.timetable;

    InsertionPositionInfo? insertionPositionInfo = rubyTimetable.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");

    WordIndex highlightWordIndex = rubyTimetable.getWordIndexFromSeekPosition(seekPosition);
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

      TimingIndex rightTimingIndex = rubyTimetable.rightTimingIndex(highlightWordIndex);
      TimingIndex timingIndex = insertionPositionInfo.timingIndex;
      if (timingIndex == rightTimingIndex) {
        nextInsertionPosition = insertionPosition - 1;
      } else {
        if (timingIndex.index - 1 <= 0) {
          return this;
        }
        Timing previousTiming = rubyTimetable.timings[timingIndex.index - 1];
        nextInsertionPosition = previousTiming.insertionPosition;
      }
    }

    InsertionPositionInfo? nextInsertionPositionInfo = rubyTimetable.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");
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
    Timetable rubyTimetable = sentence.rubyMap[wordRange]!.timetable;

    InsertionPositionInfo? insertionPositionInfo = rubyTimetable.getInsertionPositionInfo(insertionPosition);
    assert(insertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");

    WordIndex highlightWordIndex = rubyTimetable.getWordIndexFromSeekPosition(seekPosition);
    InsertionPosition nextInsertionPosition = InsertionPosition.empty;
    if (insertionPositionInfo is WordInsertionPositionInfo) {
      WordIndex wordIndex = insertionPositionInfo.wordIndex;
      assert(wordIndex == highlightWordIndex, "An unexpected state was occurred.");
      nextInsertionPosition = insertionPosition + 1;
      if (nextInsertionPosition >= InsertionPosition(rubyTimetable.sentence.length)) {
        return this;
      }
    }

    if (insertionPositionInfo is TimingInsertionPositionInfo) {
      if (insertionPositionInfo.duplicate && option == Option.former) {
        return copyWith(option: Option.latter);
      }

      TimingIndex leftTimingIndex = rubyTimetable.leftTimingIndex(highlightWordIndex);
      TimingIndex timingIndex = insertionPositionInfo.timingIndex;
      if (insertionPositionInfo.duplicate) timingIndex = timingIndex + 1;
      if (timingIndex == leftTimingIndex) {
        nextInsertionPosition = insertionPosition + 1;
      } else {
        TimingIndex nextTimingIndex = timingIndex + 1;
        if (nextTimingIndex.index >= rubyTimetable.timings.length - 1) {
          return this;
        }
        Timing nextTiming = rubyTimetable.timings[nextTimingIndex.index];
        nextInsertionPosition = nextTiming.insertionPosition;
      }
    }

    InsertionPositionInfo? nextInsertionPositionInfo = rubyTimetable.getInsertionPositionInfo(nextInsertionPosition);
    assert(nextInsertionPositionInfo != null, "An unexpected state was occurred for the insertion position info.");
    if (nextInsertionPositionInfo is WordInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.none);
    }
    if (nextInsertionPositionInfo is TimingInsertionPositionInfo) {
      return copyWith(insertionPosition: nextInsertionPosition, option: Option.former);
    }

    return this;
  }

  @override
  List<TextPaneCursor?> getWordRangeDividedCursors(Sentence sentence, List<WordRange> wordRangeList) {
    List<RubyCursor?> separatedCursors = List.filled(wordRangeList.length, null);
    RubyCursor cursor = copyWith();
    for (int index = 0; index < wordRangeList.length; index++) {
      WordRange wordRange = wordRangeList[index];
      if (wordRange == cursor.wordRange) {
        separatedCursors[index] = cursor;
        break;
      }
    }
    return separatedCursors;
  }

  @override
  List<TextPaneCursor?> getWordDividedCursors(WordList wordList) {
    List<RubyCursor?> separatedCursors = List.filled(wordList.length, null);
    RubyCursor shiftedCursor = copyWith();
    for (int index = 0; index < wordList.length; index++) {
      Word word = wordList[index];
      RubyCursor? nextCursor = shiftedCursor.shiftLeftByWord(word);
      if (nextCursor == null) {
        separatedCursors[index] = shiftedCursor;
        break;
      }
      shiftedCursor = nextCursor;
    }
    return separatedCursors;
  }

  RubyCursor? shiftLeftByWord(Word word) {
    if (insertionPosition.position - word.word.length < 0) {
      return null;
    }
    InsertionPosition newInsertionPosition = insertionPosition - word.word.length;
    return copyWith(insertionPosition: newInsertionPosition);
  }

  RubyCursor copyWith({
    Sentence? sentence,
    SeekPosition? seekPosition,
    WordRange? wordRange,
    InsertionPosition? insertionPosition,
    Option? option,
  }) {
    return RubyCursor(
      sentence: sentence ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      wordRange: wordRange ?? this.wordRange,
      insertionPosition: insertionPosition ?? this.insertionPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'RubyCursor($sentence, wordRange: $wordRange, position: ${insertionPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final RubyCursor otherWords = other as RubyCursor;
    if (sentence != otherWords.sentence) return false;
    if (seekPosition != otherWords.seekPosition) return false;
    if (wordRange != otherWords.wordRange) return false;
    if (insertionPosition != otherWords.insertionPosition) return false;
    if (option != otherWords.option) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ wordRange.hashCode ^ insertionPosition.hashCode ^ option.hashCode;
}
