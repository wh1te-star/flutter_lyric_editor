import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/timing_point_index.dart';

class TimingPointInsertionPositionInfo implements InsertionPositionInfo{
  TimingPointIndex index;
  bool duplicate;
  TimingPointInsertionPositionInfo(this.index, this.duplicate);

  TimingPointInsertionPositionInfo._privateConstructor(this.index, this.duplicate);
  static final TimingPointInsertionPositionInfo _empty = TimingPointInsertionPositionInfo._privateConstructor(TimingPointIndex.empty, false);
  static TimingPointInsertionPositionInfo get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TimingPointInsertionPositionInfo copyWith({
    TimingPointIndex? index,
    bool? duplicate,
  }) {
    return TimingPointInsertionPositionInfo(
      index ?? this.index,
      duplicate ?? this.duplicate,
    );
  }

  @override
  String toString() {
    return "InsertionPositionInfo: TimingPoint at index $index";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TimingPointInsertionPositionInfo) {
      return false;
    }
    return index == other.index && duplicate == other.duplicate;
  }

  @override
  int get hashCode => index.hashCode ^ duplicate.hashCode;
}