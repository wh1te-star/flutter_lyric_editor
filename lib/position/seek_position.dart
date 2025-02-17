class SeekPosition implements Comparable<SeekPosition> {
  final int position;

  SeekPosition(this.position) {
    if (!isEmpty) {
      assert(position >= 0);
    }
  }

  static final SeekPosition _empty = SeekPosition._internal(-1);
  static SeekPosition get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  SeekPosition._internal(this.position);

  SeekPosition copyWith({int? position}) {
    return SeekPosition(
      position ?? this.position,
    );
  }

  @override
  String toString() {
    return "SeekPosition: $position.";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! SeekPosition) {
      return false;
    }
    return position == other.position;
  }

  @override
  int get hashCode => position.hashCode;

  SeekPosition operator +(Duration shift) => SeekPosition(position + shift.inMilliseconds);
  SeekPosition operator -(Duration shift) => SeekPosition(position - shift.inMilliseconds);

  @override
  int compareTo(SeekPosition other) {
    return position.compareTo(other.position);
  }

  bool operator >(SeekPosition other) => position > other.position;
  bool operator <(SeekPosition other) => position < other.position;
  bool operator >=(SeekPosition other) => position >= other.position;
  bool operator <=(SeekPosition other) => position <= other.position;
}
