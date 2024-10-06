import 'package:flutter/material.dart';

Size getSizeFromTextStyle(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(minWidth: 0, maxWidth: double.infinity);

  return textPainter.size;
}

Size getSizeFromFontInfo(
  String text,
  double fontSize,
  String fontFamily,
) {
  final TextStyle textStyle = TextStyle(
    fontSize: fontSize,
    fontFamily: fontFamily,
  );
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: textStyle),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout(minWidth: 0, maxWidth: double.infinity);

  return textPainter.size;
}
