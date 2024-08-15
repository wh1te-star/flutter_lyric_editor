import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class CurrentPositionIndicatorPainter extends CustomPainter {
  final double intervalLength;
  final int intervalDuration;
  final int seekPosition;
  final List<int> sections;

  CurrentPositionIndicatorPainter(this.intervalLength, this.intervalDuration, this.seekPosition, this.sections);

  @override
  void paint(Canvas canvas, Size size) {
    Paint sectionPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0;
    sections.forEach((int section) {
      double x = section * intervalLength / intervalDuration;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), sectionPaint);
    });

    Paint seekPositionPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;
    double x = seekPosition * intervalLength / intervalDuration;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), seekPositionPaint);
  }

  @override
  bool shouldRepaint(covariant CurrentPositionIndicatorPainter oldDelegate) {
    return oldDelegate.seekPosition != seekPosition || !const ListEquality().equals(oldDelegate.sections, sections);
  }
}
