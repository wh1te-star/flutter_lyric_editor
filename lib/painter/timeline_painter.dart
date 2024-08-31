import 'package:flutter/material.dart';
import 'package:lyric_editor/utility/color_utilities.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
import 'package:lyric_editor/painter/triangle_painter.dart';

class TimelinePainter extends CustomPainter {
  final Map<SnippetID, LyricSnippet> snippets;
  final List<SnippetID> selectingId;
  final double intervalLength;
  final int intervalDuration;
  final Color color;
  final double frameThickness;
  final double topMargin;
  final double bottomMargin;
  final SnippetID? cursorPosition;

  TimelinePainter({
    required this.snippets,
    required this.selectingId,
    required this.intervalLength,
    required this.intervalDuration,
    required this.color,
    required this.frameThickness,
    required this.topMargin,
    required this.bottomMargin,
    this.cursorPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int maxLanes = getMaxLanes(snippets.values.toList());

    int previousEndtime = 0;
    int currentLane = 0;

    final frameRect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    final frameRectanglePainter = RectanglePainter(
      rect: frameRect,
      sentence: "",
      color: Colors.grey,
      isSelected: true,
      borderLineWidth: frameThickness,
    );
    frameRectanglePainter.paint(canvas, size);

    Color backgroundColor = adjustColorBrightness(color, 0.3);
    Rect rect = Rect.fromLTRB(frameThickness, frameThickness, size.width - frameThickness, size.height - frameThickness);
    Paint paint = Paint()..color = backgroundColor;
    canvas.drawRect(rect, paint);

    snippets.forEach((SnippetID id, LyricSnippet snippet) {
      if (snippet.sentence == "") return;

      final endtime = snippet.startTimestamp + snippet.sentenceSegments.map((point) => point.wordDuration).reduce((a, b) => a + b);
      if (snippet.startTimestamp < previousEndtime) {
        currentLane++;
      } else {
        currentLane = 0;
        previousEndtime = endtime;
      }

      final top = currentLane * size.height / maxLanes + topMargin;
      final bottom = currentLane * size.height / maxLanes + size.height / maxLanes - bottomMargin;
      final left = snippet.startTimestamp * intervalLength / intervalDuration;
      final right = endtime * intervalLength / intervalDuration;
      final rect = Rect.fromLTRB(left, top, right, bottom);

      final isSelected = selectingId.contains(id);
      final rectanglePainter = RectanglePainter(
        rect: rect,
        sentence: snippet.sentence,
        color: color,
        isSelected: isSelected,
        borderLineWidth: 2.0,
      );
      rectanglePainter.paint(canvas, size);

      double x = snippet.startTimestamp * intervalLength / intervalDuration;
      snippet.sentenceSegments.forEach((SentenceSegment sentenceSegment) {
        TrianglePainter(
          x: x,
          y: top,
          width: 5.0,
          height: 5.0,
        ).paint(canvas, size);
        x += sentenceSegment.wordDuration * intervalLength / intervalDuration;
      });
      TrianglePainter(
        x: x,
        y: top,
        width: 5.0,
        height: 5.0,
      ).paint(canvas, size);

      if (id == cursorPosition) {
        final paint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawRect(rect, paint);
      }
    });
  }

  int getMaxLanes(List<LyricSnippet> lyricSnippetList) {
    if (lyricSnippetList.isEmpty) return 0;
    lyricSnippetList.sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));

    int maxOverlap = 0;
    int currentOverlap = 1;
    int currentEndTime = lyricSnippetList[0].endTimestamp;

    for (int i = 1; i < lyricSnippetList.length; ++i) {
      int start = lyricSnippetList[i].startTimestamp;
      int end = lyricSnippetList[i].endTimestamp;
      if (start <= currentEndTime) {
        currentOverlap++;
      } else {
        currentOverlap = 1;
        currentEndTime = end;
      }
      if (currentOverlap > maxOverlap) {
        maxOverlap = currentOverlap;
      }
    }

    return maxOverlap;
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return true;
  }
}
