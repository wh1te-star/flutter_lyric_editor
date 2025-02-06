class TimingPoint {
  int charPosition;
  int seekPosition;

  TimingPoint(this.charPosition, this.seekPosition);

  static TimingPoint get emptyTimingPoint {
    return TimingPoint(-1, -1);
  }

  TimingPoint copyWith({int? charPosition, int? seekPosition}) {
    return TimingPoint(
      charPosition ?? this.charPosition,
      seekPosition ?? this.seekPosition,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TimingPoint otherSentenceSegments = other as TimingPoint;
    return charPosition == otherSentenceSegments.charPosition && seekPosition == otherSentenceSegments.seekPosition;
  }

  @override
  String toString() {
    return 'TimingPoint(charPosition: $charPosition, seekPosition: $seekPosition)';
  }

  @override
  int get hashCode => charPosition.hashCode ^ seekPosition.hashCode;
}
