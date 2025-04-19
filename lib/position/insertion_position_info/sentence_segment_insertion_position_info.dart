import 'package:lyric_editor/position/insertion_position_info/insertion_position_info.dart';

class SentenceSegmentInsertionPositionInfo implements InsertionPositionInfo{
  int index;
  bool duplicate;
  SentenceSegmentInsertionPositionInfo(this.index, this.duplicate);

  InsertionPositionInfo._privateConstructor(this.type, this.index, this.duplicate);
  static final InsertionPositionInfo _empty = InsertionPositionInfo._privateConstructor(PositionType.timingPoint, -1, false);
  static InsertionPositionInfo get empty => _empty;
  bool get isEmpty => identical(this, _empty);

  InsertionPositionInfo copyWith({
    PositionType? type,
    int? index,
    bool? duplicate,
  }) {
    return InsertionPositionInfo(
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
    if (other is! SentenceSegmentInsertionPositionInfo) {
      return false;
    }
    return index == other.index && duplicate == other.duplicate;
  }

  @override
  int get hashCode => index.hashCode ^ duplicate.hashCode;
}