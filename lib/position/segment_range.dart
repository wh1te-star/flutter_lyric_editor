class SegmentRange {
  int startIndex;
  int endIndex;
  SegmentRange(this.startIndex, this.endIndex) {
    if(!isEmpty){
    assert(startIndex >= 0);
    assert(endIndex >= 0);
    }
  }

  SegmentRange._privateConstructor(this.startIndex, this.endIndex);
  static final SegmentRange _empty = SegmentRange._privateConstructor(-1, -1);
  static SegmentRange get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  SegmentRange copyWith({int? startIndex, int? endIndex}) {
    return SegmentRange(
      startIndex ?? this.startIndex,
      endIndex ?? this.endIndex,
    );
  }

  @override
  String toString() {
    return "$startIndex<=>$endIndex";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! SegmentRange) {
      return false;
    }
    return startIndex == other.startIndex && endIndex == other.endIndex;
  }

  @override
  int get hashCode => startIndex.hashCode ^ endIndex.hashCode;
}
