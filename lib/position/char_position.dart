class CharPosition {
  int position;

  CharPosition(this.position) {
    assert(position >= 0);
  }

  CharPosition copyWith({int? position}) {
    return CharPosition(
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
    if (other is! CharPosition) {
      return false;
    }
    return position == other.position;
  }

  @override
  int get hashCode => position.hashCode;
}
