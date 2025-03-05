import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/segment_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/mover/text_pane_cursor/text_pane_cursor.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';

class SentenceSegmentEdit extends StatelessWidget {
  final SentenceSegment sentenceSegment;
  final TextPaneCursor? textPaneCursor;
  final CursorBlinker? cursorBlinker;

  const SentenceSegmentEdit({
    required this.sentenceSegment,
    this.textPaneCursor,
    this.cursorBlinker,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle textStyle = const TextStyle(
      color: Colors.black,
    );
    if (textPaneCursor == null || cursorBlinker == null) {
      return Text(
        sentenceSegment.word,
        style: textStyle,
      );
    }

    if (textPaneCursor is SegmentSelectionCursor) {
      TextStyle textStyleIncursor = TextStyle(
        color: Colors.white,
        background: (Paint()..color = Colors.black),
      );

      return Text(
        sentenceSegment.word,
        style: cursorBlinker!.visible ? textStyleIncursor : textStyle,
      );
    } else {
      Color wordCursorColor = Colors.black;
      SentenceSelectionCursor cursor = textPaneCursor! as SentenceSelectionCursor;
      double cursorWidth = 1.0;
      double cursorHeight = 15.0;
      double cursorOffset = calculateCursorPosition(
        sentenceSegment.word,
        cursor.charPosition.position,
        textStyle,
      );

      return Stack(children: [
          /*
        Positioned(
            left: cursorOffset,
            child: Positioned(
              left: cursorOffset - cursorWidth / 2,
              child: Container(
                width: cursorWidth,
                height: cursorHeight,
                color: wordCursorColor,
              ),
            )),
            */
        Text(
          sentenceSegment.word,
          style: textStyle,
        ),
      ]);
    }
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
