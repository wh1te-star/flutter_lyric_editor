import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/invalid_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/word_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/timing_caret_position_info.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/seek_position_info/invalid_seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/timing_seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/word_seek_position_info.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/service/timing_service.dart';

class BaseCursor extends TextPaneCursor {
  CaretPosition caretPosition;
  Option option;

  BaseCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
    required this.caretPosition,
    required this.option,
  }) : super(sentence, seekPosition);

  BaseCursor._privateConstructor(
    super.sentence,
    super.seekPosition,
    this.caretPosition,
    this.option,
  );
  static final BaseCursor _empty = BaseCursor._privateConstructor(
    Sentence.empty,
    SeekPosition.empty,
    CaretPosition.empty,
    Option.former,
  );
  static BaseCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory BaseCursor.defaultCursor({
    required Sentence sentence,
    required SeekPosition seekPosition,
  }) {
    SeekPositionInfo seekPositionInfo = sentence.getSeekPositionInfoBySeekPosition(seekPosition);
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

    return BaseCursor(
      sentence: sentence,
      seekPosition: seekPosition,
      caretPosition: caretPosition,
      option: Option.former,
    );
  }

  CaretPosition decreasedPosition(CaretPosition caretPosition) {
    CaretPosition nextCaretPosition = caretPosition - 1;
    if (nextCaretPosition <= CaretPosition(0)) {
      return CaretPosition.empty;
    }
    return nextCaretPosition;
  }

  CaretPosition prevTimingPosition(TimingIndex timingIndex) {
    if (timingIndex - 1 <= TimingIndex(0)) {
      return CaretPosition.empty;
    }
    Timing previousTiming = sentence.timings[timingIndex.index - 1];
    return previousTiming.caretPosition;
  }

  CaretPosition getLeftPosition() {
    CaretPositionInfo caretPositionInfo = sentence.getCaretPositionInfo(caretPosition);
    assert(caretPositionInfo is! InvalidCaretPositionInfo, "An unexpected state was occurred for the caret position info.");

    SeekPositionInfo seekPositionInfo = sentence.getSeekPositionInfoBySeekPosition(seekPosition);
    assert(seekPositionInfo is! InvalidSeekPositionInfo, "An unexpected state was occurred for the seek position info.");

    if (caretPositionInfo is WordCaretPositionInfo && seekPositionInfo is WordSeekPositionInfo) {
      WordIndex incaretWordIndex = caretPositionInfo.wordIndex;
      WordIndex seekingWordIndex = seekPositionInfo.wordIndex;
      assert(incaretWordIndex == seekingWordIndex, "An unexpected state was occurred.");

      return decreasedPosition(caretPosition);
    }

    if (caretPositionInfo is TimingCaretPositionInfo && seekPositionInfo is TimingSeekPositionInfo) {
      TimingIndex incaretTimingIndex = caretPositionInfo.timingIndex;
      return prevTimingPosition(incaretTimingIndex);
    }
    {
      if (option == Option.latter) {
        return caretPosition;
      }

      TimingIndex rightTimingIndex = sentence.timetable.getRightTimingIndex(seekPositionInfo);
      TimingIndex incaretTimingIndex = caretPositionInfo.timingIndex;
      if (incaretTimingIndex == rightTimingIndex) {
        nextCaretPosition = caretPosition - 1;
      } else {
        ////
      }
    }

    assert(false);
    return CaretPosition.empty;
  }

  TextPaneCursor moveToCaretPositionFromRight(CaretPosition targetPosition) {
    CaretPositionInfo nextCaretPositionInfo = sentence.getCaretPositionInfo(targetPosition);
    assert(nextCaretPositionInfo is! InvalidCaretPositionInfo, "An unexpected state was occurred for the caret position info.");
    if (nextCaretPositionInfo is WordCaretPositionInfo) {
      return copyWith(caretPosition: targetPosition, option: Option.none);
    }
    if (nextCaretPositionInfo is TimingCaretPositionInfo) {
      Option nextOption = Option.former;
      if (nextCaretPositionInfo.duplicate) {
        nextOption = Option.latter;
      }
      return copyWith(caretPosition: targetPosition, option: nextOption);
    }

    return this;
  }

  @override
  TextPaneCursor moveLeftCursor() {
    CaretPosition nextCaretPosition = getLeftPosition();
    if (nextCaretPosition.isEmpty) {
      return this;
    }
    if (nextCaretPosition == caretPosition) {
      return copyWith(option: Option.former);
    }
    return moveToCaretPositionFromRight(nextCaretPosition);
  }

  @override
  TextPaneCursor moveRightCursor() {
    CaretPositionInfo caretPositionInfo = sentence.getCaretPositionInfo(caretPosition);
    assert(caretPositionInfo is! InvalidCaretPositionInfo, "An unexpected state was occurred for the caret position info.");

    WordIndex highlightWordIndex = sentence.getSeekPositionInfoBySeekPosition(seekPosition);
    CaretPosition nextCaretPosition = CaretPosition.empty;
    if (caretPositionInfo is WordCaretPositionInfo) {
      WordIndex wordIndex = caretPositionInfo.wordIndex;
      assert(wordIndex == highlightWordIndex, "An unexpected state was occurred.");
      nextCaretPosition = caretPosition + 1;
      if (nextCaretPosition >= CaretPosition(sentence.sentence.length)) {
        return this;
      }
    }

    if (caretPositionInfo is TimingCaretPositionInfo) {
      if (caretPositionInfo.duplicate && option == Option.former) {
        return copyWith(option: Option.latter);
      }

      TimingIndex leftTimingIndex = sentence.timetable.getLeftTimingIndex(highlightWordIndex);
      TimingIndex timingIndex = caretPositionInfo.timingIndex;
      if (caretPositionInfo.duplicate) timingIndex = timingIndex + 1;
      if (timingIndex == leftTimingIndex) {
        nextCaretPosition = caretPosition + 1;
      } else {
        TimingIndex nextTimingIndex = timingIndex + 1;
        if (nextTimingIndex.index >= sentence.timings.length - 1) {
          return this;
        }
        Timing nextTiming = sentence.timings[nextTimingIndex.index];
        nextCaretPosition = nextTiming.caretPosition;
      }
    }

    CaretPositionInfo nextCaretPositionInfo = sentence.getCaretPositionInfo(nextCaretPosition);
    assert(nextCaretPositionInfo is! InvalidCaretPositionInfo, "An unexpected state was occurred for the caret position info.");
    if (nextCaretPositionInfo is WordCaretPositionInfo) {
      return copyWith(caretPosition: nextCaretPosition, option: Option.none);
    }
    if (nextCaretPositionInfo is TimingCaretPositionInfo) {
      return copyWith(caretPosition: nextCaretPosition, option: Option.former);
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
    if (caretPosition.position - wordList.charCount < 0) {
      return null;
    }
    CaretPosition newCaretPosition = caretPosition - wordList.charCount;
    return copyWith(caretPosition: newCaretPosition);
  }

  @override
  BaseCursor? shiftLeftByWord(Word word) {
    if (caretPosition.position - word.word.length < 0) {
      return null;
    }
    CaretPosition newCaretPosition = caretPosition - word.word.length;
    return copyWith(caretPosition: newCaretPosition);
  }

  BaseCursor copyWith({
    Sentence? sentence,
    SeekPosition? seekPosition,
    CaretPosition? caretPosition,
    Option? option,
  }) {
    return BaseCursor(
      sentence: sentence ?? this.sentence,
      seekPosition: seekPosition ?? this.seekPosition,
      caretPosition: caretPosition ?? this.caretPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'BaseCursor(position: ${caretPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final BaseCursor otherWords = other as BaseCursor;
    if (sentence != otherWords.sentence) return false;
    if (seekPosition != otherWords.seekPosition) return false;
    if (caretPosition != otherWords.caretPosition) return false;
    if (option != otherWords.option) return false;
    return true;
  }

  @override
  int get hashCode => sentence.hashCode ^ seekPosition.hashCode ^ caretPosition.hashCode ^ option.hashCode;
}
