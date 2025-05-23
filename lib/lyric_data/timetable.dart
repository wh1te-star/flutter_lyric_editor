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
import 'package:lyric_editor/position/phrase_position.dart';
import 'package:lyric_editor/position/timing_index.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';

class Timetable {
  final SeekPosition startTimestamp;
  final WordList wordList;
  late TimingPointList timingPointList;

  Timetable({
    required this.startTimestamp,
    required this.wordList,
  }) {
    timingPointList = constructTimingPointList(wordList);
  }

  String get sentence => wordList.sentence;
  SeekPosition get endTimestamp {
    return SeekPosition(startTimestamp.position + timingPointList.list.last.seekPosition.position);
  }

  List<Word> get words => wordList.list;
  List<TimingPoint> get timingPoints => timingPointList.list;
  int get charCount => wordList.charCount;
  int get wordCount => wordList.wordCount;

  static Timetable get empty => Timetable(
        startTimestamp: SeekPosition.empty,
        wordList: WordList.empty,
      );

  bool get isEmpty => this == empty;

  TimingPointList constructTimingPointList(WordList wordList) {
    return wordList.toTimingPointList();
  }

  WordList syncWords(TimingPointList timingPointList) {
    return timingPointList.toWordList(sentence);
  }

  Word toWord(WordIndex wordIndex) {
    return words[wordIndex.index];
  }

  TimingPointIndex leftTimingPointIndex(WordIndex wordIndex) {
    if (wordIndex.index < 0 && words.length < wordIndex.index) {
      return TimingPointIndex.empty;
    }
    return TimingPointIndex(wordIndex.index);
  }

  TimingPointIndex rightTimingPointIndex(WordIndex wordIndex) {
    if (wordIndex.index + 1 < 0 && words.length < wordIndex.index + 1) {
      return TimingPointIndex.empty;
    }
    return TimingPointIndex(wordIndex.index + 1);
  }

  TimingPoint leftTimingPoint(WordIndex wordIndex) {
    if (wordIndex.index < 0 && words.length < wordIndex.index) {
      return TimingPoint.empty;
    }
    return timingPoints[wordIndex.index];
  }

  TimingPoint rightTimingPoint(WordIndex wordIndex) {
    if (wordIndex.index + 1 < 0 && words.length < wordIndex.index + 1) {
      return TimingPoint.empty;
    }
    return timingPoints[wordIndex.index + 1];
  }

  Timetable editSentence(String newSentence) {
    List<int> charPositionTranslation = getCharPositionTranslation(sentence, newSentence);

    WordList wordList = this.wordList;
    List<Word> words = wordList.list;
    Timetable timetable = Timetable(startTimestamp: startTimestamp, wordList: wordList);
    for (TimingPoint timingPoint in timingPointList.list) {
      InsertionPosition currentCharPosition = timingPoint.insertionPosition;
      if (charPositionTranslation[currentCharPosition.position] == -1) {
        try {
          timetable = timetable.deleteTimingPoint(currentCharPosition, Option.former);
        } on TimingPointException catch (_, e) {
          debugPrint(e.toString());
        }
        try {
          timetable = timetable.deleteTimingPoint(currentCharPosition, Option.latter);
        } on TimingPointException catch (_, e) {
          debugPrint(e.toString());
        }
      }
    }

    for (int index = 0; index < words.length; index++) {
      int leftCharPosition = charPositionTranslation[timingPoints[index].insertionPosition.position];
      int rightCharPosition = charPositionTranslation[timingPoints[index + 1].insertionPosition.position];
      timetable.wordList.list[index].word = newSentence.substring(leftCharPosition, rightCharPosition);
    }
    timetable = timetable.integrate2OrMoreTimingPoints();

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

  Timetable integrate2OrMoreTimingPoints() {
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

  WordList getWordList(PhrasePosition phrasePosition) {
    return WordList(
      words.sublist(
        phrasePosition.startIndex.index,
        phrasePosition.endIndex.index + 1,
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
    List<TimingPoint> timingPoints = timingPointList.list;
    for (int index = 0; index < words.length; index++) {
      if (seekPosition.position < startTimestamp.position + timingPoints[index + 1].seekPosition.position) {
        return WordIndex(index);
      }
    }
    assert(false);
    return WordIndex.empty;
  }

  double getWordProgress(SeekPosition seekPosition) {
    WordIndex wordIndex = getWordIndexFromSeekPosition(seekPosition);
    SeekPosition wordStartSeekPosition = SeekPosition(startTimestamp.position + leftTimingPoint(wordIndex).seekPosition.position);
    SeekPosition wordEndSeekPosition = SeekPosition(startTimestamp.position + rightTimingPoint(wordIndex).seekPosition.position);
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

    for (int index = 0; index < timingPoints.length; index++) {
      TimingPoint timingPoint = timingPoints[index];
      if (timingPoint.insertionPosition == insertionPosition) {
        bool duplicate = false;
        if (index + 1 >= timingPoints.length) {
          return TimingPointInsertionPositionInfo(TimingPointIndex(index), duplicate);
        }

        TimingPoint nextTimingPoint = timingPoints[index + 1];
        if (timingPoint.insertionPosition == nextTimingPoint.insertionPosition) {
          duplicate = true;
        }
        return TimingPointInsertionPositionInfo(TimingPointIndex(index), duplicate);
      }
    }

    for (int index = 0; index <= words.length; index++) {
      TimingPoint leftTimingPoint = timingPoints[index];
      TimingPoint rightTimingPoint = timingPoints[index + 1];
      if (leftTimingPoint.insertionPosition < insertionPosition && insertionPosition < rightTimingPoint.insertionPosition) {
        return WordInsertionPositionInfo(
          WordIndex(index),
        );
      }
    }

    assert(false, "An unexpected state is occurred.");
    return WordInsertionPositionInfo.empty;
  }

  Timetable manipulateTimetable(SeekPosition seekPosition, SentenceEdge sentenceEdge, bool holdLength) {
    if (holdLength) {
      if (sentenceEdge == SentenceEdge.start) {
        Duration shiftDuration = Duration(milliseconds: startTimestamp.position - seekPosition.position);
        return shiftTimetableBy(shiftDuration);
      } else {
        Duration shiftDuration = Duration(milliseconds: seekPosition.position - endTimestamp.position);
        return shiftTimetableBy(shiftDuration);
      }
    }

    if (sentenceEdge == SentenceEdge.start) {
      if (seekPosition < startTimestamp) {
        Duration extendDuration = Duration(milliseconds: startTimestamp.position - seekPosition.position);
        return extendTimetableBy(SentenceEdge.start, extendDuration);
      }
      if (startTimestamp < seekPosition) {
        Duration shortenDuration = Duration(milliseconds: seekPosition.position - startTimestamp.position);
        return shortenTimetableBy(SentenceEdge.start, shortenDuration);
      }
    } else {
      if (seekPosition < endTimestamp) {
        Duration shortenDuration = Duration(milliseconds: endTimestamp.position - seekPosition.position);
        return shortenTimetableBy(SentenceEdge.start, shortenDuration);
      }
      if (endTimestamp < seekPosition) {
        Duration extendDuration = Duration(milliseconds: seekPosition.position - endTimestamp.position);
        return extendTimetableBy(SentenceEdge.start, extendDuration);
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

  Timetable extendTimetableBy(SentenceEdge sentenceEdge, Duration extendDuration) {
    assert(extendDuration >= Duration.zero, "Should be shorten function.");

    SeekPosition startTimestamp = this.startTimestamp;
    WordList wordList = this.wordList;
    if (sentenceEdge == SentenceEdge.start) {
      startTimestamp -= extendDuration;
      wordList.list.first.duration += extendDuration;
    } else {
      wordList.list.last.duration += extendDuration;
    }

    return Timetable(startTimestamp: startTimestamp, wordList: wordList);
  }

  Timetable shortenTimetableBy(SentenceEdge sentenceEdge, Duration shortenDuration) {
    assert(shortenDuration >= Duration.zero, "Should be extend function.");

    SeekPosition startTimestamp = this.startTimestamp;
    WordList wordList = this.wordList;
    List<Word> words = wordList.list;
    if (sentenceEdge == SentenceEdge.start) {
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

  Timetable addTimingPoint(InsertionPosition insertionPosition, SeekPosition seekPosition) {
    if (insertionPosition.position <= 0 || sentence.length <= insertionPosition.position) {
      throw TimingPointException("The insertion position is out of the valid range.");
    }
    seekPosition = SeekPosition(seekPosition.position - startTimestamp.position);

    int wordIndex = -1;
    int timingPointIndex = -1;
    for (int index = 0; index < words.length; index++) {
      if (timingPoints[index].insertionPosition == insertionPosition) {
        timingPointIndex = index;
        break;
      }
      if (timingPoints[index].insertionPosition < insertionPosition && insertionPosition < timingPoints[index + 1].insertionPosition) {
        wordIndex = index;
        break;
      }
    }
    assert(wordIndex != -1 || timingPointIndex != -1, "An unexpected state occured.");

    if (wordIndex != -1) {
      TimingPoint leftTimingPoint = timingPoints[wordIndex];
      TimingPoint rightTimingPoint = timingPoints[wordIndex + 1];
      if (seekPosition <= leftTimingPoint.seekPosition || rightTimingPoint.seekPosition <= seekPosition) {
        throw TimingPointException("The seek position is out of the valid range.");
      }

      timingPoints.insert(
        wordIndex + 1,
        TimingPoint(insertionPosition, seekPosition),
      );
      WordList wordList = syncWords(TimingPointList(timingPoints));
      return Timetable(startTimestamp: startTimestamp, wordList: wordList);
    }

    int count = timingPoints.where((TimingPoint timingPoint) {
      return timingPoint.insertionPosition == insertionPosition;
    }).length;
    if (count >= 2) {
      throw TimingPointException("A timing point cannot be inserted three times or more at the same char position.");
    }

    assert(0 < timingPointIndex && timingPointIndex < timingPoints.length - 1);
    TimingPoint leftTimingPoint = timingPoints[timingPointIndex - 1];
    TimingPoint centerTimingPoint = timingPoints[timingPointIndex];
    TimingPoint rightTimingPoint = timingPoints[timingPointIndex + 1];

    if (seekPosition <= leftTimingPoint.seekPosition || rightTimingPoint.seekPosition <= seekPosition) {
      throw TimingPointException("The seek position is out of the valid range.");
    }
    if (seekPosition == centerTimingPoint.seekPosition) {
      throw TimingPointException("A timing point cannot be inserted twice or more at the same seek position.");
    }

    if (seekPosition < centerTimingPoint.seekPosition) {
      timingPoints.insert(
        timingPointIndex,
        TimingPoint(insertionPosition, seekPosition),
      );
    } else {
      timingPoints.insert(
        timingPointIndex + 1,
        TimingPoint(insertionPosition, seekPosition),
      );
    }

    WordList wordList = syncWords(TimingPointList(timingPoints));
    return Timetable(startTimestamp: startTimestamp, wordList: wordList);
  }

  Timetable deleteTimingPoint(InsertionPosition charPosition, Option option) {
    List<TimingPoint> timingPoints = timingPointList.list;
    int index = timingPoints.indexWhere((timingPoint) => timingPoint.insertionPosition == charPosition);
    if (index == -1) {
      throw TimingPointException("There is not the specified timing point.");
    }

    if (option == Option.latter) {
      index++;
    }
    timingPoints.removeAt(index);

    WordList wordList = syncWords(TimingPointList(timingPoints));
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
