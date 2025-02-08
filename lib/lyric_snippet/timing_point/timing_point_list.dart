import 'dart:ffi';

import 'package:collection/collection.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';

class TimingPointList {
  static const charPositionDuplicationAllowed = 2;
  static const seekPositionDuplicationAllowed = 1;
  final List<TimingPoint> list;

  TimingPointList(this.list) {
    assert(isCharPositionOrdered());
    assert(isSeekPositionOrdered());
    assert(isCharPositionDuplicationAllowed());
    assert(isSeekPositionDuplicationAllowed());
  }

  bool isCharPositionOrdered() {
    return list.map((TimingPoint timingPoint) {
      return timingPoint.charPosition;
    }).isSorted((int left, int right) => left.compareTo(right));
  }

  bool isSeekPositionOrdered() {
    return list.map((TimingPoint timingPoint) {
      return timingPoint.seekPosition;
    }).isSorted((int left, int right) => left.compareTo(right));
  }

  bool isCharPositionDuplicationAllowed() {
    return groupBy(
      list,
      (TimingPoint timingPoint) => timingPoint.charPosition,
    ).values.every((List<TimingPoint> group) => group.length <= charPositionDuplicationAllowed);
  }

  bool isSeekPositionDuplicationAllowed() {
    return groupBy(
      list,
      (TimingPoint timingPoint) => timingPoint.seekPosition,
    ).values.every((List<TimingPoint> group) => group.length <= seekPositionDuplicationAllowed);
  }

  TimingPointList copyWith({
    TimingPointList? timingPointList,
  }) {
    return TimingPointList(
      timingPointList?.list.map((TimingPoint timingPoint) => timingPoint.copyWith()).toList() ?? list,
    );
  }

  @override
  String toString() {
    return list.join("\n");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TimingPointList) return false;
    if (list.length != other.list.length) return false;
    return list.asMap().entries.every((MapEntry<int, TimingPoint> entry) {
      int index = entry.key;
      TimingPoint timingPoint = entry.value;
      return timingPoint == other.list[index];
    });
  }

  @override
  int get hashCode => const ListEquality().hash(list);
}
