import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timeline.dart';
import 'package:lyric_editor/lyric_data/timing_point/timing_point.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';

class Annotation {
  Timeline timing;

  Annotation({
    required this.timing,
  });

  static Annotation get empty {
    return Annotation(
      timing: Timeline.empty,
    );
  }

  bool isEmpty() {
    return timing.isEmpty;
  }

  String get sentence => timing.sentence;
  SeekPosition get startTimestamp => timing.startTime;
  SeekPosition get endTimestamp => timing.endTimestamp;
  List<Word> get sentenceSegments => timing.wordList.list;
  List<TimingPoint> get timingPoints => timing.timingList.list;
  WordIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) => timing.getSegmentIndexFromSeekPosition(seekPosition);
  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) => timing.getInsertionPositionInfo(insertionPosition);
  WordList getSentenceSegmentList(Phrase segmentRange) => timing.getSentenceSegmentList(segmentRange);

  Annotation copyWith({
    Timeline? timing,
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
