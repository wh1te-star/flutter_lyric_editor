import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';

extension AbsoluteSeekPositionBase on AbsoluteSeekPosition implements SeekPositionBase {
  @override
  AbsoluteSeekPosition get absolute => this;
}