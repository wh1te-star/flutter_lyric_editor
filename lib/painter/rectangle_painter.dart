import 'package:flutter/material.dart';

class RectanglePainter extends CustomPainter {
  final Rect rect;
  final String sentence;
  final Color indexColor;
  final bool isSelected;

  RectanglePainter({
    required this.rect,
    required this.sentence,
    required this.indexColor,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()..color = indexColor;
    canvas.drawRect(rect, mainPaint);

    final textSpan = TextSpan(
      text: sentence,
      style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(indexColor) ==
                  Brightness.light
              ? Colors.black
              : Colors.white,
          fontSize: 16),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: rect.width,
    );

    final offset = Offset(
      rect.left + (rect.width - textPainter.width) / 2 - 1,
      rect.top + (rect.height - textPainter.height) / 2 - 1,
    );

    textPainter.paint(canvas, offset);

    final double edgeWidth = 1.5;
    final lighterColor = _adjustColorBrightness(indexColor, 0.1);
    final darkerColor = _adjustColorBrightness(indexColor, -0.3);
    final borderRadius = 1.0;
    final leftInner = rect.left + borderRadius;
    final topInner = rect.top + borderRadius;
    final rightInner = rect.right - borderRadius;
    final bottomInner = rect.bottom - borderRadius;

    final lighterPath = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(leftInner, bottomInner)
      ..lineTo(leftInner, topInner)
      ..lineTo(rightInner, topInner)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.left, rect.top);

    final lighterPaint = Paint()
      ..color = lighterColor
      ..strokeWidth = edgeWidth
      ..style = PaintingStyle.stroke;

    final darkerPath = Path()
      ..moveTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rightInner, topInner)
      ..lineTo(rightInner, bottomInner)
      ..lineTo(leftInner, bottomInner)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom);

    final darkerPaint = Paint()
      ..color = darkerColor
      ..strokeWidth = edgeWidth
      ..style = PaintingStyle.stroke;

    if (isSelected) {
      canvas.drawPath(lighterPath, darkerPaint);
      canvas.drawPath(darkerPath, lighterPaint);
    } else {
      canvas.drawPath(lighterPath, lighterPaint);
      canvas.drawPath(darkerPath, darkerPaint);
    }
  }

  Color _adjustColorBrightness(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final adjustedLightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    final hslAdjusted = hsl.withLightness(adjustedLightness);
    return hslAdjusted.toColor();
  }

  @override
  bool shouldRepaint(covariant RectanglePainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.sentence != sentence ||
        oldDelegate.indexColor != indexColor ||
        oldDelegate.isSelected != isSelected;
  }
}
