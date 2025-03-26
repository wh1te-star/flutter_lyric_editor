class SegmentIndex implements Comparable<SegmentIndex> {
  final int index;

  SegmentIndex(this.index);

  SegmentIndex._privateConstructor(this.index);
  static final SegmentIndex _empty = SegmentIndex._privateConstructor(-1);
  static SegmentIndex get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  SegmentIndex copyWith({int? index}) {
    return SegmentIndex(
      index ?? this.index,
    );
  }

  @override
  String toString() {
    return "SegmentIndex: $index.";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! SegmentIndex) {
      return false;
    }
    return index == other.index;
  }

  @override
  int get hashCode => index.hashCode;

  SegmentIndex operator +(int index) => SegmentIndex(this.index + index);
  SegmentIndex operator -(int index) => SegmentIndex(this.index - index);

  @override
  int compareTo(SegmentIndex other) {
    return index.compareTo(other.index);
  }

  bool operator >(SegmentIndex other) => index > other.index;
  bool operator <(SegmentIndex other) => index < other.index;
  bool operator >=(SegmentIndex other) => index >= other.index;
  bool operator <=(SegmentIndex other) => index <= other.index;
}
