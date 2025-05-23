import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/word/word.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/ruby_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/word_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/base_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/position/insertion_position.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class WordEdit extends StatelessWidget {
  final Word word;
  final TextPaneCursor? textPaneCursor;
  final CursorBlinker? cursorBlinker;

  final double cursorWidth = 1.0;
  final double cursorHeight = 15.0;
  final Color wordCursorColor = Colors.black;
  final TextStyle normalTextStyle = const TextStyle(
    color: Colors.black,
  );
  final TextStyle underlineTextStyle = const TextStyle(
    color: Colors.black,
    decoration: TextDecoration.underline,
  );
  final TextStyle incursorTextStyle = TextStyle(
    color: Colors.white,
    background: (Paint()..color = Colors.black),
  );

  WordEdit({
    required this.word,
    this.textPaneCursor,
    this.cursorBlinker,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      cursorWidget(),
      textWidget(),
    ]);
  }

  Widget cursorWidget() {
    TextStyle textStyle = cursorTextStyle(textPaneCursor != null);
    int caretPosition = -1;
    if (textPaneCursor is BaseCursor && cursorBlinker != null && cursorBlinker!.visible) {
      BaseCursor cursor = textPaneCursor as BaseCursor;
      caretPosition = cursor.insertionPosition.position;
    }
    if (textPaneCursor is RubyCursor && cursorBlinker != null && cursorBlinker!.visible) {
      RubyCursor cursor = textPaneCursor as RubyCursor;
      caretPosition = cursor.insertionPosition.position;
    }

    if (caretPosition == -1) {
      return const ColoredBox(color: Colors.transparent);
    }

    double cursorOffset = calculateCursorPosition(
      word.word,
      caretPosition,
      textStyle,
    );
    return Positioned(
      left: cursorOffset - cursorWidth / 2,
      child: Container(
        width: cursorWidth,
        height: cursorHeight,
        color: wordCursorColor,
      ),
    );
  }

  Widget textWidget() {
    TextStyle textStyle = normalTextStyle;
    if (textPaneCursor != null && textPaneCursor is! WordCursor) {
      textStyle = underlineTextStyle;
    }
    if (textPaneCursor is WordCursor && cursorBlinker!.visible) {
      textStyle = incursorTextStyle;
    }
    return Text(
      word.word,
      style: textStyle,
    );
  }

  TextStyle cursorTextStyle(bool incursor) {
    if (cursorBlinker == null || cursorBlinker!.visible == false) {
      return normalTextStyle;
    }

    return incursorTextStyle;
  }

  double calculateCursorPosition(String text, int charPosition, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final TextPosition position = TextPosition(offset: charPosition);
    final Rect caretPrototype = Rect.fromLTWH(0, 0, 0, textPainter.height);
    final Offset caretOffset = textPainter.getOffsetForCaret(position, caretPrototype);
    return caretOffset.dx;
  }
}
