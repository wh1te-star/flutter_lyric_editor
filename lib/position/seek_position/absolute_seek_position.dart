import 'package:lyric_editor/position/seek_position/relative_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';

class AbsoluteSeekPosition extends SeekPosition implements Comparable<AbsoluteSeekPosition> {
  final int position;

  AbsoluteSeekPosition(this.position);

  AbsoluteSeekPosition._privateConstructor(this.position);
  static final AbsoluteSeekPosition _empty = AbsoluteSeekPosition._privateConstructor(-1);
  static AbsoluteSeekPosition get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  @override
  AbsoluteSeekPosition get absolute => this;
  RelativeSeekPosition toRelative(SeekPosition basePosition) {
    return RelativeSeekPosition(basePosition, durationUntil(basePosition).inMilliseconds);
  }

  Duration durationUntil(SeekPosition other) {
    return Duration(milliseconds: (other.absolute.position - position));
  }

  AbsoluteSeekPosition copyWith({int? position}) {
    return AbsoluteSeekPosition(
      position ?? this.position,
    );
  }

  @override
  String toString() {
    return "AbsoluteSeekPosition($position)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! AbsoluteSeekPosition) {
      return false;
    }
    return position == other.position;
  }

  @override
  int get hashCode => position.hashCode;

  @override
  AbsoluteSeekPosition operator +(Duration shift) => AbsoluteSeekPosition(position + shift.inMilliseconds);
  @override
  AbsoluteSeekPosition operator -(Duration shift) => AbsoluteSeekPosition(position - shift.inMilliseconds);

  @override
  int compareTo(AbsoluteSeekPosition other) {
    return position.compareTo(other.position);
  }

  bool operator >(AbsoluteSeekPosition other) => position > other.position;
  bool operator <(AbsoluteSeekPosition other) => position < other.position;
  bool operator >=(AbsoluteSeekPosition other) => position >= other.position;
  bool operator <=(AbsoluteSeekPosition other) => position <= other.position;
}
