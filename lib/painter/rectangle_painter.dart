import 'package:flutter/material.dart';
import 'package:lyric_editor/utility/color_utilities.dart';

class RectanglePainter extends CustomPainter {
  final Rect rect;
  final String sentence;
  final Color color;
  final bool isSelected;
  final double borderLineWidth;

  RectanglePainter({
    required this.rect,
    required this.sentence,
    required this.color,
    required this.isSelected,
    required this.borderLineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()..color = color;
    canvas.drawRect(rect, mainPaint);

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
      maxWidth: rect.width,
    );

    final offset = Offset(
      rect.left + (rect.width - textPainter.width) / 2 - 1,
      rect.top + (rect.height - textPainter.height) / 2 - 1,
    );

    textPainter.paint(canvas, offset);

    final double strokeLineWidth = 1.0;
    final lighterColor = adjustColorBrightness(color, 0.1);
    final darkerColor = adjustColorBrightness(color, -0.3);
    final leftInner = rect.left + borderLineWidth;
    final topInner = rect.top + borderLineWidth;
    final rightInner = rect.right - borderLineWidth;
    final bottomInner = rect.bottom - borderLineWidth;

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
      ..strokeWidth = strokeLineWidth
      ..style = PaintingStyle.fill;

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
