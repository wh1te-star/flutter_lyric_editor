import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';

abstract class SeekPosition {
  AbsoluteSeekPosition get absolute;

  SeekPosition operator +(Duration shift);
  SeekPosition operator -(Duration shift);
}
