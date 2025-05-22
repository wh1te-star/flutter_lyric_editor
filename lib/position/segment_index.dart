class SentenceSegmentIndex implements Comparable<SentenceSegmentIndex> {
  final int index;

  SentenceSegmentIndex(this.index);

  SentenceSegmentIndex._privateConstructor(this.index);
  static final SentenceSegmentIndex _empty = SentenceSegmentIndex._privateConstructor(-1);
  static SentenceSegmentIndex get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  SentenceSegmentIndex copyWith({int? index}) {
    return SentenceSegmentIndex(
      index ?? this.index,
    );
  }

  @override
  String toString() {
    return "SegmentIndex: $index";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! SentenceSegmentIndex) {
      return false;
    }
    return index == other.index;
  }

  @override
  int get hashCode => index.hashCode;

  SentenceSegmentIndex operator +(int index) => SentenceSegmentIndex(this.index + index);
  SentenceSegmentIndex operator -(int index) => SentenceSegmentIndex(this.index - index);

  @override
  int compareTo(SentenceSegmentIndex other) {
    return index.compareTo(other.index);
  }

  bool operator >(SentenceSegmentIndex other) => index > other.index;
  bool operator <(SentenceSegmentIndex other) => index < other.index;
  bool operator >=(SentenceSegmentIndex other) => index >= other.index;
  bool operator <=(SentenceSegmentIndex other) => index <= other.index;
}
