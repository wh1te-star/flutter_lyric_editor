import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/word/word_edit.dart';
import 'package:lyric_editor/position/character_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/lyric_data/timing/timing_list.dart';
import 'package:lyric_editor/lyric_data/timing_exception.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/word_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/position/word_range.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/service/timing_service.dart';

class Timetable {
  final SeekPosition startTimestamp;
  final WordList wordList;
  late TimingList timingList;

  Timetable({
    required this.startTimestamp,
    required this.wordList,
  }) {
    timingList = constructTimingList(wordList);
  }

  String get sentence => wordList.sentence;
  SeekPosition get endTimestamp {
    return SeekPosition(startTimestamp.position + timingList.list.last.seekPosition.position);
  }

  List<Word> get words => wordList.list;
  List<Timing> get timings => timingList.list;
  int get charCount => wordList.charCount;
  int get wordCount => wordList.wordCount;

  static Timetable get empty => Timetable(
        startTimestamp: SeekPosition.empty,
        wordList: WordList.empty,
      );

  bool get isEmpty => this == empty;

  TimingList constructTimingList(WordList wordList) {
    return wordList.toTimingList();
  }

  WordList syncWords(TimingList timingList) {
    return timingList.toWordList(sentence);
  }

  Word toWord(WordIndex wordIndex) {
    return words[wordIndex.index];
  }

  TimingIndex leftTimingIndex(WordIndex wordIndex) {
    if (wordIndex.index < 0 && words.length < wordIndex.index) {
      return TimingIndex.empty;
    }
    return TimingIndex(wordIndex.index);
  }

  TimingIndex rightTimingIndex(WordIndex wordIndex) {
    if (wordIndex.index + 1 < 0 && words.length < wordIndex.index + 1) {
      return TimingIndex.empty;
    }
    return TimingIndex(wordIndex.index + 1);
  }

  Timing leftTiming(WordIndex wordIndex) {
    if (wordIndex.index < 0 && words.length < wordIndex.index) {
      return Timing.empty;
    }
    return timings[wordIndex.index];
  }

  Timing rightTiming(WordIndex wordIndex) {
    if (wordIndex.index + 1 < 0 && words.length < wordIndex.index + 1) {
      return Timing.empty;
    }
    return timings[wordIndex.index + 1];
  }

  Timetable editSentence(String newSentence) {
    List<int> charPositionTranslation = getCharPositionTranslation(sentence, newSentence);

    WordList wordList = this.wordList;
    List<Word> words = wordList.list;
    Timetable timetable = Timetable(startTimestamp: startTimestamp, wordList: wordList);
    for (Timing timing in timingList.list) {
      InsertionPosition currentCharPosition = timing.insertionPosition;
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
      int leftCharPosition = charPositionTranslation[timings[index].insertionPosition.position];
      int rightCharPosition = charPositionTranslation[timings[index + 1].insertionPosition.position];
      timetable.wordList.list[index].word = newSentence.substring(leftCharPosition, rightCharPosition);
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

    for (Word word in wordList.list) {
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
    return wordList.list[index].word;
  }

  WordList getWordList(WordRange wordRange) {
    return WordList(
      words.sublist(
        wordRange.startIndex.index,
        wordRange.endIndex.index + 1,
      ),
    );
  }

  WordIndex getWordIndexFromSeekPosition(SeekPosition seekPosition) {
    if (seekPosition < startTimestamp) {
      return WordIndex.empty;
    }
    if (endTimestamp < seekPosition) {
      return WordIndex.empty;
    }
    List<Word> words = wordList.list;
    List<Timing> timings = timingList.list;
    for (int index = 0; index < words.length; index++) {
      if (seekPosition.position < startTimestamp.position + timings[index + 1].seekPosition.position) {
        return WordIndex(index);
      }
    }
    assert(false);
    return WordIndex.empty;
  }

  double getWordProgress(SeekPosition seekPosition) {
    WordIndex wordIndex = getWordIndexFromSeekPosition(seekPosition);
    SeekPosition wordStartSeekPosition = SeekPosition(startTimestamp.position + leftTiming(wordIndex).seekPosition.position);
    SeekPosition wordEndSeekPosition = SeekPosition(startTimestamp.position + rightTiming(wordIndex).seekPosition.position);
    if (seekPosition < wordStartSeekPosition) {
      return 0.0;
    }
    if (wordEndSeekPosition < seekPosition) {
      return 1.0;
    }
    Duration partialProgress = Duration(milliseconds: seekPosition.position - wordStartSeekPosition.position);
    Duration wordDuration = toWord(wordIndex).duration;
    return partialProgress.inMilliseconds / wordDuration.inMilliseconds;
  }

  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) {
    if (insertionPosition.position < 0 || sentence.length < insertionPosition.position) {
      return null;
    }

    for (int index = 0; index < timings.length; index++) {
      Timing timing = timings[index];
      if (timing.insertionPosition == insertionPosition) {
        bool duplicate = false;
        if (index + 1 >= timings.length) {
          return TimingInsertionPositionInfo(TimingIndex(index), duplicate);
        }

        Timing nextTiming = timings[index + 1];
        if (timing.insertionPosition == nextTiming.insertionPosition) {
          duplicate = true;
        }
        return TimingInsertionPositionInfo(TimingIndex(index), duplicate);
      }
    }

    for (int index = 0; index <= words.length; index++) {
      Timing leftTiming = timings[index];
      Timing rightTiming = timings[index + 1];
      if (leftTiming.insertionPosition < insertionPosition && insertionPosition < rightTiming.insertionPosition) {
        return WordInsertionPositionInfo(
          WordIndex(index),
        );
      }
    }

    assert(false, "An unexpected state is occurred.");
    return WordInsertionPositionInfo.empty;
  }

  Timetable manipulateTimetable(SeekPosition seekPosition, SentenceSide sentenceSide, bool holdLength) {
    if (holdLength) {
      if (sentenceSide == SentenceSide.start) {
        Duration shiftDuration = Duration(milliseconds: startTimestamp.position - seekPosition.position);
        return shiftTimetableBy(shiftDuration);
      } else {
        Duration shiftDuration = Duration(milliseconds: seekPosition.position - endTimestamp.position);
        return shiftTimetableBy(shiftDuration);
      }
    }

    if (sentenceSide == SentenceSide.start) {
      if (seekPosition < startTimestamp) {
        Duration extendDuration = Duration(milliseconds: startTimestamp.position - seekPosition.position);
        return extendTimetableBy(SentenceSide.start, extendDuration);
      }
      if (startTimestamp < seekPosition) {
        Duration shortenDuration = Duration(milliseconds: seekPosition.position - startTimestamp.position);
        return shortenTimetableBy(SentenceSide.start, shortenDuration);
      }
    } else {
      if (seekPosition < endTimestamp) {
        Duration shortenDuration = Duration(milliseconds: endTimestamp.position - seekPosition.position);
        return shortenTimetableBy(SentenceSide.start, shortenDuration);
      }
      if (endTimestamp < seekPosition) {
        Duration extendDuration = Duration(milliseconds: seekPosition.position - endTimestamp.position);
        return extendTimetableBy(SentenceSide.start, extendDuration);
      }
    }
    return this;
  }

  Timetable shiftTimetableBy(Duration shiftDuration) {
    return Timetable(
      startTimestamp: startTimestamp + shiftDuration,
      wordList: wordList,
    );
  }

  Timetable extendTimetableBy(SentenceSide sentenceSide, Duration extendDuration) {
    assert(extendDuration >= Duration.zero, "Should be shorten function.");

    SeekPosition startTimestamp = this.startTimestamp;
    WordList wordList = this.wordList;
    if (sentenceSide == SentenceSide.start) {
      startTimestamp -= extendDuration;
      wordList.list.first.duration += extendDuration;
    } else {
      wordList.list.last.duration += extendDuration;
    }

    return Timetable(startTimestamp: startTimestamp, wordList: wordList);
  }

  Timetable shortenTimetableBy(SentenceSide sentenceSide, Duration shortenDuration) {
    assert(shortenDuration >= Duration.zero, "Should be extend function.");

    SeekPosition startTimestamp = this.startTimestamp;
    WordList wordList = this.wordList;
    List<Word> words = wordList.list;
    if (sentenceSide == SentenceSide.start) {
      int index = 0;
      Duration rest = shortenDuration;
      while (index < words.length && rest - words[index].duration > Duration.zero) {
        rest -= words[index].duration;
        index++;
      }
      startTimestamp += shortenDuration;
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

    return Timetable(startTimestamp: startTimestamp, wordList: wordList);
  }

  Timetable addTiming(InsertionPosition insertionPosition, SeekPosition seekPosition) {
    if (insertionPosition.position <= 0 || sentence.length <= insertionPosition.position) {
      throw TimingException("The insertion position is out of the valid range.");
    }
    seekPosition = SeekPosition(seekPosition.position - startTimestamp.position);

    int wordIndex = -1;
    int timingIndex = -1;
    for (int index = 0; index < words.length; index++) {
      if (timings[index].insertionPosition == insertionPosition) {
        timingIndex = index;
        break;
      }
      if (timings[index].insertionPosition < insertionPosition && insertionPosition < timings[index + 1].insertionPosition) {
        wordIndex = index;
        break;
      }
    }
    assert(wordIndex != -1 || timingIndex != -1, "An unexpected state occured.");

    if (wordIndex != -1) {
      Timing leftTiming = timings[wordIndex];
      Timing rightTiming = timings[wordIndex + 1];
      if (seekPosition <= leftTiming.seekPosition || rightTiming.seekPosition <= seekPosition) {
        throw TimingException("The seek position is out of the valid range.");
      }

      timings.insert(
        wordIndex + 1,
        Timing(insertionPosition, seekPosition),
      );
      WordList wordList = syncWords(TimingList(timings));
      return Timetable(startTimestamp: startTimestamp, wordList: wordList);
    }

    int count = timings.where((Timing timing) {
      return timing.insertionPosition == insertionPosition;
    }).length;
    if (count >= 2) {
      throw TimingException("A timing point cannot be inserted three times or more at the same char position.");
    }

    assert(0 < timingIndex && timingIndex < timings.length - 1);
    Timing leftTiming = timings[timingIndex - 1];
    Timing centerTiming = timings[timingIndex];
    Timing rightTiming = timings[timingIndex + 1];

    if (seekPosition <= leftTiming.seekPosition || rightTiming.seekPosition <= seekPosition) {
      throw TimingException("The seek position is out of the valid range.");
    }
    if (seekPosition == centerTiming.seekPosition) {
      throw TimingException("A timing point cannot be inserted twice or more at the same seek position.");
    }

    if (seekPosition < centerTiming.seekPosition) {
      timings.insert(
        timingIndex,
        Timing(insertionPosition, seekPosition),
      );
    } else {
      timings.insert(
        timingIndex + 1,
        Timing(insertionPosition, seekPosition),
      );
    }

    WordList wordList = syncWords(TimingList(timings));
    return Timetable(startTimestamp: startTimestamp, wordList: wordList);
  }

  Timetable deleteTiming(InsertionPosition charPosition, Option option) {
    List<Timing> timings = timingList.list;
    int index = timings.indexWhere((timing) => timing.insertionPosition == charPosition);
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
      startTimestamp: startTimestamp ?? this.startTimestamp.copyWith(),
      wordList: wordList ?? this.wordList.copyWith(),
    );
  }

  @override
  String toString() {
    return "$startTimestamp/$wordList";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Timetable) {
      return false;
    }
    return startTimestamp == other.startTimestamp && wordList == other.wordList;
  }

  @override
  int get hashCode => startTimestamp.hashCode ^ wordList.hashCode;
}
