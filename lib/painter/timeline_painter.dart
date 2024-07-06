import 'package:flutter/material.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
import 'package:lyric_editor/painter/triangle_painter.dart';

class TimelinePainter extends CustomPainter {
  final List<LyricSnippet> snippets;
  final List<LyricSnippetID> selectingId;
  final double intervalLength;
  final int intervalDuration;
  final double topMargin;
  final double bottomMargin;
  final Color indexColor;

  TimelinePainter({
    required this.snippets,
    required this.selectingId,
    required this.intervalLength,
    required this.intervalDuration,
    required this.topMargin,
    required this.bottomMargin,
    required this.indexColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final top = topMargin;
    final bottom = size.height - bottomMargin;

    snippets.forEach((LyricSnippet snippet) {
      final endtime = snippet.startTimestamp +
          snippet.timingPoints
              .map((point) => point.wordDuration)
              .reduce((a, b) => a + b);
      final left = snippet.startTimestamp * intervalLength / intervalDuration;
      final right = endtime * intervalLength / intervalDuration;
      final rect = Rect.fromLTRB(left, top, right, bottom);

      final isSelected = selectingId.contains(snippet.id);
      final rectanglePainter = RectanglePainter(
        rect: rect,
        sentence: snippet.sentence,
        indexColor: indexColor,
        isSelected: isSelected,
      );
      rectanglePainter.paint(canvas, size);

      double x = snippet.startTimestamp * intervalLength / intervalDuration;
      snippet.timingPoints.forEach((TimingPoint timingPoint) {
        TrianglePainter(
          x: x,
          y: top,
          width: 5.0,
          height: 5.0,
        ).paint(canvas, size);
        x += timingPoint.wordDuration * intervalLength / intervalDuration;
      });
      TrianglePainter(
        x: x,
        y: top,
        width: 5.0,
        height: 5.0,
      ).paint(canvas, size);
    });
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return true;
  }
}
