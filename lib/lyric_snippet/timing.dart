import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lyric_editor/pane/text_pane/edit_widget/sentence_segment/sentence_segment_edit.dart';
import 'package:lyric_editor/position/character_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point_list.dart';
import 'package:lyric_editor/lyric_snippet/timing_point_exception.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/sentence_segment_insertion_position_info.dart';
import 'package:lyric_editor/position/insertion_position_info/timing_point_insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/position/timing_point_index.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';

class Timing {
  final SeekPosition startTimestamp;
  final SentenceSegmentList sentenceSegmentList;
  late TimingPointList timingPointList;

  Timing({
    required this.startTimestamp,
    required this.sentenceSegmentList,
  }) {
    timingPointList = constructTimingPointList(sentenceSegmentList);
  }

  String get sentence => sentenceSegmentList.sentence;
  SeekPosition get endTimestamp {
    return SeekPosition(startTimestamp.position + timingPointList.list.last.seekPosition.position);
  }

  List<SentenceSegment> get sentenceSegments => sentenceSegmentList.list;
  List<TimingPoint> get timingPoints => timingPointList.list;
  int get charLength => sentenceSegmentList.charLength;
  int get segmentLength => sentenceSegmentList.segmentLength;

  static Timing get empty => Timing(
        startTimestamp: SeekPosition.empty,
        sentenceSegmentList: SentenceSegmentList.empty,
      );

  bool get isEmpty => this == empty;

  TimingPointList constructTimingPointList(SentenceSegmentList sentenceSegmentList) {
    return sentenceSegmentList.toTimingPointList();
  }

  SentenceSegmentList syncSentenceSegments(TimingPointList timingPointList) {
    return timingPointList.toSentenceSegmentList(sentence);
  }

  SentenceSegment toSentenceSegment(SentenceSegmentIndex segmentIndex) {
    return sentenceSegments[segmentIndex.index];
  }

  TimingPointIndex leftTimingPointIndex(SentenceSegmentIndex segmentIndex) {
    if (segmentIndex.index < 0 && sentenceSegments.length < segmentIndex.index) {
      return TimingPointIndex.empty;
    }
    return TimingPointIndex(segmentIndex.index);
  }

  TimingPointIndex rightTimingPointIndex(SentenceSegmentIndex segmentIndex) {
    if (segmentIndex.index + 1 < 0 && sentenceSegments.length < segmentIndex.index + 1) {
      return TimingPointIndex.empty;
    }
    return TimingPointIndex(segmentIndex.index + 1);
  }

  TimingPoint leftTimingPoint(SentenceSegmentIndex segmentIndex) {
    if (segmentIndex.index < 0 && sentenceSegments.length < segmentIndex.index) {
      return TimingPoint.empty;
    }
    return timingPoints[segmentIndex.index];
  }

  TimingPoint rightTimingPoint(SentenceSegmentIndex segmentIndex) {
    if (segmentIndex.index + 1 < 0 && sentenceSegments.length < segmentIndex.index + 1) {
      return TimingPoint.empty;
    }
    return timingPoints[segmentIndex.index + 1];
  }

  Timing editSentence(String newSentence) {
    List<int> charPositionTranslation = getCharPositionTranslation(sentence, newSentence);

    SentenceSegmentList sentenceSegmentList = this.sentenceSegmentList;
    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;
    List<TimingPoint> timingPoints = timingPointList.list;
    Timing timing = Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
    for (TimingPoint timingPoint in timingPointList.list) {
      InsertionPosition currentCharPosition = timingPoint.charPosition;
      if (charPositionTranslation[currentCharPosition.position] == -1) {
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
      int leftCharPosition = charPositionTranslation[timingPoints[index].charPosition.position];
      int rightCharPosition = charPositionTranslation[timingPoints[index + 1].charPosition.position];
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
        accumulatedSum += sentenceSegment.duration.inMilliseconds;
      } else {
        if (accumulatedSum != 0) {
          result.add(SentenceSegment(
            "",
            Duration(milliseconds: accumulatedSum),
          ));
          accumulatedSum = 0;
        }
        result.add(sentenceSegment);
      }
    }

    if (accumulatedSum != 0) {
      result.add(SentenceSegment(
        "",
        Duration(milliseconds: accumulatedSum),
      ));
    }

    return Timing(startTimestamp: startTimestamp, sentenceSegmentList: SentenceSegmentList(result));
  }

  String getSegmentWord(int index) {
    return sentenceSegmentList.list[index].word;
  }

  SentenceSegmentList getSentenceSegmentList(SegmentRange segmentRange) {
    return SentenceSegmentList(
      sentenceSegments.sublist(
        segmentRange.startIndex.index,
        segmentRange.endIndex.index + 1,
      ),
    );
  }

  SentenceSegmentIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) {
    if (seekPosition < startTimestamp) {
      return SentenceSegmentIndex.empty;
    }
    if (endTimestamp < seekPosition) {
      return SentenceSegmentIndex.empty;
    }
    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;
    List<TimingPoint> timingPoints = timingPointList.list;
    for (int index = 0; index < sentenceSegments.length; index++) {
      if (seekPosition.position < startTimestamp.position + timingPoints[index + 1].seekPosition.position) {
        return SentenceSegmentIndex(index);
      }
    }
    return SentenceSegmentIndex.empty;
  }

  double getSegmentProgress(SeekPosition seekPosition) {
    SentenceSegmentIndex segmentIndex = getSegmentIndexFromSeekPosition(seekPosition);
    SeekPosition segmentStartSeekPosition = SeekPosition(startTimestamp.position + leftTimingPoint(segmentIndex).seekPosition.position);
    SeekPosition segmentEndSeekPosition = SeekPosition(startTimestamp.position + rightTimingPoint(segmentIndex).seekPosition.position);
    if (seekPosition < segmentStartSeekPosition) {
      return 0.0;
    }
    if (segmentEndSeekPosition < seekPosition) {
      return 1.0;
    }
    Duration partialProgress = Duration(milliseconds: seekPosition.position - segmentStartSeekPosition.position);
    Duration segmentDuration = toSentenceSegment(segmentIndex).duration;
    return partialProgress.inMilliseconds / segmentDuration.inMilliseconds;
  }

  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) {
    if (insertionPosition.position < 0 || sentence.length < insertionPosition.position) {
      return null;
    }

    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;
    List<TimingPoint> timingPoints = timingPointList.list;
    for (int index = 0; index < sentenceSegments.length; index++) {
      int leftSegmentPosition = timingPoints[index].charPosition.position;
      int rightSegmentPosition = timingPoints[index + 1].charPosition.position;
      if (leftSegmentPosition < insertionPosition.position && insertionPosition.position < rightSegmentPosition) {
        return SentenceSegmentInsertionPositionInfo(SentenceSegmentIndex(index));
      }
      if (insertionPosition.position == leftSegmentPosition) {
        if (leftSegmentPosition == rightSegmentPosition) {
          return TimingPointInsertionPositionInfo(TimingPointIndex(index), true);
        } else {
          return TimingPointInsertionPositionInfo(TimingPointIndex(index), false);
        }
      }
    }
    return TimingPointInsertionPositionInfo(TimingPointIndex(sentenceSegments.length), false);
  }

  Timing manipulateTiming(SeekPosition seekPosition, SnippetEdge snippetEdge, bool holdLength) {
    if (holdLength) {
      if (snippetEdge == SnippetEdge.start) {
        Duration shiftDuration = Duration(milliseconds: startTimestamp.position - seekPosition.position);
        return shiftTimingBy(shiftDuration);
      } else {
        Duration shiftDuration = Duration(milliseconds: seekPosition.position - endTimestamp.position);
        return shiftTimingBy(shiftDuration);
      }
    }

    if (snippetEdge == SnippetEdge.start) {
      if (seekPosition < startTimestamp) {
        Duration extendDuration = Duration(milliseconds: startTimestamp.position - seekPosition.position);
        return extendTimingBy(SnippetEdge.start, extendDuration);
      }
      if (startTimestamp < seekPosition) {
        Duration shortenDuration = Duration(milliseconds: seekPosition.position - startTimestamp.position);
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

  Timing shiftTimingBy(Duration shiftDuration) {
    return Timing(
      startTimestamp: startTimestamp + shiftDuration,
      sentenceSegmentList: sentenceSegmentList,
    );
  }

  Timing extendTimingBy(SnippetEdge snippetEdge, Duration extendDuration) {
    assert(extendDuration >= Duration.zero, "Should be shorten function.");

    SeekPosition startTimestamp = this.startTimestamp;
    SentenceSegmentList sentenceSegmentList = this.sentenceSegmentList;
    if (snippetEdge == SnippetEdge.start) {
      startTimestamp -= extendDuration;
      sentenceSegmentList.list.first.duration += extendDuration;
    } else {
      sentenceSegmentList.list.last.duration += extendDuration;
    }

    return Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
  }

  Timing shortenTimingBy(SnippetEdge snippetEdge, Duration shortenDuration) {
    assert(shortenDuration >= Duration.zero, "Should be extend function.");

    SeekPosition startTimestamp = this.startTimestamp;
    SentenceSegmentList sentenceSegmentList = this.sentenceSegmentList;
    List<SentenceSegment> sentenceSegments = sentenceSegmentList.list;
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

    return Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
  }

  Timing addTimingPoint(InsertionPosition charPosition, SeekPosition seekPosition) {
    if (charPosition.position <= 0 || sentence.length <= charPosition.position) {
      throw TimingPointException("The char position is out of the valid range.");
    }
    seekPosition = SeekPosition(seekPosition.position - startTimestamp.position);

    int segmentIndex = -1;
    int timingPointIndex = -1;
    for (int index = 0; index < sentenceSegments.length; index++) {
      if (timingPoints[index].charPosition == charPosition) {
        timingPointIndex = index;
        break;
      }
      if (timingPoints[index].charPosition < charPosition && charPosition < timingPoints[index + 1].charPosition) {
        segmentIndex = index;
        break;
      }
    }
    assert(segmentIndex != -1 || timingPointIndex != -1, "An unexpected state occured.");

    if (segmentIndex != -1) {
      TimingPoint leftTimingPoint = timingPoints[segmentIndex];
      TimingPoint rightTimingPoint = timingPoints[segmentIndex + 1];
      if (seekPosition <= leftTimingPoint.seekPosition || rightTimingPoint.seekPosition <= seekPosition) {
        throw TimingPointException("The seek position is out of the valid range.");
      }

      timingPoints.insert(
        segmentIndex + 1,
        TimingPoint(charPosition, seekPosition),
      );
      SentenceSegmentList sentenceSegmentList = syncSentenceSegments(TimingPointList(timingPoints));
      return Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
    }

    int count = timingPoints.where((TimingPoint timingPoint) {
      return timingPoint.charPosition == charPosition;
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
        TimingPoint(charPosition, seekPosition),
      );
    } else {
      timingPoints.insert(
        timingPointIndex + 1,
        TimingPoint(charPosition, seekPosition),
      );
    }

    SentenceSegmentList sentenceSegmentList = syncSentenceSegments(TimingPointList(timingPoints));
    return Timing(startTimestamp: startTimestamp, sentenceSegmentList: sentenceSegmentList);
  }

  Timing deleteTimingPoint(InsertionPosition charPosition, Option option) {
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
    SeekPosition? startTimestamp,
    SentenceSegmentList? sentenceSegmentList,
  }) {
    return Timing(
      startTimestamp: startTimestamp ?? this.startTimestamp.copyWith(),
      sentenceSegmentList: sentenceSegmentList ?? this.sentenceSegmentList.copyWith(),
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
