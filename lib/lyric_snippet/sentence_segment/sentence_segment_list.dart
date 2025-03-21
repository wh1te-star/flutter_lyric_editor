import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point_list.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';

class SentenceSegmentList {
  final List<SentenceSegment> _list;

  SentenceSegmentList(this._list) {
    assert(!has2ConseqentEmpty());
  }

  List<SentenceSegment> get list => _list;

  static SentenceSegmentList get empty => SentenceSegmentList([]);
  bool get isEmpty => list.isEmpty;

  SentenceSegment operator [](int index) => list[index];
  void operator []=(int index, SentenceSegment value) {
    list[index] = value;
  }

  String get sentence {
    return _list.map((SentenceSegment segment) {
      return segment.word;
    }).join("");
  }

  int get segmentLength => list.length;
  int get charLength {
    return list.fold(0, (total, sentenceSegment) {
      return total + sentenceSegment.word.length;
    });
  }

  bool has2ConseqentEmpty() {
    for (int index = 0; index < _list.length - 1; index++) {
      if (_list[index].word == "" && _list[index + 1].word == "") {
        return true;
      }
    }
    return false;
  }

  TimingPointList toTimingPointList() {
    List<TimingPoint> timingPoints = [];
    InsertionPosition insertionPosition = InsertionPosition(0);
    SeekPosition seekPosition = SeekPosition(0);
    for (SentenceSegment sentenceSegment in list) {
      timingPoints.add(TimingPoint(insertionPosition, seekPosition));

      insertionPosition += sentenceSegment.word.length;
      seekPosition += sentenceSegment.duration;
    }
    timingPoints.add(TimingPoint(insertionPosition, seekPosition));

    return TimingPointList(timingPoints);
  }

  SentenceSegmentList copyWith({
    SentenceSegmentList? sentenceSegmentList,
  }) {
    return SentenceSegmentList(
      sentenceSegmentList?._list.map((SentenceSegment sentenceSegment) => sentenceSegment.copyWith()).toList() ?? _list,
    );
  }

  @override
  String toString() {
    return _list.join("\n");
  }

  SentenceSegmentList operator +(SentenceSegmentList other) {
    List<SentenceSegment> combinedList = [..._list, ...other._list];
    return SentenceSegmentList(combinedList);
  }

  SentenceSegmentList addSegment(SentenceSegment segment) {
    List<SentenceSegment> combinedList = [..._list, segment];
    return SentenceSegmentList(combinedList);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SentenceSegmentList) return false;
    if (_list.length != other._list.length) return false;
    return _list.asMap().entries.every((MapEntry<int, SentenceSegment> entry) {
      int index = entry.key;
      SentenceSegment timingPoint = entry.value;
      return timingPoint == other._list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(_list);
}
