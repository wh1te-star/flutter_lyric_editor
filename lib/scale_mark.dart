import 'package:flutter/material.dart';

class ScaleMark extends CustomPainter {
  final double interval;
  final double majorMarkLength;
  final double midiumMarkLength;
  final double minorMarkLength;

  ScaleMark(
      {required this.interval,
      required this.majorMarkLength,
      required this.midiumMarkLength,
      required this.minorMarkLength});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      paint,
    );
    double x = 0.0;
    for (int i = 0; x <= size.width; i++, x += interval) {
      if (i % 10 == 0) {
        canvas.drawLine(
          Offset(x, size.height - majorMarkLength),
          Offset(x, size.height),
          paint,
        );
      } else if (i % 5 == 0) {
        canvas.drawLine(
          Offset(x, size.height - midiumMarkLength),
          Offset(x, size.height),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(x, size.height - minorMarkLength),
          Offset(x, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
