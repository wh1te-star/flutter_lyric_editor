import 'package:lyric_editor/position/caret_position.dart';
import 'package:lyric_editor/position/seek_position/relative_seek_position.dart';

class Timing {
  final CaretPosition caretPosition;
  final RelativeSeekPosition seekPosition;

  Timing(this.caretPosition, this.seekPosition);

  Timing._privateConstructor(this.caretPosition, this.seekPosition);
  static final Timing _empty = Timing._privateConstructor(CaretPosition.empty, RelativeSeekPosition.empty);
  static Timing get empty => _empty;
  bool get isEmpty => identical(this, _empty);
  bool get isNotEmpty => !identical(this, _empty);

  Timing copyWith({CaretPosition? caretPosition, RelativeSeekPosition? seekPosition}) {
    return Timing(
      caretPosition ?? this.caretPosition,
      seekPosition ?? this.seekPosition,
    );
  }

  @override
  String toString() {
    return 'Timing(caretPosition: $caretPosition, seekPosition: $seekPosition)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (runtimeType != other.runtimeType) return false;
    final Timing otherWords = other as Timing;
    return caretPosition == otherWords.caretPosition && seekPosition == otherWords.seekPosition;
  }

  @override
  int get hashCode => caretPosition.hashCode ^ seekPosition.hashCode;
}
