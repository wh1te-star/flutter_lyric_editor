import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/timing/timing.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class TimingPointEdit extends StatelessWidget {
  static const String timingPointChar = '🕛';
  static const String rubyExistenceBorderChar = '🔽';

  final bool timingPoint;
  final CursorBlinker? cursorBlinker;

  const TimingPointEdit({
    this.timingPoint = true,
    this.cursorBlinker,
  });

  @override
  Widget build(BuildContext context) {
    String symbolChar = timingPointChar;
    if (!timingPoint) symbolChar = rubyExistenceBorderChar;
    String withSpace = "\xa0$symbolChar\xa0";

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
