import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';

class LyricSnippet with TimingObject {
  VocalistID vocalistID;
  Map<SegmentRange, Annotation> annotations;

  LyricSnippet({
    required this.vocalistID,
    required startTimestamp,
    required List<SentenceSegment> sentenceSegments,
    required this.annotations,
  }) {
    this.startTimestamp = startTimestamp;
    _sentenceSegments = sentenceSegments;
    updateTimingPoints();
  }

  static LyricSnippet get emptySnippet {
    return LyricSnippet(
      vocalistID: VocalistID(0),
      startTimestamp: 0,
      sentenceSegments: [],
      annotations: {},
    );
  }

  MapEntry<SegmentRange, Annotation> getAnnotationWords(int index) {
    return annotations.entries.firstWhere(
      (entry) => entry.key.startIndex <= index && index <= entry.key.endIndex,
      orElse: () => MapEntry(SegmentRange(-1, -1), Annotation.emptySnippet),
    );
  }

  int? getAnnotationIndexFromSeekPosition(int seekPosition) {
    for (MapEntry<SegmentRange, Annotation> entry in annotations.entries) {
      SegmentRange range = entry.key;
      Annotation annotation = entry.value;
      int startSeekPosition = startTimestamp + timingPoints[range.startIndex].seekPosition + annotation.timingPoints.first.seekPosition;
      int endSeekPosition = startTimestamp + timingPoints[range.startIndex].seekPosition + annotation.timingPoints.last.seekPosition;
      if (startSeekPosition <= seekPosition && seekPosition < endSeekPosition) {
        return range.startIndex;
      }
    }
    return null;
  }

  @override
  void addTimingPoint(int charPosition, int seekPosition) {
    carryUpAnnotationSegments(charPosition);
    super.addTimingPoint(charPosition, seekPosition);
  }

  @override
  void deleteTimingPoint(int charPosition, Option option) {
    carryDownAnnotationSegments(charPosition);
    super.deleteTimingPoint(charPosition, option);
  }

  Map<SegmentRange, Annotation> copyAnnotationMap() {
    return annotations.map((SegmentRange key, Annotation value) {
      SegmentRange newKey = key.copyWith();
      Annotation newValue = value.copyWith();
      return MapEntry(newKey, newValue);
    });
  }

  void carryUpAnnotationSegments(int charPosition) {
    PositionTypeInfo info = getPositionTypeInfo(charPosition);
    Map<SegmentRange, Annotation> updatedAnnotations = {};
    int index = info.index;

    annotations.forEach((SegmentRange key, Annotation value) {
      SegmentRange newKey = key.copyWith();

      switch (info.type) {
        case PositionType.sentenceSegment:
          if (index < key.startIndex) {
            newKey.startIndex++;
            newKey.endIndex++;
          } else if (index <= key.endIndex) {
            newKey.endIndex++;
          }
          break;
        case PositionType.timingPoint:
          int startIndex = key.startIndex;
          int endIndex = key.endIndex + 1;
          if (index <= startIndex) {
            newKey.startIndex++;
            newKey.endIndex++;
          } else if (index < endIndex) {
            newKey.endIndex++;
          }
          break;
      }
      updatedAnnotations[newKey] = value;
    });

    annotations = updatedAnnotations;
  }

  void carryDownAnnotationSegments(int charPosition) {
    PositionTypeInfo info = getPositionTypeInfo(charPosition);
    Map<SegmentRange, Annotation> updatedAnnotations = {};
    int timingPointIndex = info.index;

    annotations.forEach((SegmentRange key, Annotation value) {
      SegmentRange newKey = key.copyWith();
      int startIndex = key.startIndex;
      int endIndex = key.endIndex + 1;
      if (timingPointIndex == startIndex && timingPointIndex == endIndex + 1) {
        if (info.duplicate) {
            newKey.startIndex--;
            newKey.endIndex--;
        } else {
          return;
        }
      } else if (timingPointIndex < startIndex) {
        newKey.startIndex--;
        newKey.endIndex--;
      } else if (timingPointIndex < endIndex) {
        newKey.endIndex--;
      }
      updatedAnnotations[newKey] = value;
    });

    annotations = updatedAnnotations;
  }

  void addAnnotation(String annotationString, int startIndex, int endIndex) {
    int duration = sentenceSegments.sublist(startIndex, endIndex + 1).fold(0, (sum, segment) => sum + segment.duration);
    TimingPoint justBeforeTimingPoint = timingPoints[startIndex];
    SegmentRange annotationKey = SegmentRange(startIndex, endIndex);
    annotations[annotationKey] = Annotation(startTimestamp: startTimestamp + justBeforeTimingPoint.seekPosition, sentenceSegments: [
      SentenceSegment(
        annotationString,
        duration,
      ),
    ]);
  }

  void deleteAnnotation(SegmentRange range) {
    annotations.remove(range);
  }

  LyricSnippet copyWith({
    VocalistID? vocalistID,
    int? startTimestamp,
    List<SentenceSegment>? sentenceSegments,
    Map<SegmentRange, Annotation>? annotations,
  }) {
    return LyricSnippet(
      vocalistID: vocalistID ?? this.vocalistID,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      sentenceSegments: sentenceSegments ?? _sentenceSegments,
      annotations: annotations ?? this.annotations,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is LyricSnippet && runtimeType == other.runtimeType && vocalistID == other.vocalistID && sentence == other.sentence && startTimestamp == other.startTimestamp && listEquals(_sentenceSegments, other._sentenceSegments);

  @override
  int get hashCode => Object.hash(vocalistID, startTimestamp, Object.hashAll(_sentenceSegments));
}

class Annotation with TimingObject {
  Annotation({
    required int startTimestamp,
    required List<SentenceSegment> sentenceSegments,
  }) {
    this.startTimestamp = startTimestamp;
    _sentenceSegments = sentenceSegments;
    updateTimingPoints();
  }

  static Annotation get emptySnippet {
    return Annotation(
      startTimestamp: 0,
      sentenceSegments: [],
    );
  }

  Annotation copyWith({
    int? startTimestamp,
    List<SentenceSegment>? sentenceSegments,
  }) {
    return Annotation(
      startTimestamp: startTimestamp ?? this.startTimestamp,
      sentenceSegments: sentenceSegments ?? _sentenceSegments,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is LyricSnippet && runtimeType == other.runtimeType && sentence == other.sentence && startTimestamp == other.startTimestamp && listEquals(_sentenceSegments, other._sentenceSegments);

  @override
  int get hashCode => Object.hash(startTimestamp, Object.hashAll(_sentenceSegments));
}

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

class Vocalist {
  String name;
  int color;
  Vocalist({
    required this.name,
    required this.color,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final Vocalist otherVocalist = other as Vocalist;
    return name == otherVocalist.name && color == otherVocalist.color;
  }

  @override
  int get hashCode => Object.hash(name, color);

  Vocalist copyWith({
    String? name,
    int? color,
  }) {
    return Vocalist(
      name: name ?? this.name,
      color: color ?? this.color,
    );
  }
}

class VocalistCombination {
  List<String> vocalistNames;

  VocalistCombination(this.vocalistNames);

  @override
  bool operator ==(Object other) => identical(this, other) || other is VocalistCombination && runtimeType == other.runtimeType && listEquals(vocalistNames..sort(), other.vocalistNames..sort());

  @override
  int get hashCode => vocalistNames.fold(0, (prev, element) => 31 * prev + element.hashCode);
}

class SentenceSegment {
  String word;
  int duration;

  SentenceSegment(this.word, this.duration);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSegment otherSentenceSegments = other as SentenceSegment;
    return word == otherSentenceSegments.word && duration == otherSentenceSegments.duration;
  }

  @override
  int get hashCode => word.hashCode ^ duration.hashCode;

  @override
  String toString() {
    return 'SentenceSegment(wordLength: $word, wordDuration: $duration)';
  }

  SentenceSegment copyWith({String? word, int? duration}) {
    return SentenceSegment(
      word ?? this.word,
      duration ?? this.duration,
    );
  }
}

class TimingPoint {
  int charPosition;
  int seekPosition;

  TimingPoint(this.charPosition, this.seekPosition);

  static TimingPoint get emptyTimingPoint {
    return TimingPoint(-1, -1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TimingPoint otherSentenceSegments = other as TimingPoint;
    return charPosition == otherSentenceSegments.charPosition && seekPosition == otherSentenceSegments.seekPosition;
  }

  @override
  int get hashCode => charPosition.hashCode ^ seekPosition.hashCode;

  @override
  String toString() {
    return 'TimingPoint(charPosition: $charPosition, seekPosition: $seekPosition)';
  }

  TimingPoint copyWith({int? charPosition, int? seekPosition}) {
    return TimingPoint(
      charPosition ?? this.charPosition,
      seekPosition ?? this.seekPosition,
    );
  }
}

class PositionTypeInfo {
  PositionType type;
  int index;
  bool duplicate;
  PositionTypeInfo(this.type, this.index, this.duplicate);
}

class SegmentRange {
  int startIndex;
  int endIndex;
  SegmentRange(this.startIndex, this.endIndex);

  @override
  String toString() {
    return "${startIndex}<=>${endIndex}";
  }

  SegmentRange copyWith({int? startIndex, int? endIndex}) {
    return SegmentRange(
      startIndex ?? this.startIndex,
      endIndex ?? this.endIndex,
    );
  }
}

enum PositionType {
  timingPoint,
  sentenceSegment,
}

class TimingPointException implements Exception {
  final String message;
  TimingPointException(this.message);

  @override
  String toString() => 'TimingPointException: $message';
}
