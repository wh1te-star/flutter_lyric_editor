class WordIndex implements Comparable<WordIndex> {
  final int index;

  WordIndex(this.index);

  WordIndex._privateConstructor(this.index);
  static final WordIndex _empty = WordIndex._privateConstructor(-1);
  static WordIndex get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  WordIndex copyWith({int? index}) {
    return WordIndex(
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
    if (other is! WordIndex) {
      return false;
    }
    return index == other.index;
  }

  @override
  int get hashCode => index.hashCode;

  WordIndex operator +(int index) => WordIndex(this.index + index);
  WordIndex operator -(int index) => WordIndex(this.index - index);

  @override
  int compareTo(WordIndex other) {
    return index.compareTo(other.index);
  }

  bool operator >(WordIndex other) => index > other.index;
  bool operator <(WordIndex other) => index < other.index;
  bool operator >=(WordIndex other) => index >= other.index;
  bool operator <=(WordIndex other) => index <= other.index;
}
