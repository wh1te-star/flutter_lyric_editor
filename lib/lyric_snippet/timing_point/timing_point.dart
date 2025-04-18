import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';

class TimingPoint {
  final InsertionPosition charPosition;
  final SeekPosition seekPosition;

  TimingPoint(this.charPosition, this.seekPosition);

  TimingPoint._privateConstructor(this.charPosition, this.seekPosition);
  static final TimingPoint _empty = TimingPoint._privateConstructor(InsertionPosition.empty, SeekPosition.empty);
  static TimingPoint get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  TimingPoint copyWith({InsertionPosition? charPosition, SeekPosition? seekPosition}) {
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
