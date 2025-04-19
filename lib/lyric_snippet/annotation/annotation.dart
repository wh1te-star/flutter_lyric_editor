import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';

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
  SeekPosition get startTimestamp => timing.startTimestamp;
  SeekPosition get endTimestamp => timing.endTimestamp;
  List<SentenceSegment> get sentenceSegments => timing.sentenceSegmentList.list;
  List<TimingPoint> get timingPoints => timing.timingPointList.list;
  SentenceSegmentIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) => timing.getSegmentIndexFromSeekPosition(seekPosition);
  SentenceSegmentIndex getSegmentIndexFromInsertionPosition(InsertionPosition insertionPosition) => timing.getSegmentIndexFromInsertionPosition(insertionPosition);
  SentenceSegmentList getSentenceSegmentList(SegmentRange segmentRange) => timing.getSentenceSegmentList(segmentRange);

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
