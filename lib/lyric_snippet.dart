class TimingPoint {
  int characterPosition;
  int seekPosition;
  TimingPoint(this.characterPosition, this.seekPosition);
}

class LyricSnippet {
  String vocalist;
  String sentence;
  int startTimestamp;
  int endTimestamp;
  List<TimingPoint> timingPoints;

  LyricSnippet({
    required this.vocalist,
    required this.sentence,
    required this.startTimestamp,
    required this.endTimestamp,
    required this.timingPoints,
  });
}
