import 'package:flutter/material.dart';

class CurrentPositionIndicatorPainter extends CustomPainter {
  final double x;

  CurrentPositionIndicatorPainter({required this.x});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CurrentPositionIndicatorPainter oldDelegate) {
    return oldDelegate.x != x;
  }
}
