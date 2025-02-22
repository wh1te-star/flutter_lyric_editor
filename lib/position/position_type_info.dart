class PositionTypeInfo {
  PositionType type;
  int index;
  bool duplicate;
  PositionTypeInfo(this.type, this.index, this.duplicate);

  PositionTypeInfo._privateConstructor(this.type, this.index, this.duplicate);
  static final PositionTypeInfo _empty = PositionTypeInfo._privateConstructor(PositionType.timingPoint, -1, false);
  static PositionTypeInfo get empty => _empty;
  bool get isEmpty => identical(this, _empty);

  PositionTypeInfo copyWith({
    PositionType? type,
    int? index,
    bool? duplicate,
  }) {
    return PositionTypeInfo(
      type ?? this.type,
      index ?? this.index,
      duplicate ?? this.duplicate,
    );
  }

  @override
  String toString() {
    return "$type at $index (duplicate: $duplicate)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! PositionTypeInfo) {
      return false;
    }
    return type == other.type && index == other.index && duplicate == other.duplicate;
  }

  @override
  int get hashCode => type.hashCode ^ index.hashCode ^ duplicate.hashCode;
}

enum PositionType {
  timingPoint,
  sentenceSegment;

  @override
  String toString() => name;
}
