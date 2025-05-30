import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/empty_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';

class RelativeSeekPosition extends SeekPosition implements Comparable<RelativeSeekPosition> {
  final SeekPosition basePosition;
  final int shiftDuration;

  RelativeSeekPosition(this.basePosition, this.shiftDuration);

  RelativeSeekPosition._privateConstructor(this.basePosition, this.shiftDuration);
  static final RelativeSeekPosition _empty = RelativeSeekPosition._privateConstructor(EmptySeekPosition(), -1);
  static RelativeSeekPosition get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  AbsoluteSeekPosition get absolute => basePosition.absolute + Duration(milliseconds: shiftDuration);
  AbsoluteSeekPosition get relative => AbsoluteSeekPosition(shiftDuration);

  RelativeSeekPosition copyWith({SeekPosition? basePosition, int? shiftDuration}) {
    return RelativeSeekPosition(
      basePosition ?? this.basePosition,
      shiftDuration ?? this.shiftDuration,
    );
  }

  @override
  String toString() {
    return "RelativeSeekPosition($basePosition, $shiftDuration)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RelativeSeekPosition) {
      return false;
    }
    return basePosition == other.basePosition && shiftDuration == other.shiftDuration;
  }

  @override
  int get hashCode => shiftDuration.hashCode;

  @override
  RelativeSeekPosition operator +(Duration shift) => RelativeSeekPosition(basePosition, shiftDuration + shift.inMilliseconds);
  @override
  RelativeSeekPosition operator -(Duration shift) => RelativeSeekPosition(basePosition, shiftDuration - shift.inMilliseconds);

  @override
  int compareTo(RelativeSeekPosition other) {
    return shiftDuration.compareTo(other.shiftDuration);
  }

  bool operator >(RelativeSeekPosition other) => absolute > other.absolute;
  bool operator <(RelativeSeekPosition other) => absolute < other.absolute;
  bool operator >=(RelativeSeekPosition other) => absolute >= other.absolute;
  bool operator <=(RelativeSeekPosition other) => absolute <= other.absolute;
}
