import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';

class Annotation {
  Timing timing;

  Annotation({
    required this.timing,
  });

  static Annotation get empty {
    return Annotation(
      timing: Timing.empty,
    );
  }

  bool isEmpty() {
    return timing.isEmpty;
  }

  String get sentence => timing.sentence;
  int get startTimestamp => timing.startTimestamp;
  int get endTimestamp => timing.endTimestamp;
  List<SentenceSegment> get sentenceSegments => timing.sentenceSegmentList.list;
  List<TimingPoint> get timingPoints => timing.timingPointList.list;

  Annotation copyWith({
    Timing? timing,
  }) {
    return Annotation(
      timing: timing ?? this.timing,
    );
  }

  @override
  String toString() {
    return "Annotation($timing)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Annotation) {
      return false;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return timing == other.timing;
  }

  @override
  int get hashCode => timing.hashCode;
}
