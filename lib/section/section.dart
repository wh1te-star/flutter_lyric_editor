import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';

class Section implements Comparable<Section> {
  AbsoluteSeekPosition seekPosition;

  Section(this.seekPosition);

  static Section get empty => Section(AbsoluteSeekPosition.empty);
  bool get isEmpty => this == empty;

  Section copyWith({
    AbsoluteSeekPosition? seekPosition,
  }) {
    return Section(seekPosition ?? this.seekPosition);
  }

  @override
  String toString() {
    return "Section($seekPosition)";
  }

  @override
  int compareTo(Section other) {
    return seekPosition.compareTo(other.seekPosition);
  }

  bool operator >(Section other) => compareTo(other) > 0;
  bool operator <(Section other) => compareTo(other) < 0;
  bool operator >=(Section other) => compareTo(other) >= 0;
  bool operator <=(Section other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Section) {
      return false;
    }
    if (runtimeType != other.runtimeType) {
      return false;
    }
    return seekPosition == other.seekPosition;
  }

  @override
  int get hashCode => seekPosition.hashCode;
}