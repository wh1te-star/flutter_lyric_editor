class InsertionPosition implements Comparable<InsertionPosition> {
  int position;

  InsertionPosition(this.position) {
    if (!isEmpty) {
      assert(position >= 0);
    }
  }

  InsertionPosition._privateConstructor(this.position);
  static final InsertionPosition _empty = InsertionPosition._privateConstructor(-1);
  static InsertionPosition get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

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

  InsertionPosition operator +(int shift) => InsertionPosition(position + shift);
  InsertionPosition operator -(int shift) => InsertionPosition(position - shift);

  @override
  int compareTo(InsertionPosition other) {
    return position.compareTo(other.position);
  }

  bool operator >(InsertionPosition other) => position > other.position;
  bool operator <(InsertionPosition other) => position < other.position;
  bool operator >=(InsertionPosition other) => position >= other.position;
  bool operator <=(InsertionPosition other) => position <= other.position;
}
