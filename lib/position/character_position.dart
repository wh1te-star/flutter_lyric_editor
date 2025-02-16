class CharacterPosition implements Comparable<CharacterPosition> {
  int position;

  CharacterPosition(this.position) {
    if (!isEmpty) {
      assert(position >= 0);
    }
  }

  static CharacterPosition get empty => CharacterPosition(-1);
  bool get isEmpty => this == empty;

  CharacterPosition copyWith({int? position}) {
    return CharacterPosition(
      position ?? this.position,
    );
  }

  @override
  String toString() {
    return "CharPosition: $position.";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! CharacterPosition) {
      return false;
    }
    return position == other.position;
  }

  @override
  int get hashCode => position.hashCode;

  CharacterPosition operator +(CharacterPosition other) {
    return CharacterPosition(position + other.position);
  }

  CharacterPosition operator -(CharacterPosition other) {
    return CharacterPosition(position - other.position);
  }

  @override
  int compareTo(CharacterPosition other) {
    return position.compareTo(other.position);
  }

  bool operator >(CharacterPosition other) => position > other.position;
  bool operator <(CharacterPosition other) => position < other.position;
  bool operator >=(CharacterPosition other) => position >= other.position;
  bool operator <=(CharacterPosition other) => position <= other.position;
}
