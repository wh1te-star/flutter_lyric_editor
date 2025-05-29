import 'package:lyric_editor/position/seek_position/seek_position_base.dart';

class RelativeSeekPosition implements SeekPositionBase {
  final SeekPositionBase base;
  final int shift; // The offset in milliseconds from the base

  /// Creates a RelativeSeekPosition.
  /// The [base] can be either an [AbsoluteSeekPosition] or another [RelativeSeekPosition].
  /// The [shift] is the offset in milliseconds from the [base].
  const RelativeSeekPosition(this.base, this.shift);

  /// Returns the absolute seek position by applying the shift to the base's absolute position.
  @override
  AbsoluteSeekPosition get absolute => AbsoluteSeekPosition(base.absolute.position + shift);

  RelativeSeekPosition copyWith({SeekPositionBase? base, int? shift}) {
    return RelativeSeekPosition(
      base ?? this.base,
      shift ?? this.shift,
    );
  }

  @override
  String toString() {
    return "RelativeSeekPosition: shift $shift from base: ${base.toString()}.";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! RelativeSeekPosition) {
      return false;
    }
    return base == other.base && shift == other.shift;
  }

  @override
  int get hashCode => Object.hash(base, shift);
}