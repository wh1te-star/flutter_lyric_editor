import 'package:flutter/material.dart';
import 'package:lyric_editor/utility/color_utilities.dart';

class RectanglePainter extends CustomPainter {
  final Rect? rect;
  final String sentence;
  final Color color;
  final bool isSelected;
  final double borderLineWidth;

  RectanglePainter({
    required this.sentence,
    required this.color,
    required this.isSelected,
    required this.borderLineWidth,
    this.rect,
  });

  @override
@override
void paint(Canvas canvas, Size size) {
  final mainPaint = Paint()..color = color;

  // Use a local variable to hold the rect value
  final Rect effectiveRect = rect ?? Rect.fromLTWH(0, 0, size.width, size.height);

  canvas.drawRect(effectiveRect, mainPaint);

  final textSpan = TextSpan(
    text: sentence,
    style: TextStyle(color: determineBlackOrWhite(color), fontSize: 16),
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
    maxWidth: effectiveRect.width,
  );

  final offset = Offset(
    effectiveRect.left + (effectiveRect.width - textPainter.width) / 2 - 1,
    effectiveRect.top + (effectiveRect.height - textPainter.height) / 2 - 1,
  );

  textPainter.paint(canvas, offset);

  const double strokeLineWidth = 1.0;
  final lighterColor = adjustColorBrightness(color, 0.1);
  final darkerColor = adjustColorBrightness(color, -0.3);
  final leftInner = effectiveRect.left + borderLineWidth;
  final topInner = effectiveRect.top + borderLineWidth;
  final rightInner = effectiveRect.right - borderLineWidth;
  final bottomInner = effectiveRect.bottom - borderLineWidth;

  final lighterPath = Path()
    ..moveTo(effectiveRect.left, effectiveRect.top)
    ..lineTo(effectiveRect.left, effectiveRect.bottom)
    ..lineTo(leftInner, bottomInner)
    ..lineTo(leftInner, topInner)
    ..lineTo(rightInner, topInner)
    ..lineTo(effectiveRect.right, effectiveRect.top)
    ..lineTo(effectiveRect.left, effectiveRect.top);

  final lighterPaint = Paint()
    ..color = lighterColor
    ..strokeWidth = strokeLineWidth
    ..style = PaintingStyle.fill;

  final darkerPath = Path()
    ..moveTo(effectiveRect.right, effectiveRect.bottom)
    ..lineTo(effectiveRect.right, effectiveRect.top)
    ..lineTo(rightInner, topInner)
    ..lineTo(rightInner, bottomInner)
    ..lineTo(leftInner, bottomInner)
    ..lineTo(effectiveRect.left, effectiveRect.bottom)
    ..lineTo(effectiveRect.right, effectiveRect.bottom);

  final darkerPaint = Paint()
    ..color = darkerColor
    ..strokeWidth = strokeLineWidth
    ..style = PaintingStyle.fill;

  if (isSelected) {
    canvas.drawPath(lighterPath, darkerPaint);
    canvas.drawPath(darkerPath, lighterPaint);
  } else {
    canvas.drawPath(lighterPath, lighterPaint);
    canvas.drawPath(darkerPath, darkerPaint);
  }
}

  @override
  bool shouldRepaint(covariant RectanglePainter oldDelegate) {
    return oldDelegate.rect != rect || oldDelegate.sentence != sentence || oldDelegate.color != color || oldDelegate.isSelected != isSelected;
  }
}
