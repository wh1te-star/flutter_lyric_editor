import 'package:lyric_editor/position/seek_position_info/seek_position_info.dart';
import 'package:lyric_editor/position/timing_index.dart';

class TimingSeekPositionInfo implements SeekPositionInfo {
  TimingIndex timingIndex;
  TimingSeekPositionInfo(this.timingIndex);

  TimingSeekPositionInfo copyWith({
    TimingIndex? timingIndex,
  }) {
    return TimingSeekPositionInfo(
      timingIndex ?? this.timingIndex,
    );
  }

  @override
  String toString() {
    return "SeekPositionInfo: Timing at index $timingIndex";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TimingSeekPositionInfo) {
      return false;
    }
    return timingIndex == other.timingIndex;
  }

  @override
  int get hashCode => timingIndex.hashCode;
}
