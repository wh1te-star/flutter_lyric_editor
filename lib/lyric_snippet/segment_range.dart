class SegmentRange {
  int startIndex;
  int endIndex;
  SegmentRange(this.startIndex, this.endIndex);

  @override
  String toString() {
    return "$startIndex<=>$endIndex";
  }

  SegmentRange copyWith({int? startIndex, int? endIndex}) {
    return SegmentRange(
      startIndex ?? this.startIndex,
      endIndex ?? this.endIndex,
    );
  }
}
