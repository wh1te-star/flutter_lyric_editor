import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SentenceSegmentEdit extends StatelessWidget {
  final SentenceSegment sentenceSegment;
  final TextPaneCursor? textPaneCursor;
  final CursorBlinker? cursorBlinker;

  final double cursorWidth = 1.0;
  final double cursorHeight = 15.0;
  final Color wordCursorColor = Colors.black;
  final TextStyle normalTextStyle = const TextStyle(
    color: Colors.black,
  );
  final TextStyle incursorTextStyle = TextStyle(
    color: Colors.white,
    background: (Paint()..color = Colors.black),
  );

  SentenceSegmentEdit({
    required this.sentenceSegment,
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
    if (textPaneCursor is SentenceSelectionCursor) {
      SentenceSelectionCursor cursor = textPaneCursor as SentenceSelectionCursor;
      double cursorOffset = calculateCursorPosition(
        sentenceSegment.word,
        cursor.charPosition.position,
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

    return const ColoredBox(color: Colors.transparent);
  }

  Widget textWidget() {
    bool incursor = textPaneCursor != null;
    TextStyle textStyle = normalTextStyle.copyWith(
      decoration:incursor ? TextDecoration.underline : null,
    );
    return Text(
      sentenceSegment.word,
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
