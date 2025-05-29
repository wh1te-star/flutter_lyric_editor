import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/lyric_data/timetable.dart';
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

class CaretCursor extends TextPaneCursor {
  CaretPosition caretPosition;
  Option option;

  CaretCursor({
    required Timetable timetable,
    required SeekPosition seekPosition,
    required this.caretPosition,
    required this.option,
  }) : super(timetable, seekPosition);

  CaretCursor._privateConstructor(
    super.timetable,
    super.seekPosition,
    this.caretPosition,
    this.option,
  );
  static final CaretCursor _empty = CaretCursor._privateConstructor(
    Timetable.empty,
    SeekPosition.empty,
    CaretPosition.empty,
    Option.former,
  );
  static CaretCursor get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  factory CaretCursor.defaultCursor({
    required Timetable timetable,
    required SeekPosition seekPosition,
  }) {
    SeekPositionInfo seekPositionInfo = timetable.getSeekPositionInfoBySeekPosition(seekPosition);
    if (seekPositionInfo is InvalidSeekPositionInfo) {
      return empty;
    }

    CaretPosition caretPosition = CaretPosition.empty;
    if (seekPositionInfo is TimingSeekPositionInfo) {
      caretPosition = timetable.timingList[seekPositionInfo.timingIndex].caretPosition;
    }
    if (seekPositionInfo is WordSeekPositionInfo) {
      caretPosition = timetable.getLeftTiming(seekPositionInfo.wordIndex).caretPosition + 1;
    }
    assert(caretPosition.isNotEmpty);

    return CaretCursor(
      timetable: timetable,
      seekPosition: seekPosition,
      caretPosition: caretPosition,
      option: Option.former,
    );
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
    CaretPosition nextCaretPosition = getRightPosition();
    if (nextCaretPosition.isEmpty) {
      return this;
    }
    if (nextCaretPosition == caretPosition) {
      return copyWith(option: Option.latter);
    }
    return moveToCaretPositionFromLeft(nextCaretPosition);
  }

  CaretPosition increasedPosition(CaretPosition caretPosition) {
    CaretPosition nextCaretPosition = caretPosition + 1;
    if (nextCaretPosition >= CaretPosition(timetable.sentence.length)) {
      return CaretPosition.empty;
    }
    return nextCaretPosition;
  }

  CaretPosition decreasedPosition(CaretPosition caretPosition) {
    CaretPosition nextCaretPosition = caretPosition - 1;
    if (nextCaretPosition <= CaretPosition(0)) {
      return CaretPosition.empty;
    }
    return nextCaretPosition;
  }

  CaretPosition nextTimingPosition(TimingIndex timingIndex) {
    TimingIndex nextTimingIndex = timingIndex + 1;
    if (nextTimingIndex.index >= timetable.timingList.length - 1) {
      return CaretPosition.empty;
    }
    Timing nextTiming = timetable.timingList[nextTimingIndex];
    return nextTiming.caretPosition;
  }

  CaretPosition prevTimingPosition(TimingIndex timingIndex) {
    TimingIndex prevTimingIndex = timingIndex - 1;
    if (prevTimingIndex <= TimingIndex(0)) {
      return CaretPosition.empty;
    }
    Timing prevTiming = timetable.timingList[prevTimingIndex];
    return prevTiming.caretPosition;
  }

  CaretPosition getLeftPosition() {
    CaretPositionInfo caretPositionInfo = timetable.getCaretPositionInfo(caretPosition);
    SeekPositionInfo seekPositionInfo = timetable.getSeekPositionInfoBySeekPosition(seekPosition);

    if (caretPositionInfo is WordCaretPositionInfo && seekPositionInfo is WordSeekPositionInfo) {
      WordIndex incaretWordIndex = caretPositionInfo.wordIndex;
      WordIndex seekingWordIndex = seekPositionInfo.wordIndex;
      assert(incaretWordIndex == seekingWordIndex, "An unexpected state was occurred.");

      return decreasedPosition(caretPosition);
    }

    if (caretPositionInfo is TimingCaretPositionInfo) {
      if (caretPositionInfo.duplicate && option == Option.latter) {
        return caretPosition;
      }

      TimingIndex incaretTimingIndex = caretPositionInfo.timingIndex;
      if (seekPositionInfo is TimingSeekPositionInfo) {
        return prevTimingPosition(incaretTimingIndex);
      }

      if (seekPositionInfo is WordSeekPositionInfo) {
        WordIndex seekingWordIndex = seekPositionInfo.wordIndex;
        TimingIndex rightTimingIndex = timetable.getRightTimingIndex(seekingWordIndex);
        if (incaretTimingIndex == rightTimingIndex) {
          return decreasedPosition(caretPosition);
        }
        return prevTimingPosition(incaretTimingIndex);
      }
    }

    assert(false, "Invalid state: caretPositionInfo type is ${caretPositionInfo.runtimeType} and seekPositionInfo type is ${seekPositionInfo.runtimeType}");
    return CaretPosition.empty;
  }

  TextPaneCursor moveToCaretPositionFromRight(CaretPosition targetPosition) {
    CaretPositionInfo nextCaretPositionInfo = timetable.getCaretPositionInfo(targetPosition);
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

  CaretPosition getRightPosition() {
    CaretPositionInfo caretPositionInfo = timetable.getCaretPositionInfo(caretPosition);
    SeekPositionInfo seekPositionInfo = timetable.getSeekPositionInfoBySeekPosition(seekPosition);

    if (caretPositionInfo is WordCaretPositionInfo && seekPositionInfo is WordSeekPositionInfo) {
      WordIndex incaretWordIndex = caretPositionInfo.wordIndex;
      WordIndex seekingWordIndex = seekPositionInfo.wordIndex;
      assert(incaretWordIndex == seekingWordIndex, "An unexpected state was occurred.");

      return increasedPosition(caretPosition);
    }

    if (caretPositionInfo is TimingCaretPositionInfo) {
      if (caretPositionInfo.duplicate && option == Option.former) {
        return caretPosition;
      }

      TimingIndex incaretTimingIndex = caretPositionInfo.timingIndex;
      if (seekPositionInfo is TimingSeekPositionInfo) {
        return nextTimingPosition(incaretTimingIndex);
      }

      if (seekPositionInfo is WordSeekPositionInfo) {
        TimingIndex leftTimingIndex = timetable.getLeftTimingIndex(seekPositionInfo.wordIndex);
        if (incaretTimingIndex == leftTimingIndex) {
          return increasedPosition(caretPosition);
        } else {
          return nextTimingPosition(incaretTimingIndex);
        }
      }
    }

    assert(false, "Invalid state: caretPositionInfo type is ${caretPositionInfo.runtimeType} and seekPositionInfo type is ${seekPositionInfo.runtimeType}");
    return CaretPosition.empty;
  }

  TextPaneCursor moveToCaretPositionFromLeft(CaretPosition targetPosition) {
    CaretPositionInfo nextCaretPositionInfo = timetable.getCaretPositionInfo(targetPosition);
    assert(nextCaretPositionInfo is! InvalidCaretPositionInfo, "An unexpected state was occurred for the caret position info.");
    if (nextCaretPositionInfo is WordCaretPositionInfo) {
      return copyWith(caretPosition: targetPosition, option: Option.none);
    }
    if (nextCaretPositionInfo is TimingCaretPositionInfo) {
      return copyWith(caretPosition: targetPosition, option: Option.former);
    }

    return this;
  }

  TextPaneCursor enterWordMode() {
    return WordCursor(
      timetable: timetable,
      seekPosition: seekPosition,
      wordRange: WordRange(WordIndex(0), WordIndex(0)),
      isExpandMode: false,
    );
  }

  @override
  List<TextPaneCursor?> getWordRangeDividedCursors(Timetable timetable, List<WordRange> wordRangeList) {
    List<CaretCursor?> separatedCursors = List.filled(wordRangeList.length, null);
    CaretCursor shiftedCursor = copyWith();
    for (int index = 0; index < wordRangeList.length; index++) {
      WordRange wordRange = wordRangeList[index];
      WordList? sentenceSubList = timetable.getWordList(wordRange);
      CaretCursor? nextCursor = shiftedCursor.shiftLeftByWordList(sentenceSubList);
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
    List<CaretCursor?> separatedCursors = List.filled(wordList.length, null);
    CaretCursor shiftedCursor = copyWith();
    for (int index = 0; index < wordList.length; index++) {
      WordIndex wordIndex = WordIndex(index);
      Word word = wordList[wordIndex];
      CaretCursor? nextCursor = shiftedCursor.shiftLeftByWord(word);
      if (nextCursor == null) {
        separatedCursors[index] = shiftedCursor;
        break;
      }
      shiftedCursor = nextCursor;
    }
    return separatedCursors;
  }

  @override
  CaretCursor? shiftLeftByWordList(WordList wordList) {
    if (caretPosition.position - wordList.charCount < 0) {
      return null;
    }
    CaretPosition newCaretPosition = caretPosition - wordList.charCount;
    return copyWith(caretPosition: newCaretPosition);
  }

  @override
  CaretCursor? shiftLeftByWord(Word word) {
    if (caretPosition.position - word.word.length < 0) {
      return null;
    }
    CaretPosition newCaretPosition = caretPosition - word.word.length;
    return copyWith(caretPosition: newCaretPosition);
  }

  CaretCursor copyWith({
    Timetable? timetable,
    SeekPosition? seekPosition,
    CaretPosition? caretPosition,
    Option? option,
  }) {
    return CaretCursor(
      timetable: timetable ?? this.timetable,
      seekPosition: seekPosition ?? this.seekPosition,
      caretPosition: caretPosition ?? this.caretPosition,
      option: option ?? this.option,
    );
  }

  @override
  String toString() {
    return 'CaretCursor(position: ${caretPosition.position}, option: $option)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final CaretCursor otherWords = other as CaretCursor;
    if (timetable != otherWords.timetable) return false;
    if (seekPosition != otherWords.seekPosition) return false;
    if (caretPosition != otherWords.caretPosition) return false;
    if (option != otherWords.option) return false;
    return true;
  }

  @override
  int get hashCode => timetable.hashCode ^ seekPosition.hashCode ^ caretPosition.hashCode ^ option.hashCode;
}
