class SeekPosition implements Comparable<SeekPosition> {
  int position;

  SeekPosition(this.position) {
    if (!isEmpty) {
      assert(position >= 0);
    }
  }

  static SeekPosition get empty => SeekPosition(-1);
  bool get isEmpty => this == empty;

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

  @override
  int compareTo(SeekPosition other) {
    return position.compareTo(other.position);
  }

  bool operator >(SeekPosition other) => position > other.position;
  bool operator <(SeekPosition other) => position < other.position;
  bool operator >=(SeekPosition other) => position >= other.position;
  bool operator <=(SeekPosition other) => position <= other.position;
}
