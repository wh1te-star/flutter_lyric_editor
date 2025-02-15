class CharacterPosition {
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
}
