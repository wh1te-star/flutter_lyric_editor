class TimingPoint {
  int characterLength;
  int seekPosition;
  TimingPoint(this.characterLength, this.seekPosition);
}

class LyricSnippet {
  String id;
  String vocalist;
  String sentence;
  int startTimestamp;
  List<TimingPoint> timingPoints;

  LyricSnippet({
    required this.id,
    required this.vocalist,
    required this.sentence,
    required this.startTimestamp,
    required this.timingPoints,
  });
}
