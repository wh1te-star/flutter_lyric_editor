import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:tuple/tuple.dart';

/* Comparison Utility */
List<int> getCharPositionTranslation(String oldSentence, String newSentence) {
  int oldLength = oldSentence.length;
  int newLength = newSentence.length;

  List<List<int>> lcsMap = List.generate(oldLength + 1, (_) => List.filled(newLength + 1, 0));

  for (int i = 1; i <= oldLength; i++) {
    for (int j = 1; j <= newLength; j++) {
      if (oldSentence[i - 1] == newSentence[j - 1]) {
        lcsMap[i][j] = lcsMap[i - 1][j - 1] + 1;
      } else {
        lcsMap[i][j] = max(lcsMap[i - 1][j], lcsMap[i][j - 1]);
      }
    }
  }

  List<int> indexTranslation = List.filled(oldLength + 1, -1);
  int i = oldLength, j = newLength;

  while (i > 0 && j > 0) {
    if (oldSentence[i - 1] == newSentence[j - 1]) {
      indexTranslation[i] = j;
      indexTranslation[i - 1] = j - 1;
      i--;
      j--;
    } else if (lcsMap[i - 1][j] >= lcsMap[i][j - 1]) {
      i--;
    } else {
      j--;
    }
  }

  return indexTranslation;
}

/* Range Utility */
List<Tuple2<SegmentRange, Annotation?>> getRangeListForAnnotations(Map<SegmentRange, Annotation> annotations, int numberOfSegments) {
  if (annotations.isEmpty) {
    return [
      Tuple2(
        SegmentRange(0, numberOfSegments - 1),
        null,
      ),
    ];
  }

  List<Tuple2<SegmentRange, Annotation?>> rangeList = [];
  int previousEnd = -1;

  for (MapEntry<SegmentRange, Annotation> entry in annotations.entries) {
    SegmentRange segmentRange = entry.key;
    Annotation annotation = entry.value;

    if (previousEnd + 1 <= segmentRange.startIndex - 1) {
      rangeList.add(
        Tuple2(
          SegmentRange(previousEnd + 1, segmentRange.startIndex - 1),
          null,
        ),
      );
    }
    rangeList.add(
      Tuple2(
        segmentRange,
        annotation,
      ),
    );

    previousEnd = segmentRange.endIndex;
  }

  if (previousEnd + 1 <= numberOfSegments - 1) {
    rangeList.add(
      Tuple2(
        SegmentRange(previousEnd + 1, numberOfSegments - 1),
        null,
      ),
    );
  }

  return rangeList;
}

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
