import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/position_type_info.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point_list.dart';
import 'package:lyric_editor/lyric_snippet/timing_point_exception.dart';
import 'package:lyric_editor/service/timing_service.dart';

class Timing {
  final int startTimestamp;
  final SentenceSegmentList sentenceSegmentList;
  late TimingPointList timingPointList;

  Timing({
    required this.startTimestamp,
    required this.sentenceSegmentList,
  }) {
    timingPointList = constructTimingPointList(sentenceSegmentList);
  }

  String get sentence => sentenceSegmentList.sentence;
  int get endTimestamp {
    return startTimestamp + timingPointList.list.last.seekPosition;
  }
  List<SentenceSegment> get sentenceSegments => sentenceSegmentList.list;
  List<TimingPoint> get timingPoints => timingPointList.list;

  static Timing get empty {
    return Timing(
      startTimestamp: 0,
      sentenceSegmentList: SentenceSegmentList.empty,
    );
  }

  bool isEmpty() {
    return startTimestamp == 0 && sentenceSegmentList.isEmpty();
  }

  TimingPointList constructTimingPointList(SentenceSegmentList sentenceSegmentList) {
    List<TimingPoint> timingPoints = [];
    int charPosition = 0;
    int seekPosition = 0;
    for (var segment in sentenceSegmentList.list) {
      timingPoints.add(TimingPoint(charPosition, seekPosition));
      charPosition += segment.word.length;
      seekPosition += segment.duration;
    }
    timingPoints.add(TimingPoint(charPosition, seekPosition));

    return TimingPointList(timingPoints);
  }

  SentenceSegmentList syncSentenceSegments(TimingPointList timingPointList) {
    List<SentenceSegment> sentenceSegments = [];
    List<TimingPoint> timingPoints = timingPointList.list;
    for (int index = 0; index < timingPoints.length - 1; index++) {
      String word = sentence.substring(timingPoints[index].charPosition, timingPoints[index + 1].charPosition);
      int duration = timingPoints[index + 1].seekPosition - timingPoints[index].seekPosition;
      sentenceSegments.add(SentenceSegment(word, duration));
    }

    return SentenceSegmentList(sentenceSegments);
  }

  Timing editSentence(String newSentence) {
    List<int> charPositionTranslation = getCharPositionTranslation(sentence, newSentence);

    SentenceSegmentList sentenceSegmentList = this.sentenceSegmentList;
    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;
    List<TimingPoint> timingPoints = timingPointList.list;
    Timing timing = Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
    for (TimingPoint timingPoint in timingPointList.list) {
      int currentCharPosition = timingPoint.charPosition;
      if (charPositionTranslation[currentCharPosition] == -1) {
        try {
          timing = timing.deleteTimingPoint(currentCharPosition, Option.former);
        } on TimingPointException catch (_, e) {
          debugPrint(e.toString());
        }
        try {
          timing = timing.deleteTimingPoint(currentCharPosition, Option.latter);
        } on TimingPointException catch (_, e) {
          debugPrint(e.toString());
        }
      }
    }

    for (int index = 0; index < sentenceSegments.length; index++) {
      int leftCharPosition = charPositionTranslation[timingPoints[index].charPosition];
      int rightCharPosition = charPositionTranslation[timingPoints[index + 1].charPosition];
      timing.sentenceSegmentList.list[index].word = newSentence.substring(leftCharPosition, rightCharPosition);
    }
    timing = timing.integrate2OrMoreTimingPoints();

    return timing;
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

  Timing integrate2OrMoreTimingPoints() {
    List<SentenceSegment> result = [];
    int accumulatedSum = 0;

    for (SentenceSegment sentenceSegment in sentenceSegmentList.list) {
      if (sentenceSegment.word == "") {
        accumulatedSum += sentenceSegment.duration;
      } else {
        if (accumulatedSum != 0) {
          result.add(SentenceSegment("", accumulatedSum));
          accumulatedSum = 0;
        }
        result.add(sentenceSegment);
      }
    }

    if (accumulatedSum != 0) {
      result.add(SentenceSegment("", accumulatedSum));
    }

    return Timing(startTimestamp: startTimestamp, sentenceSegmentList: SentenceSegmentList(result));
  }

  String getSegmentWord(int index) {
    return sentenceSegmentList.list[index].word;
  }

  int getSegmentIndexFromSeekPosition(int seekPosition) {
    if (seekPosition < startTimestamp || endTimestamp < seekPosition) {
      return -1;
    }
    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;
    List<TimingPoint> timingPoints = timingPointList.list;
    for (int index = 0; index < sentenceSegments.length; index++) {
      if (seekPosition <= startTimestamp + timingPoints[index + 1].seekPosition) {
        return index;
      }
    }
    return sentenceSegments.length;
  }

  PositionTypeInfo getPositionTypeInfo(int charPosition) {
    if (charPosition < 0 || sentence.length < charPosition) {
      return PositionTypeInfo(PositionType.sentenceSegment, -1, false);
    }

    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;
    List<TimingPoint> timingPoints = timingPointList.list;
    for (int index = 0; index < sentenceSegments.length; index++) {
      int leftSegmentPosition = timingPoints[index].charPosition;
      int rightSegmentPosition = timingPoints[index + 1].charPosition;
      if (leftSegmentPosition < charPosition && charPosition < rightSegmentPosition) {
        return PositionTypeInfo(PositionType.sentenceSegment, index, false);
      }
      if (charPosition == leftSegmentPosition) {
        if (leftSegmentPosition == rightSegmentPosition) {
          return PositionTypeInfo(PositionType.timingPoint, index, true);
        } else {
          return PositionTypeInfo(PositionType.timingPoint, index, false);
        }
      }
    }
    return PositionTypeInfo(PositionType.timingPoint, sentenceSegments.length, false);
  }

  Timing moveSnippet(int shiftDuration) {
    return Timing(
      startTimestamp: startTimestamp + shiftDuration,
      sentenceSegmentList: sentenceSegmentList,
    );
  }

  Timing extendSnippet(SnippetEdge snippetEdge, int extendDuration) {
    assert(extendDuration >= 0, "Should be shorten function.");

    int startTimestamp = this.startTimestamp;
    SentenceSegmentList sentenceSegmentList = this.sentenceSegmentList;
    if (snippetEdge == SnippetEdge.start) {
      startTimestamp -= extendDuration;
      sentenceSegmentList.list.first.duration += extendDuration;
    } else {
      sentenceSegmentList.list.last.duration += extendDuration;
    }

    return Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
  }

  Timing shortenSnippet(SnippetEdge snippetEdge, int shortenDuration) {
    assert(shortenDuration >= 0, "Should be extend function.");

    int startTimestamp = this.startTimestamp;
    SentenceSegmentList sentenceSegmentList = this.sentenceSegmentList;
    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;
    if (snippetEdge == SnippetEdge.start) {
      int index = 0;
      int rest = shortenDuration;
      while (index < sentenceSegments.length && rest - sentenceSegments[index].duration > 0) {
        rest -= sentenceSegments[index].duration;
        index++;
      }
      startTimestamp += shortenDuration;
      sentenceSegments = sentenceSegments.sublist(index);
      sentenceSegments.first.duration -= rest;
    } else {
      int index = sentenceSegments.length - 1;
      int rest = shortenDuration;
      while (index >= 0 && rest - sentenceSegments[index].duration > 0) {
        rest -= sentenceSegments[index].duration;
        index--;
      }
      sentenceSegments = sentenceSegments.sublist(0, index + 1);
      sentenceSegments.last.duration -= rest;
    }

    return Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
  }

  Timing addTimingPoint(int charPosition, int seekPosition) {
    if (charPosition <= 0 || sentence.length <= charPosition) {
      throw TimingPointException("The char position is out of the valid range.");
    }
    if (seekPosition <= startTimestamp || endTimestamp <= seekPosition) {
      throw TimingPointException("The seek position is out of the valid range.");
    }

    List<TimingPoint> timingPoints = timingPointList.list;
    seekPosition -= startTimestamp;
    for (int index = 0; index < timingPoints.length - 1; index++) {
      if (charPosition == timingPoints[index].charPosition) {
        if (timingPoints[index].charPosition == timingPoints[index + 1].charPosition) {
          throw TimingPointException("A timing point cannot be inserted three times or more at the same char position.");
        }
        if (seekPosition == timingPoints[index].seekPosition) {
          throw TimingPointException("A timing point cannot be inserted twice or more at the same seek position.");
        }

        if (seekPosition < timingPoints[index].seekPosition) {
          timingPoints.insert(index, TimingPoint(charPosition, seekPosition));
          break;
        } else {
          timingPoints.insert(index + 1, TimingPoint(charPosition, seekPosition));
          break;
        }
      }

      if (timingPoints[index].charPosition < charPosition && charPosition < timingPoints[index + 1].charPosition) {
        timingPoints.insert(index + 1, TimingPoint(charPosition, seekPosition));
        break;
      }
    }

    SentenceSegmentList sentenceSegmentList = syncSentenceSegments(TimingPointList(timingPoints));
    return Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
  }

  Timing deleteTimingPoint(int charPosition, Option option) {
    List<TimingPoint> timingPoints = timingPointList.list;
    int index = timingPoints.indexWhere((timingPoint) => timingPoint.charPosition == charPosition);
    if (index == -1) {
      throw TimingPointException("There is not the specified timing point.");
    }

    if (option == Option.latter) {
      index++;
    }
    timingPoints.removeAt(index);

    SentenceSegmentList sentenceSegmentList = syncSentenceSegments(TimingPointList(timingPoints));
    return Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
  }

  Timing copyWith({
    int? startTimestamp,
    SentenceSegmentList? sentenceSegmentList,
  }) {
    return Timing(
      startTimestamp: startTimestamp ?? this.startTimestamp,
      sentenceSegmentList: sentenceSegmentList?.copyWith() ?? this.sentenceSegmentList,
    );
  }

  @override
  String toString() {
    return "$startTimestamp/$sentenceSegmentList";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Timing) {
      return false;
    }
    return startTimestamp == other.startTimestamp && sentenceSegmentList == other.sentenceSegmentList;
  }

  @override
  int get hashCode => startTimestamp.hashCode ^ sentenceSegmentList.hashCode;
}
