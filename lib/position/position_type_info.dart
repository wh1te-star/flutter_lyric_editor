class InsertionPositionInfo {
  PositionType type;
  int index;
  bool duplicate;
  InsertionPositionInfo(this.type, this.index, this.duplicate);

  InsertionPositionInfo._privateConstructor(this.type, this.index, this.duplicate);
  static final InsertionPositionInfo _empty = InsertionPositionInfo._privateConstructor(PositionType.timingPoint, -1, false);
  static InsertionPositionInfo get empty => _empty;
  bool get isEmpty => identical(this, _empty);

  InsertionPositionInfo copyWith({
    PositionType? type,
    int? index,
    bool? duplicate,
  }) {
    return InsertionPositionInfo(
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
    if (other is! InsertionPositionInfo) {
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
