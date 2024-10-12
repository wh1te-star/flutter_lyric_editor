import 'package:flutter/material.dart';

class PartialTextPainter extends CustomPainter {
  final String text;
  final int start;
  final int end;
  final double percent;
  final String fontFamily;
  final double fontSize;
  final Color fontBaseColor;
  final double firstOutlineWidth;
  final double secondOutlineWidth;

  late final List<TextStyle> textStylesBefore;
  late final List<TextSpan> textSpansBefore;
  late final List<TextPainter> textPaintersBefore;

  late final List<TextStyle> textStylesAfter;
  late final List<TextSpan> textSpansAfter;
  late final List<TextPainter> textPaintersAfter;

  PartialTextPainter({
    required this.text,
    required this.start,
    required this.end,
    required this.percent,
    required this.fontFamily,
    required this.fontSize,
    required this.fontBaseColor,
    required this.firstOutlineWidth,
    required this.secondOutlineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    setupTextStyles();
    setupTextSpans();
    setupTextPainters(size);
    paintText(canvas, size);
  }

  void setupTextStyles() {
    Shadow shadow = Shadow(
      color: fontBaseColor,
      blurRadius: 30.0,
      offset: const Offset(0.0, 0.0),
    );

    textStylesBefore = [
      createTextStyle(color: Colors.white),
      createTextStyle(strokeWidth: firstOutlineWidth, strokeColor: Colors.black),
      createTextStyle(strokeWidth: firstOutlineWidth + secondOutlineWidth, strokeColor: fontBaseColor, shadow: shadow),
    ];

    textStylesAfter = [
      createTextStyle(color: fontBaseColor),
      createTextStyle(strokeWidth: firstOutlineWidth, strokeColor: Colors.white),
      createTextStyle(strokeWidth: firstOutlineWidth + secondOutlineWidth, strokeColor: Colors.black, shadow: shadow),
    ];
  }

  TextStyle createTextStyle({
    Color? color,
    double? strokeWidth,
    Color? strokeColor,
    Shadow? shadow,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: color,
      foreground: strokeWidth != null && strokeColor != null
          ? (Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = strokeColor)
          : null,
      shadows: shadow != null ? [shadow] : null,
    );
  }

  void setupTextSpans() {
    textSpansBefore = textStylesBefore.map((style) => TextSpan(text: text, style: style)).toList();
    textSpansAfter = textStylesAfter.map((style) => TextSpan(text: text, style: style)).toList();
  }

  void setupTextPainters(Size size) {
    textPaintersBefore = textSpansBefore.map((span) {
      final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      painter.layout(maxWidth: size.width);
      return painter;
    }).toList();

    textPaintersAfter = textSpansAfter.map((span) {
      final painter = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
      painter.layout(maxWidth: size.width);
      return painter;
    }).toList();
  }

  void paintText(Canvas canvas, Size size) {
    final textWidth = textPaintersBefore[0].width;
    final textHeight = textPaintersBefore[0].height;

    final actualX = (size.width - textWidth) / 2;
    final actualY = (size.height - textHeight) / 2;

    final annotationCenterOffset = Offset(actualX, actualY - 10);
    final centerOffset = Offset(actualX, actualY);

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    for (var painter in textPaintersBefore.reversed) {
      painter.paint(canvas, centerOffset);
      painter.paint(canvas, annotationCenterOffset);
    }

    final startOffset = textPaintersAfter[0].getOffsetForCaret(TextPosition(offset: start), Rect.zero).dx;
    final endOffset = textPaintersAfter[0].getOffsetForCaret(TextPosition(offset: end), Rect.zero).dx;
    final sliceWidth = actualX + startOffset + (endOffset - startOffset) * percent;

    if (percent < 0 && sliceWidth > 0) {
      debugPrint("percent: $percent, sliceWidth: $sliceWidth");
    }

    canvas.clipRect(Rect.fromLTWH(0, 0, sliceWidth, size.height));

    for (var painter in textPaintersAfter.reversed) {
      painter.paint(canvas, centerOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}