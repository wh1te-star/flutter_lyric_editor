class TimingIndex implements Comparable<TimingIndex> {
  final int index;

  TimingIndex(this.index);

  TimingIndex._privateConstructor(this.index);
  static final TimingIndex _empty = TimingIndex._privateConstructor(-1);
  static TimingIndex get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TimingIndex copyWith({int? index}) {
    return TimingIndex(
      index ?? this.index,
    );
  }

  @override
  String toString() {
    return "TimingPointIndex: $index";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TimingIndex) {
      return false;
    }
    return index == other.index;
  }

  @override
  int get hashCode => index.hashCode;

  TimingIndex operator +(int index) => TimingIndex(this.index + index);
  TimingIndex operator -(int index) => TimingIndex(this.index - index);

  @override
  int compareTo(TimingIndex other) {
    return index.compareTo(other.index);
  }

  bool operator >(TimingIndex other) => index > other.index;
  bool operator <(TimingIndex other) => index < other.index;
  bool operator >=(TimingIndex other) => index >= other.index;
  bool operator <=(TimingIndex other) => index <= other.index;
}
