import 'package:flutter/material.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';

class FunctionCell extends StatelessWidget {
  AbsoluteSeekPosition seekPosition;
  FunctionCell(this.seekPosition);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text("SeekPosition: ${seekPosition.absolute.position}"),
    );
  }
}
