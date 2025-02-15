class InsertionPosition {
  int position;

  InsertionPosition(this.position) {
    assert(position >= 0);
  }

  InsertionPosition copyWith({int? position}) {
    return InsertionPosition(
      position ?? this.position,
    );
  }

  @override
  String toString() {
    return "InsertionPosition: $position.";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! InsertionPosition) {
      return false;
    }
    return position == other.position;
  }

  @override
  int get hashCode => position.hashCode;
}
