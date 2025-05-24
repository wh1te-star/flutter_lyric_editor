class CaretPosition implements Comparable<CaretPosition> {
  int position;

  CaretPosition(this.position) {
    if (!isEmpty) {
      assert(position >= 0);
    }
  }

  CaretPosition._privateConstructor(this.position);
  static final CaretPosition _empty = CaretPosition._privateConstructor(-1);
  static CaretPosition get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  CaretPosition copyWith({int? position}) {
    return CaretPosition(
      position ?? this.position,
    );
  }

  @override
  String toString() {
    return "CaretPosition: $position.";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! CaretPosition) {
      return false;
    }
    return position == other.position;
  }

  @override
  int get hashCode => position.hashCode;

  CaretPosition operator +(int shift) => CaretPosition(position + shift);
  CaretPosition operator -(int shift) => CaretPosition(position - shift);

  @override
  int compareTo(CaretPosition other) {
    return position.compareTo(other.position);
  }

  bool operator >(CaretPosition other) => position > other.position;
  bool operator <(CaretPosition other) => position < other.position;
  bool operator >=(CaretPosition other) => position >= other.position;
  bool operator <=(CaretPosition other) => position <= other.position;
}
