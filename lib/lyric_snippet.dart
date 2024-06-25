class LyricSnippet {
  String vocalist;
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
    return startTimestamp +
        timingPoints.fold(0, (sum, current) => sum + current.wordDuration);
  }

  int charPosition(int index) {
    if (index < 0 || index >= timingPoints.length) {
      throw RangeError(
          'Index ${index} is out of bounds for timingPoints with length ${timingPoints.length}');
    }
    return timingPoints
        .take(index + 1)
        .fold(0, (sum, current) => sum + current.wordLength);
  }

  int seekPosition(int index) {
    if (index < 0 || index >= timingPoints.length) {
      throw RangeError(
          'Index ${index} is out of bounds for timingPoints with length ${timingPoints.length}');
    }
    return timingPoints
        .take(index + 1)
        .fold(0, (sum, current) => sum + current.wordDuration);
  }

  set id(LyricSnippetID id) {
    vocalist = id.vocalist;
    index = id.index;
  }
}

class TimingPoint {
  int wordLength;
  int wordDuration;
  TimingPoint(this.wordLength, this.wordDuration);
}

class LyricSnippetID {
  String vocalist;
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
