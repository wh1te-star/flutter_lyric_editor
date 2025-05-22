import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_data/reading/reading.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:tuple/tuple.dart';


/* text size utilities */
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

/* Color Utilities */
Color adjustColorBrightness(Color color, double factor) {
  final hsl = HSLColor.fromColor(color);
  final adjustedLightness = (hsl.lightness + factor).clamp(0.0, 1.0);
  final hslAdjusted = hsl.withLightness(adjustedLightness);
  return hslAdjusted.toColor();
}

Color getContrastColor(Color color) {
  int brightness = ((color.red * 299) + (color.green * 587) + (color.blue * 114)) ~/ 1000;
  return brightness > 128 ? Colors.black : Colors.white;
}

Color determineBlackOrWhite(Color backgroundColor) {
  return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light ? Colors.black : Colors.white;
}
