import 'package:flutter/foundation.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';

class LyricSnippet {
  VocalistID vocalistID;
  String sentence;
  int startTimestamp;
  List<SentenceSegment> _sentenceSegments;

  LyricSnippet({
    required this.vocalistID,
    required this.sentence,
    required this.startTimestamp,
    required List<SentenceSegment> sentenceSegments,
  }) : _sentenceSegments = sentenceSegments {
    updateTimingPoints();
  }

  List<TimingPoint> _timingPoints = [];

  List<SentenceSegment> get sentenceSegments => _sentenceSegments;
  set sentenceSegments(List<SentenceSegment> segments) {
    _sentenceSegments.clear();
    _sentenceSegments.addAll(segments);
    updateTimingPoints();
  }

  List<TimingPoint> get timingPoints => _timingPoints;

  int get endTimestamp {
    return startTimestamp + _timingPoints.last.seekPosition;
  }

  String segmentWord(int index) {
    return sentence.substring(
      timingPoints[index].charPosition,
      timingPoints[index + 1].charPosition,
    );
  }

  void updateTimingPoints() {
    List<TimingPoint> newTimingPoints = [];
    int charPosition = 0;
    int seekPosition = 0;
    for (var segment in sentenceSegments) {
      newTimingPoints.add(TimingPoint(charPosition, seekPosition));
      charPosition += segment.wordLength;
      seekPosition += segment.wordDuration;
    }
    newTimingPoints.add(TimingPoint(charPosition, seekPosition));

    _timingPoints = newTimingPoints;
  }

  void updateSentenceSegments() {
    List<SentenceSegment> newSentenceSegments = [];
    for (int index = 0; index < timingPoints.length - 1; index++) {
      int wordLength = timingPoints[index + 1].charPosition - timingPoints[index].charPosition;
      int wordDuration = timingPoints[index + 1].seekPosition - timingPoints[index].seekPosition;
      newSentenceSegments.add(SentenceSegment(wordLength, wordDuration));
    }

    _sentenceSegments = newSentenceSegments;
  }

  static LyricSnippet get emptySnippet {
    return LyricSnippet(
      vocalistID: VocalistID(0),
      sentence: "",
      startTimestamp: 0,
      sentenceSegments: [],
    );
  }

  int getSeekPositionSegmentIndex(int seekPosition) {
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

  PositionTypeInfo getCharPositionIndex(int charPosition) {
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

  LyricSnippet copyWith({
    VocalistID? vocalistID,
    String? sentence,
    int? startTimestamp,
    List<SentenceSegment>? sentenceSegments,
  }) {
    return LyricSnippet(
      vocalistID: vocalistID ?? this.vocalistID,
      sentence: sentence ?? this.sentence,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      sentenceSegments: sentenceSegments != null ? sentenceSegments.map((segment) => SentenceSegment(segment.wordLength, segment.wordDuration)).toList() : _sentenceSegments.map((segment) => SentenceSegment(segment.wordLength, segment.wordDuration)).toList(),
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is LyricSnippet && runtimeType == other.runtimeType && vocalistID == other.vocalistID && sentence == other.sentence && startTimestamp == other.startTimestamp && listEquals(_sentenceSegments, other._sentenceSegments);

  @override
  int get hashCode => vocalistID.hashCode ^ sentence.hashCode ^ startTimestamp.hashCode ^ _sentenceSegments.hashCode;
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
  int get hashCode => name.hashCode ^ color.hashCode;

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
  int wordLength;
  int wordDuration;

  SentenceSegment(this.wordLength, this.wordDuration);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final SentenceSegment otherSentenceSegments = other as SentenceSegment;
    return wordLength == otherSentenceSegments.wordLength && wordDuration == otherSentenceSegments.wordDuration;
  }

  @override
  int get hashCode => wordLength.hashCode ^ wordDuration.hashCode;

  @override
  String toString() {
    return 'SentenceSegment(wordLength: $wordLength, wordDuration: $wordDuration)';
  }
}

class TimingPoint {
  int charPosition;
  int seekPosition;

  TimingPoint(this.charPosition, this.seekPosition);

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
}

class PositionTypeInfo {
  PositionType type;
  int index;
  bool duplicate;
  PositionTypeInfo(this.type, this.index, this.duplicate);
}

enum PositionType {
  timingPoint,
  sentenceSegment,
}
