import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment_list.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';

class TimingPointList {
  static const charPositionDuplicationAllowed = 2;
  static const seekPositionDuplicationAllowed = 1;
  final List<TimingPoint> _list;

  TimingPointList(this._list) {
    assert(isCharPositionOrdered());
    assert(isSeekPositionOrdered());
    assert(isCharPositionDuplicationAllowed());
    assert(isSeekPositionDuplicationAllowed());
  }

  List<TimingPoint> get list => _list;

  bool isCharPositionOrdered() {
    return _list.map((TimingPoint timingPoint) {
      return timingPoint.charPosition;
    }).isSorted((InsertionPosition left, InsertionPosition right) => left.compareTo(right));
  }

  bool isSeekPositionOrdered() {
    return _list.map((TimingPoint timingPoint) {
      return timingPoint.seekPosition;
    }).isSorted((SeekPosition left, SeekPosition right) => left.compareTo(right));
  }

  bool isCharPositionDuplicationAllowed() {
    return groupBy(
      _list,
      (TimingPoint timingPoint) => timingPoint.charPosition,
    ).values.every((List<TimingPoint> group) => group.length <= charPositionDuplicationAllowed);
  }

  bool isSeekPositionDuplicationAllowed() {
    return groupBy(
      _list,
      (TimingPoint timingPoint) => timingPoint.seekPosition,
    ).values.every((List<TimingPoint> group) => group.length <= seekPositionDuplicationAllowed);
  }

  static TimingPointList get empty => TimingPointList([]);
  bool get isEmpty => list.isEmpty;

  int get length => list.length;
  TimingPoint operator [](int index) => list[index];
  void operator []=(int index, TimingPoint value) {
    list[index] = value;
  }

  SentenceSegmentList toSentenceSegmentList(String sentence) {
    List<SentenceSegment> sentenceSegments = [];
    List<TimingPoint> timingPoints = list;
    for (int index = 0; index < timingPoints.length - 1; index++) {
      String word = sentence.substring(
        timingPoints[index].charPosition.position,
        timingPoints[index + 1].charPosition.position,
      );
      Duration duration = Duration(
        milliseconds: timingPoints[index + 1].seekPosition.position - timingPoints[index].seekPosition.position,
      );
      sentenceSegments.add(SentenceSegment(word, duration));
    }

    return SentenceSegmentList(sentenceSegments);
  }

  TimingPointList copyWith({
    TimingPointList? timingPointList,
  }) {
    return TimingPointList(
      timingPointList?._list.map((TimingPoint timingPoint) => timingPoint.copyWith()).toList() ?? _list,
    );
  }

  @override
  String toString() {
    return _list.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimingPointList) return false;
    if (_list.length != other._list.length) return false;
    return _list.asMap().entries.every((MapEntry<int, TimingPoint> entry) {
      int index = entry.key;
      TimingPoint timingPoint = entry.value;
      return timingPoint == other._list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(_list);
}
