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
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/invalid_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/timing_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/word_caret_position_info.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/seek_position_info/invalid_seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/timing_seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/word_seek_position_info.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class RubyCursor extends TextPaneCursor {
  WordRange wordRange;
  CaretPosition caretPosition;
  Option option;

  RubyCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.wordRange,
    required this.caretPosition,
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
    this.caretPosition,
    this.option,
  );
  static final RubyCursor _empty = RubyCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    WordRange.empty,
    CaretPosition.empty,
    Option.former,
  );
  static RubyCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory RubyCursor.defaultCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
  }) {
/*
    WordRange wordRange = sentence.getRubysWordRangeFromSeekPosition(seekPosition);
    Ruby ruby = sentence.rubyMap[wordRange]!;
    SeekPositionInfo seekPositionInfo = ruby.getSeekPositionInfoBySeekPosition(seekPosition);
    if (seekPositionInfo is InvalidSeekPositionInfo) {
      return empty;
    }

    CaretPosition caretPosition = CaretPosition.empty;
    if (seekPositionInfo is TimingSeekPositionInfo) {
      caretPosition = sentence.timings[seekPositionInfo.timingIndex.index].caretPosition;
    }
    if (seekPositionInfo is WordSeekPositionInfo) {
      caretPosition = sentence.timetable.getLeftTiming(seekPositionInfo.wordIndex).caretPosition + 1;
    }
    assert(caretPosition.isNotEmpty);

    return RubyCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      wordRange: wordRange,
      caretPosition: caretPosition,
      option: Option.former,
    );
    */
    return RubyCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      wordRange: WordRange.empty,
      caretPosition: CaretPosition.empty,
      option: Option.former,
    );
  }

  @override
  TextPaneCursor moveLeftCursor() {
    return this;

    /*
    Timetable rubyTimetable = sentence.rubyMap[wordRange]!.timetable;

    CaretPositionInfo caretPositionInfo = rubyTimetable.getCaretPositionInfo(caretPosition);
    assert(caretPositionInfo is! InvalidCaretPositionInfo, "An unexpected state was occurred for the caret position info.");

    WordIndex highlightWordIndex = rubyTimetable.getSeekPositionInfoBySeekPosition(seekPosition);
    CaretPosition nextCaretPosition = CaretPosition.empty;
    if (caretPositionInfo is WordCaretPositionInfo) {
      WordIndex wordIndex = caretPositionInfo.wordIndex;
      assert(wordIndex == highlightWordIndex, "An unexpected state was occurred.");
      nextCaretPosition = caretPosition - 1;
      if (nextCaretPosition <= CaretPosition(0)) {
        return this;
      }
    }

    if (caretPositionInfo is TimingCaretPositionInfo) {
      if (option == Option.latter) {
        return copyWith(option: Option.former);
      }

      TimingIndex rightTimingIndex = rubyTimetable.getRightTimingIndex(highlightWordIndex);
      TimingIndex timingIndex = caretPositionInfo.timingIndex;
      if (timingIndex == rightTimingIndex) {
        nextCaretPosition = caretPosition - 1;
      } else {
        if (timingIndex.index - 1 <= 0) {
          return this;
        }
        Timing previousTiming = rubyTimetable.timings[timingIndex.index - 1];
        nextCaretPosition = previousTiming.caretPosition;
      }
    }

    CaretPositionInfo nextCaretPositionInfo = rubyTimetable.getCaretPositionInfo(nextCaretPosition);
    assert(nextCaretPositionInfo is! InvalidCaretPositionInfo, "An unexpected state was occurred for the caret position info.");
    if (nextCaretPositionInfo is WordCaretPositionInfo) {
      return copyWith(caretPosition: nextCaretPosition, option: Option.none);
    }
    if (nextCaretPositionInfo is TimingCaretPositionInfo) {
      Option nextOption = Option.former;
      if (nextCaretPositionInfo.duplicate) {
        nextOption = Option.latter;
      }
      return copyWith(caretPosition: nextCaretPosition, option: nextOption);
    }

    return this;
    */
  }

  @override
  TextPaneCursor moveRightCursor() {
    return this;

    /*
    Timetable rubyTimetable = sentence.rubyMap[wordRange]!.timetable;

    CaretPositionInfo caretPositionInfo = rubyTimetable.getCaretPositionInfo(caretPosition);
    assert(caretPositionInfo is! InvalidCaretPositionInfo, "An unexpected state was occurred for the caret position info.");

    WordIndex highlightWordIndex = rubyTimetable.getSeekPositionInfoBySeekPosition(seekPosition);
    CaretPosition nextCaretPosition = CaretPosition.empty;
    if (caretPositionInfo is WordCaretPositionInfo) {
      WordIndex wordIndex = caretPositionInfo.wordIndex;
      assert(wordIndex == highlightWordIndex, "An unexpected state was occurred.");
      nextCaretPosition = caretPosition + 1;
      if (nextCaretPosition >= CaretPosition(rubyTimetable.sentence.length)) {
        return this;
      }
    }

    if (caretPositionInfo is TimingCaretPositionInfo) {
      if (caretPositionInfo.duplicate && option == Option.former) {
        return copyWith(option: Option.latter);
      }

      TimingIndex leftTimingIndex = rubyTimetable.getLeftTimingIndex(highlightWordIndex);
      TimingIndex timingIndex = caretPositionInfo.timingIndex;
      if (caretPositionInfo.duplicate) timingIndex = timingIndex + 1;
      if (timingIndex == leftTimingIndex) {
        nextCaretPosition = caretPosition + 1;
      } else {
        TimingIndex nextTimingIndex = timingIndex + 1;
        if (nextTimingIndex.index >= rubyTimetable.timings.length - 1) {
          return this;
        }
        Timing nextTiming = rubyTimetable.timings[nextTimingIndex.index];
        nextCaretPosition = nextTiming.caretPosition;
      }
    }

    CaretPositionInfo nextCaretPositionInfo = rubyTimetable.getCaretPositionInfo(nextCaretPosition);
    assert(nextCaretPositionInfo is! InvalidCaretPositionInfo, "An unexpected state was occurred for the caret position info.");
    if (nextCaretPositionInfo is WordCaretPositionInfo) {
      return copyWith(caretPosition: nextCaretPosition, option: Option.none);
    }
    if (nextCaretPositionInfo is TimingCaretPositionInfo) {
      return copyWith(caretPosition: nextCaretPosition, option: Option.former);
    }

    return this;
    */
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
      WordIndex wordIndex = WordIndex(index);
      Word word = wordList[wordIndex];
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
    if (caretPosition.position - word.word.length < 0) {
      return null;
    }
    CaretPosition newCaretPosition = caretPosition - word.word.length;
    return copyWith(caretPosition: newCaretPosition);
  }

  RubyCursor copyWith({
    Sentence? sentence,
    SeekPosition? seekPosition,
    WordRange? wordRange,
    CaretPosition? caretPosition,
    Option? option,
  }) {
    return RubyCursor(
      sentence: sentence ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      wordRange: wordRange ?? this.wordRange,
      caretPosition: caretPosition ?? this.caretPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'RubyCursor($sentence, wordRange: $wordRange, position: ${caretPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final RubyCursor otherWords = other as RubyCursor;
    if (sentence != otherWords.sentence) return false;
    if (seekPosition != otherWords.seekPosition) return false;
    if (wordRange != otherWords.wordRange) return false;
    if (caretPosition != otherWords.caretPosition) return false;
    if (option != otherWords.option) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ wordRange.hashCode ^ caretPosition.hashCode ^ option.hashCode;
}
