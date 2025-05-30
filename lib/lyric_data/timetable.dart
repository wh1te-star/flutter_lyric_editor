import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/word/word_edit.dart';
import 'package:lyric_editor/position/character_position.dart';
import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/lyric_data/timing/timing_list.dart';
import 'package:lyric_editor/lyric_data/timing_exception.dart';
import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/caret_position_info/invalid_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/word_caret_position_info.dart';
import 'package:lyric_editor/position/caret_position_info/timing_caret_position_info.dart';
import 'package:lyric_editor/position/option_enum.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/empty_seek_position.dart';
import 'package:lyric_editor/position/seek_position/relative_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/position/seek_position_info/invalid_seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/timing_seek_position_info.dart';
import 'package:lyric_editor/position/seek_position_info/word_seek_position_info.dart';
import 'package:lyric_editor/position/sentence_side_enum.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/service/timing_service.dart';

class Timetable {
  final SeekPosition startTimestamp;
  final WordList _wordList;
  late TimingList _timingList;

  Timetable({
    required this.startTimestamp,
    required WordList wordList,
  }) : _wordList = wordList {
    _timingList = constructTimingList(_wordList);
  }

  String get sentence => _wordList.sentence;
  SeekPosition get endTimestamp {
    return timingList.list.last.seekPosition;
  }

  WordList get wordList => _wordList;
  TimingList get timingList => _timingList;
  int get charCount => _wordList.charCount;
  int get wordCount => _wordList.wordCount;

  static Timetable get empty => Timetable(
        startTimestamp: EmptySeekPosition(),
        wordList: WordList.empty,
      );

  bool get isEmpty => this == empty;

  TimingList constructTimingList(WordList wordList) {
    return wordList.toTimingList(startTimestamp.absolute);
  }

  WordList syncWords(TimingList timingList) {
    return timingList.toWordList(sentence);
  }

  Word toWord(WordIndex wordIndex) {
    return wordList[wordIndex];
  }

  TimingIndex getLeftTimingIndex(WordIndex wordIndex) {
    if (wordIndex.index < 0 && wordList.length < wordIndex.index) {
      return TimingIndex.empty;
    }
    return TimingIndex(wordIndex.index);
  }

  TimingIndex getRightTimingIndex(WordIndex wordIndex) {
    if (wordIndex.index + 1 < 0 && wordList.length < wordIndex.index + 1) {
      return TimingIndex.empty;
    }
    return TimingIndex(wordIndex.index + 1);
  }

  Timing getLeftTiming(WordIndex wordIndex) {
    if (wordIndex.index < 0 && wordList.length < wordIndex.index) {
      return Timing.empty;
    }
    return timingList.list[wordIndex.index];
  }

  Timing getRightTiming(WordIndex wordIndex) {
    if (wordIndex.index + 1 < 0 && wordList.length < wordIndex.index + 1) {
      return Timing.empty;
    }
    return timingList.list[wordIndex.index + 1];
  }

  Timetable editSentence(String newSentence) {
    List<int> charPositionTranslation = getCharPositionTranslation(sentence, newSentence);

    List<Word> words = wordList.list;
    Timetable timetable = Timetable(startTimestamp: startTimestamp, wordList: wordList);
    for (Timing timing in _timingList.list) {
      CaretPosition currentCharPosition = timing.caretPosition;
      if (charPositionTranslation[currentCharPosition.position] == -1) {
        try {
          timetable = timetable.deleteTiming(currentCharPosition, Option.former);
        } on TimingException catch (_, e) {
          debugPrint(e.toString());
        }
        try {
          timetable = timetable.deleteTiming(currentCharPosition, Option.latter);
        } on TimingException catch (_, e) {
          debugPrint(e.toString());
        }
      }
    }

    for (int index = 0; index < words.length; index++) {
      TimingIndex timingIndex = TimingIndex(index);
      int leftCharPosition = charPositionTranslation[timingList[timingIndex].caretPosition.position];
      int rightCharPosition = charPositionTranslation[timingList[timingIndex + 1].caretPosition.position];
      timetable._wordList.list[index].word = newSentence.substring(leftCharPosition, rightCharPosition);
    }
    timetable = timetable.integrate2OrMoreTimings();

    return timetable;
  }

  List<int> getCharPositionTranslation(String oldSentence, String newSentence) {
    int oldLength = oldSentence.length;
    int newLength = newSentence.length;

    List<List<int>> lcsMap = List.generate(oldLength + 1, (_) => List.filled(newLength + 1, 0));

    for (int i = 1; i <= oldLength; i++) {
      for (int j = 1; j <= newLength; j++) {
        if (oldSentence[i - 1] == newSentence[j - 1]) {
          lcsMap[i][j] = lcsMap[i - 1][j - 1] + 1;
        } else {
          lcsMap[i][j] = max(lcsMap[i - 1][j], lcsMap[i][j - 1]);
        }
      }
    }

    List<int> indexTranslation = List.filled(oldLength + 1, -1);
    int i = oldLength, j = newLength;

    while (i > 0 && j > 0) {
      if (oldSentence[i - 1] == newSentence[j - 1]) {
        indexTranslation[i] = j;
        indexTranslation[i - 1] = j - 1;
        i--;
        j--;
      } else if (lcsMap[i - 1][j] >= lcsMap[i][j - 1]) {
        i--;
      } else {
        j--;
      }
    }

    return indexTranslation;
  }

  Timetable integrate2OrMoreTimings() {
    List<Word> result = [];
    int accumulatedSum = 0;

    for (Word word in _wordList.list) {
      if (word.word == "") {
        accumulatedSum += word.duration.inMilliseconds;
      } else {
        if (accumulatedSum != 0) {
          result.add(Word(
            "",
            Duration(milliseconds: accumulatedSum),
          ));
          accumulatedSum = 0;
        }
        result.add(word);
      }
    }

    if (accumulatedSum != 0) {
      result.add(Word(
        "",
        Duration(milliseconds: accumulatedSum),
      ));
    }

    return Timetable(startTimestamp: startTimestamp, wordList: WordList(result));
  }

  String getWordString(int index) {
    return _wordList.list[index].word;
  }

  WordList getWordList(WordRange wordRange) {
    return WordList(
      wordList.list.sublist(
        wordRange.startIndex.index,
        wordRange.endIndex.index + 1,
      ),
    );
  }

  SeekPositionInfo getSeekPositionInfoBySeekPosition(AbsoluteSeekPosition seekPosition) {
    if (seekPosition < startTimestamp.absolute) {
      return InvalidSeekPositionInfo(SentenceSide.start);
    }

    if (seekPosition == startTimestamp) {
      return TimingSeekPositionInfo(TimingIndex(0));
    }
    for (int index = 0; index < wordList.length; index++) {
      WordIndex wordIndex = WordIndex(index);
      Timing rightTiming = getRightTiming(wordIndex);
      AbsoluteSeekPosition rightSeekPosition = rightTiming.seekPosition.absolute;
      if (seekPosition < rightSeekPosition) {
        return WordSeekPositionInfo(wordIndex);
      }
      if (seekPosition == rightSeekPosition) {
        TimingIndex rightTimingIndex = getRightTimingIndex(wordIndex);
        return TimingSeekPositionInfo(rightTimingIndex);
      }
    }
    return InvalidSeekPositionInfo(SentenceSide.end);
  }

  CaretPositionInfo getCaretPositionInfo(CaretPosition caretPosition) {
    if (caretPosition.position < 0 || sentence.length < caretPosition.position) {
      return InvalidCaretPositionInfo();
    }

    for (int index = 0; index < timingList.length; index++) {
      TimingIndex timingIndex = TimingIndex(index);
      Timing timing = timingList[timingIndex];
      if (timing.caretPosition == caretPosition) {
        bool duplicate = false;
        if (index + 1 >= timingList.length) {
          return TimingCaretPositionInfo(TimingIndex(index), duplicate);
        }

        Timing nextTiming = timingList[timingIndex + 1];
        if (timing.caretPosition == nextTiming.caretPosition) {
          duplicate = true;
        }
        return TimingCaretPositionInfo(TimingIndex(index), duplicate);
      }
    }

    for (int index = 0; index <= wordList.length; index++) {
      TimingIndex timingIndex = TimingIndex(index);
      Timing leftTiming = timingList[timingIndex];
      Timing rightTiming = timingList[timingIndex + 1];
      if (leftTiming.caretPosition < caretPosition && caretPosition < rightTiming.caretPosition) {
        return WordCaretPositionInfo(
          WordIndex(index),
        );
      }
    }

    assert(false, "An unexpected state is occurred.");
    return InvalidCaretPositionInfo();
  }

  Timetable manipulateTimetable(AbsoluteSeekPosition seekPosition, SentenceSide sentenceSide, bool holdLength) {
    if (holdLength) {
      if (sentenceSide == SentenceSide.start) {
        Duration shiftDuration = startTimestamp.absolute.durationUntil(seekPosition);
        return shiftTimetableBy(shiftDuration);
      } else {
        Duration shiftDuration = endTimestamp.absolute.durationUntil(seekPosition);
        return shiftTimetableBy(shiftDuration);
      }
    }

    if (sentenceSide == SentenceSide.start) {
      if (seekPosition < startTimestamp.absolute) {
        Duration extendDuration = seekPosition.durationUntil(startTimestamp.absolute);
        return extendTimetableBy(SentenceSide.start, extendDuration);
      }
      if (startTimestamp.absolute < seekPosition) {
        Duration shortenDuration = startTimestamp.absolute.durationUntil(seekPosition);
        return shortenTimetableBy(SentenceSide.start, shortenDuration);
      }
    } else {
      if (seekPosition < endTimestamp.absolute) {
        Duration shortenDuration = seekPosition.durationUntil(endTimestamp.absolute);
        return shortenTimetableBy(SentenceSide.start, shortenDuration);
      }
      if (endTimestamp.absolute < seekPosition) {
        Duration extendDuration = endTimestamp.absolute.durationUntil(seekPosition);
        return extendTimetableBy(SentenceSide.start, extendDuration);
      }
    }
    return this;
  }

  Timetable shiftTimetableBy(Duration shiftDuration) {
    return Timetable(
      startTimestamp: startTimestamp + shiftDuration,
      wordList: _wordList,
    );
  }

  Timetable extendTimetableBy(SentenceSide sentenceSide, Duration extendDuration) {
    assert(extendDuration >= Duration.zero, "Should be shorten function.");

    SeekPosition newStartTimestamp = startTimestamp;
    WordList newWordList = this._wordList;
    if (sentenceSide == SentenceSide.start) {
      newStartTimestamp -= extendDuration;
      newWordList.list.first.duration += extendDuration;
    } else {
      newWordList.list.last.duration += extendDuration;
    }

    return Timetable(startTimestamp: newStartTimestamp, wordList: newWordList);
  }

  Timetable shortenTimetableBy(SentenceSide sentenceSide, Duration shortenDuration) {
    assert(shortenDuration >= Duration.zero, "Should be extend function.");

    SeekPosition newStartTimestamp = startTimestamp;
    WordList newWordList = _wordList;
    List<Word> words = newWordList.list;
    if (sentenceSide == SentenceSide.start) {
      int index = 0;
      Duration rest = shortenDuration;
      while (index < words.length && rest - words[index].duration > Duration.zero) {
        rest -= words[index].duration;
        index++;
      }
      newStartTimestamp += shortenDuration;
      words = words.sublist(index);
      words.first.duration -= rest;
    } else {
      int index = words.length - 1;
      Duration rest = shortenDuration;
      while (index >= 0 && rest - words[index].duration > Duration.zero) {
        rest -= words[index].duration;
        index--;
      }
      words = words.sublist(0, index + 1);
      words.last.duration -= rest;
    }

    return Timetable(startTimestamp: newStartTimestamp, wordList: newWordList);
  }

  Timetable addTiming(CaretPosition caretPosition, AbsoluteSeekPosition seekPosition) {
    if (caretPosition.position <= 0 || sentence.length <= caretPosition.position) {
      throw TimingException("The caret position is out of the valid range.");
    }

    CaretPositionInfo caretPositionInfo = getCaretPositionInfo(caretPosition);

    if (caretPositionInfo is WordCaretPositionInfo) {
      WordIndex wordIndex = caretPositionInfo.wordIndex;
      Timing leftTiming = getLeftTiming(wordIndex);
      Timing rightTiming = getRightTiming(wordIndex);
      if (seekPosition <= leftTiming.seekPosition.absolute || rightTiming.seekPosition.absolute <= seekPosition) {
        throw TimingException("The seek position is out of the valid range.");
      }

      List<Timing> newTimingList = timingList.list;
      RelativeSeekPosition relativeSeekPosition = seekPosition.toRelative(startTimestamp);
      newTimingList.insert(
        wordIndex.index + 1,
        Timing(caretPosition, relativeSeekPosition),
      );
      WordList wordList = syncWords(TimingList(newTimingList));
      return Timetable(startTimestamp: startTimestamp, wordList: wordList);
    }

    if (caretPositionInfo is TimingCaretPositionInfo) {
      int count = timingList.list.where((Timing timing) {
        return timing.caretPosition == caretPosition;
      }).length;
      if (count >= 2) {
        throw TimingException("A timing point cannot be inserted three times or more at the same char position.");
      }

      TimingIndex timingIndex = caretPositionInfo.timingIndex;
      assert(0 < timingIndex.index && timingIndex.index < timingList.length - 1);
      Timing leftTiming = timingList[timingIndex - 1];
      Timing centerTiming = timingList[timingIndex];
      Timing rightTiming = timingList[timingIndex + 1];

      if (seekPosition <= leftTiming.seekPosition.absolute || rightTiming.seekPosition.absolute <= seekPosition) {
        throw TimingException("The seek position is out of the valid range.");
      }
      if (seekPosition == centerTiming.seekPosition) {
        throw TimingException("A timing point cannot be inserted twice or more at the same seek position.");
      }

      RelativeSeekPosition relativeSeekPosition = seekPosition.toRelative(startTimestamp);
      List<Timing> newTimingList = timingList.list;
      if (seekPosition < centerTiming.seekPosition.absolute) {
        newTimingList.insert(
          timingIndex.index,
          Timing(caretPosition, relativeSeekPosition),
        );
      } else {
        newTimingList.insert(
          timingIndex.index + 1,
          Timing(caretPosition, relativeSeekPosition),
        );
      }

      WordList newWordList = syncWords(TimingList(newTimingList));
      return Timetable(startTimestamp: startTimestamp, wordList: newWordList);
    }

    assert(false);
    return Timetable.empty;
  }

  Timetable deleteTiming(CaretPosition charPosition, Option option) {
    List<Timing> timings = _timingList.list;
    int index = timings.indexWhere((timing) => timing.caretPosition == charPosition);
    if (index == -1) {
      throw TimingException("There is not the specified timing point.");
    }

    if (option == Option.latter) {
      index++;
    }
    timings.removeAt(index);

    WordList wordList = syncWords(TimingList(timings));
    return Timetable(startTimestamp: startTimestamp, wordList: wordList);
  }

  Timetable copyWith({
    SeekPosition? startTimestamp,
    WordList? wordList,
  }) {
    return Timetable(
      startTimestamp: startTimestamp ?? this.startTimestamp,
      wordList: wordList ?? this._wordList,
    );
  }

  @override
  String toString() {
    return "$startTimestamp/$_wordList";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Timetable) {
      return false;
    }
    return startTimestamp == other.startTimestamp && _wordList == other._wordList;
  }

  @override
  int get hashCode => startTimestamp.hashCode ^ _wordList.hashCode;
}
