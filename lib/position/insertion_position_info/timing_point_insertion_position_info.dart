import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';

class TimingPointInsertionPositionInfo implements InsertionPositionInfo{
  TimingPointIndex index;
  bool duplicate;
  TimingPointInsertionPositionInfo(this.index, this.duplicate);

  TimingPointInsertionPositionInfo._privateConstructor(this.index, this.duplicate);
  static final TimingPointInsertionPositionInfo _empty = TimingPointInsertionPositionInfo._privateConstructor();
  static TimingPointInsertionPositionInfo get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TimingPointInsertionPositionInfo copyWith({
    PositionType? type,
    int? index,
    bool? duplicate,
  }) {
    return TimingPointInsertionPositionInfo(
      type ?? this.type,
      index ?? this.index,
      duplicate ?? this.duplicate,
    );
  }

  @override
  String toString() {
    return "$type at $index (duplicate: $duplicate)";
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