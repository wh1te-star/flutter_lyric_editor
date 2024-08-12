import 'package:flutter/foundation.dart';

class LyricSnippet {
  Vocalist vocalist;
  int index;
  String sentence;
  int startTimestamp;
  List<TimingPoint> timingPoints;
  late List<TimingPoint> accumulatedTimingPoints;

  LyricSnippet({
    required this.vocalist,
    required this.index,
    required this.sentence,
    required this.startTimestamp,
    required this.timingPoints,
  });

  LyricSnippetID get id => LyricSnippetID(vocalist, index);

  int get endTimestamp {
    return startTimestamp + timingPoints.fold(0, (sum, current) => sum + current.wordDuration);
  }

  int charPosition(int index) {
    if (index < 0 || index >= timingPoints.length) {
      throw RangeError('Index ${index} is out of bounds for timingPoints with length ${timingPoints.length}');
    }
    return timingPoints.take(index + 1).fold(0, (sum, current) => sum + current.wordLength);
  }

  int seekPosition(int index) {
    if (index < 0 || index >= timingPoints.length) {
      throw RangeError('Index ${index} is out of bounds for timingPoints with length ${timingPoints.length}');
    }
    return timingPoints.take(index + 1).fold(0, (sum, current) => sum + current.wordDuration);
  }

  set id(LyricSnippetID id) {
    vocalist = id.vocalist;
    index = id.index;
  }

  LyricSnippet copyWith({
    Vocalist? vocalist,
    int? index,
    String? sentence,
    int? startTimestamp,
    List<TimingPoint>? timingPoints,
  }) {
    return LyricSnippet(
      vocalist: vocalist ?? this.vocalist,
      index: index ?? this.index,
      sentence: sentence ?? this.sentence,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      timingPoints: timingPoints != null ? List<TimingPoint>.from(timingPoints) : List<TimingPoint>.from(this.timingPoints),
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is LyricSnippet && runtimeType == other.runtimeType && vocalist == other.vocalist && index == other.index && sentence == other.sentence && startTimestamp == other.startTimestamp && listEquals(timingPoints, other.timingPoints);

  @override
  int get hashCode => vocalist.hashCode ^ index.hashCode ^ sentence.hashCode ^ startTimestamp.hashCode ^ timingPoints.hashCode;
}

class Vocalist {
  String name;
  int color;
  Vocalist(this.name, this.color);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final Vocalist otherVocalist = other as Vocalist;
    return name == otherVocalist.name && color == otherVocalist.color;
  }

  @override
  int get hashCode => name.hashCode ^ color.hashCode;
}

class VocalistCombination {
  List<String> vocalistNames;

  VocalistCombination(this.vocalistNames);

  @override
  bool operator ==(Object other) => identical(this, other) || other is VocalistCombination && runtimeType == other.runtimeType && listEquals(vocalistNames..sort(), other.vocalistNames..sort());

  @override
  int get hashCode => vocalistNames.fold(0, (prev, element) => 31 * prev + element.hashCode);
}

class TimingPoint {
  int wordLength;
  int wordDuration;

  TimingPoint(this.wordLength, this.wordDuration);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TimingPoint otherTimingPoint = other as TimingPoint;
    return wordLength == otherTimingPoint.wordLength && wordDuration == otherTimingPoint.wordDuration;
  }

  @override
  int get hashCode => wordLength.hashCode ^ wordDuration.hashCode;
}

class LyricSnippetID {
  Vocalist vocalist;
  int index;
  LyricSnippetID(this.vocalist, this.index);

  @override
  bool operator ==(Object other) {
    if (other is LyricSnippetID) {
      return vocalist == other.vocalist && index == other.index;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => vocalist.hashCode ^ index.hashCode;

  @override
  String toString() => 'LyricSnippetID($vocalist, $index)';
}
