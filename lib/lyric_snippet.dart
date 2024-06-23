class LyricSnippet {
  String vocalist;
  int index;
  String sentence;
  int startTimestamp;
  List<TimingPoint> timingPoints;

  LyricSnippet({
    required this.vocalist,
    required this.index,
    required this.sentence,
    required this.startTimestamp,
    required this.timingPoints,
  });

  LyricSnippetID get id => LyricSnippetID(vocalist, index);
}

class TimingPoint {
  int characterLength;
  int seekPosition;
  TimingPoint(this.characterLength, this.seekPosition);
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
