class TimingPoint {
  final int charPosition;
  final int seekPosition;

  TimingPoint(this.charPosition, this.seekPosition) {
    if (!isEmpty()) {
      assert(charPosition >= 0);
      assert(seekPosition >= 0);
    }
  }

  static TimingPoint get emptyTimingPoint {
    return TimingPoint(-1, -1);
  }

  bool isEmpty() {
    return charPosition == -1 && seekPosition == -1;
  }

  TimingPoint copyWith({int? charPosition, int? seekPosition}) {
    return TimingPoint(
      charPosition ?? this.charPosition,
      seekPosition ?? this.seekPosition,
    );
  }

  @override
  String toString() {
    return 'TimingPoint(charPosition: $charPosition, seekPosition: $seekPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TimingPoint otherSentenceSegments = other as TimingPoint;
    return charPosition == otherSentenceSegments.charPosition && seekPosition == otherSentenceSegments.seekPosition;
  }

  @override
  int get hashCode => charPosition.hashCode ^ seekPosition.hashCode;
}
