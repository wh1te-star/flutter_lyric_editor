import 'package:flutter/material.dart';

class ScaleMark extends CustomPainter {
  final double intervalLength;
  final double majorMarkLength;
  final double midiumMarkLength;
  final double minorMarkLength;
  final int intervalDuration;

  ScaleMark(
      {required this.intervalLength,
      required this.majorMarkLength,
      required this.midiumMarkLength,
      required this.minorMarkLength,
      required this.intervalDuration});

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
    double x = intervalLength - 1;
    for (int i = 1; x <= size.width; i++, x += intervalLength) {
      if (i % 10 == 0) {
        canvas.drawLine(
          Offset(x, size.height - majorMarkLength),
          Offset(x, size.height),
          paint,
        );
        String text = formatSecond((i * intervalDuration / 1000.0).toInt());
        TextSpan span = TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 12),
          text: text,
        );
        TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
          canvas,
          Offset(x - tp.width / 2, size.height - majorMarkLength - tp.height),
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

  String formatSecond(int inSecondFormat) {
    int minutes = inSecondFormat ~/ Duration.secondsPerMinute;
    int seconds = inSecondFormat % Duration.secondsPerMinute;

    String formattedMinutes = minutes.toString().padLeft(2, '0');
    String formattedSeconds = seconds.toString().padLeft(2, '0');

    return "$formattedMinutes:$formattedSeconds";
  }
}
