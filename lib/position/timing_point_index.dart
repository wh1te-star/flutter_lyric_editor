class TimingPointIndex implements Comparable<TimingPointIndex> {
  final int index;

  TimingPointIndex(this.index);

  TimingPointIndex._privateConstructor(this.index);
  static final TimingPointIndex _empty = TimingPointIndex._privateConstructor(-1);
  static TimingPointIndex get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TimingPointIndex copyWith({int? index}) {
    return TimingPointIndex(
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
    if (other is! TimingPointIndex) {
      return false;
    }
    return index == other.index;
  }

  @override
  int get hashCode => index.hashCode;

  TimingPointIndex operator +(int index) => TimingPointIndex(this.index + index);
  TimingPointIndex operator -(int index) => TimingPointIndex(this.index - index);

  @override
  int compareTo(TimingPointIndex other) {
    return index.compareTo(other.index);
  }

  bool operator >(TimingPointIndex other) => index > other.index;
  bool operator <(TimingPointIndex other) => index < other.index;
  bool operator >=(TimingPointIndex other) => index >= other.index;
  bool operator <=(TimingPointIndex other) => index <= other.index;
}