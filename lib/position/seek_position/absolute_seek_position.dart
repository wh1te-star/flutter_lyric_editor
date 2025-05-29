class AbsoluteSeekPosition implements Comparable<AbsoluteSeekPosition> {
  final int position;

  const AbsoluteSeekPosition(this.position);

  // Private constructor for internal use, e.g., for 'empty'
  const AbsoluteSeekPosition._privateConstructor(this.position);
  static const AbsoluteSeekPosition _empty = AbsoluteSeekPosition._privateConstructor(-1);
  static AbsoluteSeekPosition get empty => _empty;
  bool get isEmpty => identical(this, _empty) || position < 0; // Consider negative positions as empty/invalid

  AbsoluteSeekPosition copyWith({int? position}) {
    return AbsoluteSeekPosition(
      position ?? this.position,
    );
  }

  @override
  String toString() {
    return "AbsoluteSeekPosition: $position.";
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

  AbsoluteSeekPosition operator +(Duration shift) => AbsoluteSeekPosition(position + shift.inMilliseconds);
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