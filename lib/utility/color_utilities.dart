import 'package:flutter/material.dart';

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
