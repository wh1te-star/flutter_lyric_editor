import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/lyric_data/word/word_list.dart';
import 'package:lyric_editor/lyric_data/timeline.dart';
import 'package:lyric_editor/lyric_data/timing_point/timing_point.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/position/segment_range.dart';

class Reading {
  Timeline timeline;

  Reading({
    required this.timeline,
  });

  static Reading get empty {
    return Reading(
      timeline: Timeline.empty,
    );
  }

  bool isEmpty() {
    return timeline.isEmpty;
  }

  String get sentence => timeline.sentence;
  SeekPosition get startTimestamp => timeline.startTime;
  SeekPosition get endTimestamp => timeline.endTimestamp;
  List<Word> get sentenceSegments => timeline.wordList.list;
  List<TimingPoint> get timingPoints => timeline.timingList.list;
  WordIndex getSegmentIndexFromSeekPosition(SeekPosition seekPosition) => timeline.getSegmentIndexFromSeekPosition(seekPosition);
  InsertionPositionInfo? getInsertionPositionInfo(InsertionPosition insertionPosition) => timeline.getInsertionPositionInfo(insertionPosition);
  WordList getSentenceSegmentList(Phrase segmentRange) => timeline.getSentenceSegmentList(segmentRange);

  Reading copyWith({
    Timeline? timing,
  }) {
    return Reading(
      timeline: timing ?? this.timeline,
    );
  }

  @override
  String toString() {
    return "Annotation($timeline)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Reading) {
      return false;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return timeline == other.timeline;
  }

  @override
  int get hashCode => timeline.hashCode;
}
