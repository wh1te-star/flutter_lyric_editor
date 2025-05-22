import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/sentence_segment_edit.dart';
import 'package:lyric_editor/position/character_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timing_point/timing_point.dart';
import 'package:lyric_editor/lyric_data/timing_point/timing_point_list.dart';
import 'package:lyric_editor/lyric_data/timing_exception.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_point_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/position/timing_point_index.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';

class Timeline {
  final SeekPosition startTime;
  final WordList wordList;
  late TimingList timingList;

  Timeline({
    required this.startTime,
    required this.wordList,
  }) {
    timingList = constructTimingList(wordList);
  }

  String get sentence => wordList.sentence;
  SeekPosition get endTimestamp {
    return SeekPosition(startTime.position + timingList.list.last.seekPosition.position);
  }

  List<Word> get words => wordList.list;
  List<TimingPoint> get timings => timingList.list;
  int get charCount => wordList.charLength;
  int get segmentCount => wordList.segmentLength;

  static Timeline get empty => Timeline(
        startTime: SeekPosition.empty,
        wordList: WordList.empty,
      );

  bool get isEmpty => this == empty;

  TimingList constructTimingList(WordList wordList) {
    return wordList.toTimingPointList();
  }

  WordList syncSentenceSegments(TimingList timingList) {
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

  TimingPoint leftTiming(WordIndex wordIndex) {
    if (wordIndex.index < 0 && words.length < wordIndex.index) {
      return TimingPoint.empty;
    }
    return timings[wordIndex.index];
  }

  TimingPoint rightTiming(WordIndex wordIndex) {
    if (wordIndex.index + 1 < 0 && words.length < wordIndex.index + 1) {
      return TimingPoint.empty;
    }
    return timings[wordIndex.index + 1];
  }

  Timeline editSentence(String newSentence) {
    List<int> charPositionTranslation = getCharPositionTranslation(sentence, newSentence);

    WordList wordList = this.wordList;
    List<Word> words = wordList.list;
    Timeline timeline = Timeline(startTime: startTime, wordList: wordList);
    for (TimingPoint timingPoint in timingList.list) {
      InsertionPosition currentInsertionPosition = timingPoint.insertionPosition;
      if (charPositionTranslation[currentInsertionPosition.position] == -1) {
        try {
          timeline = timeline.deleteTiming(currentInsertionPosition, Option.former);
        } on TimingException catch (_, e) {
          debugPrint(e.toString());
        }
        try {
          timeline = timeline.deleteTiming(currentInsertionPosition, Option.latter);
        } on TimingException catch (_, e) {
          debugPrint(e.toString());
        }
      }
    }

    for (int index = 0; index < words.length; index++) {
      int leftCharPosition = charPositionTranslation[timings[index].insertionPosition.position];
      int rightCharPosition = charPositionTranslation[timings[index + 1].insertionPosition.position];
      timeline.wordList.list[index].word = newSentence.substring(leftCharPosition, rightCharPosition);
    }
    timeline = timeline.integrate2OrMoreTimingPoints();

    return timeline;
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

  Timeline integrate2OrMoreTimingPoints() {
    List<Word> result = [];
    int accumulatedSum = 0;

    for (Word sentenceSegment in wordList.list) {
      if (sentenceSegment.word == "") {
        accumulatedSum += sentenceSegment.duration.inMilliseconds;
      } else {
        if (accumulatedSum != 0) {
          result.add(Word(
            "",
            Duration(milliseconds: accumulatedSum),
          ));
          accumulatedSum = 0;
        }
        result.add(sentenceSegment);
      }
    }

    if (accumulatedSum != 0) {
      result.add(Word(
        "",
        Duration(milliseconds: accumulatedSum),
      ));
    }

    return Timeline(startTime: startTime, wordList: WordList(result));
  }

  String getSegmentWord(int index) {
    return wordList.list[index].word;
  }

  WordList getSentenceSegmentList(Phrase segmentRange) {
    return WordList(
      words.sublist(
        segmentRange.startIndex.index,
        segmentRange.endIndex.index + 1,
      ),
    );
  }

  WordIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) {
    if (seekPosition < startTime) {
      return WordIndex.empty;
    }
    if (endTimestamp < seekPosition) {
      return WordIndex.empty;
    }
    List<Word> sentenceSegments = wordList.list;
    List<TimingPoint> timingPoints = timingList.list;
    for (int index = 0; index < sentenceSegments.length; index++) {
      if (seekPosition.position < startTime.position + timingPoints[index + 1].seekPosition.position) {
        return WordIndex(index);
      }
    }
    assert(false);
    return WordIndex.empty;
  }

  double getSegmentProgress(SeekPosition seekPosition) {
    WordIndex segmentIndex = getSegmentIndexFromSeekPosition(seekPosition);
    SeekPosition segmentStartSeekPosition = SeekPosition(startTime.position + leftTiming(segmentIndex).seekPosition.position);
    SeekPosition segmentEndSeekPosition = SeekPosition(startTime.position + rightTiming(segmentIndex).seekPosition.position);
    if (seekPosition < segmentStartSeekPosition) {
      return 0.0;
    }
    if (segmentEndSeekPosition < seekPosition) {
      return 1.0;
    }
    Duration partialProgress = Duration(milliseconds: seekPosition.position - segmentStartSeekPosition.position);
    Duration segmentDuration = toWord(segmentIndex).duration;
    return partialProgress.inMilliseconds / segmentDuration.inMilliseconds;
  }

  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) {
    if (insertionPosition.position < 0 || sentence.length < insertionPosition.position) {
      return null;
    }

    for (int index = 0; index < timings.length; index++) {
      TimingPoint timingPoint = timings[index];
      if (timingPoint.insertionPosition == insertionPosition) {
        bool duplicate = false;
        if (index + 1 >= timings.length) {
          return TimingPointInsertionPositionInfo(TimingIndex(index), duplicate);
        }

        TimingPoint nextTimingPoint = timings[index + 1];
        if (timingPoint.insertionPosition == nextTimingPoint.insertionPosition) {
          duplicate = true;
        }
        return TimingPointInsertionPositionInfo(TimingIndex(index), duplicate);
      }
    }

    for (int index = 0; index <= words.length; index++) {
      TimingPoint leftTimingPoint = timings[index];
      TimingPoint rightTimingPoint = timings[index + 1];
      if (leftTimingPoint.insertionPosition < insertionPosition && insertionPosition < rightTimingPoint.insertionPosition) {
        return SentenceSegmentInsertionPositionInfo(
          WordIndex(index),
        );
      }
    }

    assert(false, "An unexpected state is occurred.");
    return SentenceSegmentInsertionPositionInfo.empty;
  }

  Timeline manipulateTiming(SeekPosition seekPosition, SnippetEdge snippetEdge, bool holdLength) {
    if (holdLength) {
      if (snippetEdge == SnippetEdge.start) {
        Duration shiftDuration = Duration(milliseconds: startTime.position - seekPosition.position);
        return shiftTimingBy(shiftDuration);
      } else {
        Duration shiftDuration = Duration(milliseconds: seekPosition.position - endTimestamp.position);
        return shiftTimingBy(shiftDuration);
      }
    }

    if (snippetEdge == SnippetEdge.start) {
      if (seekPosition < startTime) {
        Duration extendDuration = Duration(milliseconds: startTime.position - seekPosition.position);
        return extendTimingBy(SnippetEdge.start, extendDuration);
      }
      if (startTime < seekPosition) {
        Duration shortenDuration = Duration(milliseconds: seekPosition.position - startTime.position);
        return shortenTimingBy(SnippetEdge.start, shortenDuration);
      }
    } else {
      if (seekPosition < endTimestamp) {
        Duration shortenDuration = Duration(milliseconds: endTimestamp.position - seekPosition.position);
        return shortenTimingBy(SnippetEdge.start, shortenDuration);
      }
      if (endTimestamp < seekPosition) {
        Duration extendDuration = Duration(milliseconds: seekPosition.position - endTimestamp.position);
        return extendTimingBy(SnippetEdge.start, extendDuration);
      }
    }
    return this;
  }

  Timeline shiftTimingBy(Duration shiftDuration) {
    return Timeline(
      startTime: startTime + shiftDuration,
      wordList: wordList,
    );
  }

  Timeline extendTimingBy(SnippetEdge snippetEdge, Duration extendDuration) {
    assert(extendDuration >= Duration.zero, "Should be shorten function.");

    SeekPosition startTimestamp = this.startTime;
    WordList sentenceSegmentList = this.wordList;
    if (snippetEdge == SnippetEdge.start) {
      startTimestamp -= extendDuration;
      sentenceSegmentList.list.first.duration += extendDuration;
    } else {
      sentenceSegmentList.list.last.duration += extendDuration;
    }

    return Timeline(startTime: startTimestamp, wordList: sentenceSegmentList);
  }

  Timeline shortenTimingBy(SnippetEdge snippetEdge, Duration shortenDuration) {
    assert(shortenDuration >= Duration.zero, "Should be extend function.");

    SeekPosition startTimestamp = this.startTime;
    WordList sentenceSegmentList = this.wordList;
    List<Word> sentenceSegments = sentenceSegmentList.list;
    if (snippetEdge == SnippetEdge.start) {
      int index = 0;
      Duration rest = shortenDuration;
      while (index < sentenceSegments.length && rest - sentenceSegments[index].duration > Duration.zero) {
        rest -= sentenceSegments[index].duration;
        index++;
      }
      startTimestamp += shortenDuration;
      sentenceSegments = sentenceSegments.sublist(index);
      sentenceSegments.first.duration -= rest;
    } else {
      int index = sentenceSegments.length - 1;
      Duration rest = shortenDuration;
      while (index >= 0 && rest - sentenceSegments[index].duration > Duration.zero) {
        rest -= sentenceSegments[index].duration;
        index--;
      }
      sentenceSegments = sentenceSegments.sublist(0, index + 1);
      sentenceSegments.last.duration -= rest;
    }

    return Timeline(startTime: startTimestamp, wordList: sentenceSegmentList);
  }

  Timeline addTimingPoint(InsertionPosition charPosition, SeekPosition seekPosition) {
    if (charPosition.position <= 0 || sentence.length <= charPosition.position) {
      throw TimingException("The char position is out of the valid range.");
    }
    seekPosition = SeekPosition(seekPosition.position - startTime.position);

    int segmentIndex = -1;
    int timingPointIndex = -1;
    for (int index = 0; index < words.length; index++) {
      if (timings[index].insertionPosition == charPosition) {
        timingPointIndex = index;
        break;
      }
      if (timings[index].insertionPosition < charPosition && charPosition < timings[index + 1].insertionPosition) {
        segmentIndex = index;
        break;
      }
    }
    assert(segmentIndex != -1 || timingPointIndex != -1, "An unexpected state occured.");

    if (segmentIndex != -1) {
      TimingPoint leftTimingPoint = timings[segmentIndex];
      TimingPoint rightTimingPoint = timings[segmentIndex + 1];
      if (seekPosition <= leftTimingPoint.seekPosition || rightTimingPoint.seekPosition <= seekPosition) {
        throw TimingException("The seek position is out of the valid range.");
      }

      timings.insert(
        segmentIndex + 1,
        TimingPoint(charPosition, seekPosition),
      );
      WordList sentenceSegmentList = syncSentenceSegments(TimingList(timings));
      return Timeline(startTime: startTime, wordList: sentenceSegmentList);
    }

    int count = timings.where((TimingPoint timingPoint) {
      return timingPoint.insertionPosition == charPosition;
    }).length;
    if (count >= 2) {
      throw TimingException("A timing point cannot be inserted three times or more at the same char position.");
    }

    assert(0 < timingPointIndex && timingPointIndex < timings.length - 1);
    TimingPoint leftTimingPoint = timings[timingPointIndex - 1];
    TimingPoint centerTimingPoint = timings[timingPointIndex];
    TimingPoint rightTimingPoint = timings[timingPointIndex + 1];

    if (seekPosition <= leftTimingPoint.seekPosition || rightTimingPoint.seekPosition <= seekPosition) {
      throw TimingException("The seek position is out of the valid range.");
    }
    if (seekPosition == centerTimingPoint.seekPosition) {
      throw TimingException("A timing point cannot be inserted twice or more at the same seek position.");
    }

    if (seekPosition < centerTimingPoint.seekPosition) {
      timings.insert(
        timingPointIndex,
        TimingPoint(charPosition, seekPosition),
      );
    } else {
      timings.insert(
        timingPointIndex + 1,
        TimingPoint(charPosition, seekPosition),
      );
    }

    WordList sentenceSegmentList = syncSentenceSegments(TimingList(timings));
    return Timeline(startTime: startTime, wordList: sentenceSegmentList);
  }

  Timeline deleteTiming(InsertionPosition charPosition, Option option) {
    List<TimingPoint> timingPoints = timingList.list;
    int index = timingPoints.indexWhere((timingPoint) => timingPoint.insertionPosition == charPosition);
    if (index == -1) {
      throw TimingException("There is not the specified timing point.");
    }

    if (option == Option.latter) {
      index++;
    }
    timingPoints.removeAt(index);

    WordList sentenceSegmentList = syncSentenceSegments(TimingList(timingPoints));
    return Timeline(startTime: startTime, wordList: sentenceSegmentList);
  }

  Timeline copyWith({
    SeekPosition? startTimestamp,
    WordList? sentenceSegmentList,
  }) {
    return Timeline(
      startTime: startTimestamp ?? this.startTime.copyWith(),
      wordList: sentenceSegmentList ?? this.wordList.copyWith(),
    );
  }

  @override
  String toString() {
    return "$startTime/$wordList";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Timeline) {
      return false;
    }
    return startTime == other.startTime && wordList == other.wordList;
  }

  @override
  int get hashCode => startTime.hashCode ^ wordList.hashCode;
}
