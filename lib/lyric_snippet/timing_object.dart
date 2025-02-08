import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/position_type_info.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/lyric_snippet/timing_point_exception.dart';
import 'package:lyric_editor/service/timing_service.dart';

mixin TimingObject {
  List<SentenceSegment> _sentenceSegments = [];
  List<TimingPoint> _timingPoints = [];
  int startTimestamp = 0;

  String get sentence {
    return sentenceSegments.map((segment) => segment.word).join();
  }

  List<TimingPoint> get timingPoints => _timingPoints;
  List<SentenceSegment> get sentenceSegments => _sentenceSegments;
  set sentenceSegments(List<SentenceSegment> segments) {
    _sentenceSegments.clear();
    _sentenceSegments.addAll(segments);
    updateTimingPoints();
  }

  int get endTimestamp {
    return startTimestamp + _timingPoints.last.seekPosition;
  }

  void updateTimingPoints() {
    List<TimingPoint> newTimingPoints = [];
    int charPosition = 0;
    int seekPosition = 0;
    for (var segment in sentenceSegments) {
      newTimingPoints.add(TimingPoint(charPosition, seekPosition));
      charPosition += segment.word.length;
      seekPosition += segment.duration;
    }
    newTimingPoints.add(TimingPoint(charPosition, seekPosition));

    _timingPoints = newTimingPoints;
  }

  void updateSentenceSegments() {
    List<SentenceSegment> newSentenceSegments = [];
    for (int index = 0; index < timingPoints.length - 1; index++) {
      String word = sentence.substring(timingPoints[index].charPosition, timingPoints[index + 1].charPosition);
      int duration = timingPoints[index + 1].seekPosition - timingPoints[index].seekPosition;
      newSentenceSegments.add(SentenceSegment(word, duration));
    }

    _sentenceSegments = newSentenceSegments;
  }

  void editSentence(String newSentence) {
    List<int> charPositionTranslation = getCharPositionTranslation(sentence, newSentence);

    List<TimingPoint> timingPointsCopy = List.from(timingPoints);
    for (var charPositions in timingPointsCopy) {
      int currentCharPosition = charPositions.charPosition;
      if (charPositionTranslation[currentCharPosition] == -1) {
        try {
          deleteTimingPoint(currentCharPosition, Option.former);
        } on TimingPointException catch (_, e) {
          debugPrint(e.toString());
        }
        try {
          deleteTimingPoint(currentCharPosition, Option.latter);
        } on TimingPointException catch (_, e) {
          debugPrint(e.toString());
        }
      }
    }

    for (int index = 0; index < sentenceSegments.length; index++) {
      int leftCharPosition = charPositionTranslation[timingPoints[index].charPosition];
      int rightCharPosition = charPositionTranslation[timingPoints[index + 1].charPosition];
      sentenceSegments[index].word = newSentence.substring(leftCharPosition, rightCharPosition);
    }
    integrate2OrMoreTimingPoints();
    updateTimingPoints();
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

  void integrate2OrMoreTimingPoints() {
    List<SentenceSegment> result = [];
    int accumulatedSum = 0;

    for (var sentenceSegment in sentenceSegments) {
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

    sentenceSegments = result;
  }

  String getSegmentWord(int index) {
    return sentence.substring(
      timingPoints[index].charPosition,
      timingPoints[index + 1].charPosition,
    );
  }

  int getSegmentIndexFromSeekPosition(int seekPosition) {
    if (seekPosition < startTimestamp || endTimestamp < seekPosition) {
      return -1;
    }
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

  void moveSnippet(int shiftDuration) {
    startTimestamp += shiftDuration;
  }

  void extendSnippet(SnippetEdge snippetEdge, int extendDuration) {
    assert(extendDuration >= 0, "Should be shorten function.");
    if (snippetEdge == SnippetEdge.start) {
      startTimestamp -= extendDuration;
      sentenceSegments.first.duration += extendDuration;
    } else {
      sentenceSegments.last.duration += extendDuration;
    }

    updateTimingPoints();
  }

  void shortenSnippet(SnippetEdge snippetEdge, int shortenDuration) {
    assert(shortenDuration >= 0, "Should be extend function.");
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

    updateTimingPoints();
  }

  void addTimingPoint(int charPosition, int seekPosition) {
    if (charPosition <= 0 || sentence.length <= charPosition) {
      debugPrint("The char position is out of the valid range.");
      return;
    }
    if (seekPosition <= startTimestamp || endTimestamp <= seekPosition) {
      debugPrint("The seek position is out of the valid range.");
      return;
    }

    seekPosition -= startTimestamp;
    for (int index = 0; index < timingPoints.length - 1; index++) {
      if (charPosition == timingPoints[index].charPosition) {
        if (timingPoints[index].charPosition == timingPoints[index + 1].charPosition) {
          debugPrint("A timing point cannot be inserted three times or more at the same char position.");
          return;
        }

        if (seekPosition < timingPoints[index].seekPosition) {
          timingPoints.insert(index, TimingPoint(charPosition, seekPosition));
          break;
        } else if (seekPosition > timingPoints[index].seekPosition) {
          timingPoints.insert(index + 1, TimingPoint(charPosition, seekPosition));
          break;
        } else {
          debugPrint("A timing point cannot be inserted twice or more at the same seek position.");
          return;
        }
      }

      if (timingPoints[index].charPosition < charPosition && charPosition < timingPoints[index + 1].charPosition) {
        timingPoints.insert(index + 1, TimingPoint(charPosition, seekPosition));
        break;
      }
    }

    updateSentenceSegments();
  }

  void deleteTimingPoint(int charPosition, Option option) {
    int index = timingPoints.indexWhere((timingPoint) => timingPoint.charPosition == charPosition);
    if (index == -1) {
      debugPrint("There is not the specified timing point.");
      return;
    }
    if (option == Option.latter) {
      index++;
    }
    timingPoints.removeAt(index);

    updateSentenceSegments();
  }
}
