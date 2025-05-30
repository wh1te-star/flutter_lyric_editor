import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';

class EmptySeekPosition extends SeekPosition {
  @override
  AbsoluteSeekPosition get absolute => AbsoluteSeekPosition.empty;

  @override
  SeekPosition operator +(Duration shift) {
    return EmptySeekPosition();
  }

  @override
  SeekPosition operator -(Duration shift) {
    return EmptySeekPosition();
  }
}
