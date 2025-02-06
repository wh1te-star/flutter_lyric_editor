class PositionTypeInfo {
  PositionType type;
  int index;
  bool duplicate;
  PositionTypeInfo(this.type, this.index, this.duplicate);
}

enum PositionType {
  timingPoint,
  sentenceSegment,
}
