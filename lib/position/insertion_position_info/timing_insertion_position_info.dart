import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';
import 'package:lyric_editor/position/timing_index.dart';

class TimingInsertionPositionInfo implements InsertionPositionInfo {
  TimingIndex timingIndex;
  bool duplicate;
  TimingInsertionPositionInfo(this.timingIndex, this.duplicate);

  TimingInsertionPositionInfo._privateConstructor(this.timingIndex, this.duplicate);
  static final TimingInsertionPositionInfo _empty = TimingInsertionPositionInfo._privateConstructor(TimingIndex.empty, false);
  static TimingInsertionPositionInfo get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TimingInsertionPositionInfo copyWith({
    TimingIndex? index,
    bool? duplicate,
  }) {
    return TimingInsertionPositionInfo(
      index ?? this.timingIndex,
      duplicate ?? this.duplicate,
    );
  }

  @override
  String toString() {
    return "InsertionPositionInfo: Timing at index $timingIndex";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TimingInsertionPositionInfo) {
      return false;
    }
    return timingIndex == other.timingIndex && duplicate == other.duplicate;
  }

  @override
  int get hashCode => timingIndex.hashCode ^ duplicate.hashCode;
}
