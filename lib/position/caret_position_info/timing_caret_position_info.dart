import 'package:lyric_editor/position/caret_position_info/caret_position_info.dart';
import 'package:lyric_editor/position/timing_index.dart';

class TimingCaretPositionInfo implements CaretPositionInfo {
  TimingIndex timingIndex;
  bool duplicate;
  TimingCaretPositionInfo(this.timingIndex, this.duplicate);

  TimingCaretPositionInfo copyWith({
    TimingIndex? timingIndex,
    bool? duplicate,
  }) {
    return TimingCaretPositionInfo(
      timingIndex ?? this.timingIndex,
      duplicate ?? this.duplicate,
    );
  }

  @override
  String toString() {
    return "CaretPositionInfo: Timing at index $timingIndex";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TimingCaretPositionInfo) {
      return false;
    }
    return timingIndex == other.timingIndex && duplicate == other.duplicate;
  }

  @override
  int get hashCode => timingIndex.hashCode ^ duplicate.hashCode;
}
