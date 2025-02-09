import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing_object.dart';

class Annotation {
  Timing timing;

  Annotation({
    required this.timing,
  });

  static Annotation get emptyAnnotation {
    return Annotation(
      timing: Timing(
        startTimestamp: 0,
        sentenceSegmentList: SentenceSegmentList([]),
      ),
    );
  }

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
