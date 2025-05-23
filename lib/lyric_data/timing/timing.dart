import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/position/seek_position.dart';

class Timing {
  final InsertionPosition insertionPosition;
  final SeekPosition seekPosition;

  Timing(this.insertionPosition, this.seekPosition);

  Timing._privateConstructor(this.insertionPosition, this.seekPosition);
  static final Timing _empty = Timing._privateConstructor(InsertionPosition.empty, SeekPosition.empty);
  static Timing get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  Timing copyWith({InsertionPosition? insertionPosition, SeekPosition? seekPosition}) {
    return Timing(
      insertionPosition ?? this.insertionPosition,
      seekPosition ?? this.seekPosition,
    );
  }

  @override
  String toString() {
    return 'Timing(insertionPosition: $insertionPosition, seekPosition: $seekPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final Timing otherWords = other as Timing;
    return insertionPosition == otherWords.insertionPosition && seekPosition == otherWords.seekPosition;
  }

  @override
  int get hashCode => insertionPosition.hashCode ^ seekPosition.hashCode;
}
