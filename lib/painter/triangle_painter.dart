import 'package:flutter/material.dart';

class TrianglePainter extends CustomPainter {
  final double x;
  final double y;
  final double width;
  final double height;

  TrianglePainter({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    Path path = Path()
      ..moveTo(x, y)
      ..lineTo(x - width / 2, y - height)
      ..lineTo(x + width / 2, y - height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    return oldDelegate.x != x ||
        oldDelegate.y != y ||
        oldDelegate.width != width ||
        oldDelegate.height != height;
  }
}
