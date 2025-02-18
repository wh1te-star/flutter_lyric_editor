import 'package:flutter/material.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:lyric_editor/pane/video_pane/annotation_range_caption.dart';

void main() {
  testGoldens('AnnotationRangeCaption screenshot', (tester) async {
    final widget = MaterialApp(
      home: Scaffold(
        body: Text("abc"),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Take screenshot of the entire widget
    await screenMatchesGolden(tester, 'annotation_range_caption');
  });
}