import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TimingPointEdit extends StatelessWidget {
  static const String timingPointChar = '🕛';

  final CursorBlinker? cursorBlinker;

  const TimingPointEdit({
    this.cursorBlinker,
  });

  @override
  Widget build(BuildContext context) {
    String withSpace = "\xa0$timingPointChar\xa0";
    TextStyle textStyle = const TextStyle(
      color: Colors.black,
    );

    if (cursorBlinker?.visible ?? false) {
      textStyle = TextStyle(
        color: Colors.white,
        background: (Paint()..color = Colors.black),
      );
    }

    return Text(
      withSpace,
      style: textStyle,
    );
  }
}
