import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';

class TimingPoint {
  final InsertionPosition insertionPosition;
  final SeekPosition seekPosition;

  TimingPoint(this.insertionPosition, this.seekPosition);

  TimingPoint._privateConstructor(this.insertionPosition, this.seekPosition);
  static final TimingPoint _empty = TimingPoint._privateConstructor(InsertionPosition.empty, SeekPosition.empty);
  static TimingPoint get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TimingPoint copyWith({InsertionPosition? insertionPosition, SeekPosition? seekPosition}) {
    return TimingPoint(
      insertionPosition ?? this.insertionPosition,
      seekPosition ?? this.seekPosition,
    );
  }

  @override
  String toString() {
    return 'TimingPoint(insertionPosition: $insertionPosition, seekPosition: $seekPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final TimingPoint otherSentenceSegments = other as TimingPoint;
    return insertionPosition == otherSentenceSegments.insertionPosition && seekPosition == otherSentenceSegments.seekPosition;
  }

  @override
  int get hashCode => insertionPosition.hashCode ^ seekPosition.hashCode;
}
