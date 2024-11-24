import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
import 'package:lyric_editor/painter/triangle_painter.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';

class SnippetTimeline extends ConsumerStatefulWidget {
  final List<LyricSnippet> snippets;
  final Color vocalistColor;
  final double songDuration;
  final double intervalLength;
  final double intervalDuration;

  SnippetTimeline(
    this.snippets,
    this.vocalistColor,
    this.songDuration,
    this.intervalLength,
    this.intervalDuration,
  );

  @override
  _SnippetTimelineState createState() => _SnippetTimelineState(
        snippets,
        vocalistColor,
        songDuration,
        intervalLength,
        intervalDuration,
      );
}

class _SnippetTimelineState extends ConsumerState<SnippetTimeline> {
  List<LyricSnippet> snippets;
  Color vocalistColor;
  double songDuration;
  double intervalLength;
  double intervalDuration;

  _SnippetTimelineState(
    this.snippets,
    this.vocalistColor,
    this.songDuration,
    this.intervalLength,
    this.intervalDuration,
  );

  double length2Duration(double length) {
    return length * intervalDuration / intervalLength;
  }

  double duration2Length(int duration) {
    return duration.toDouble() * intervalLength / intervalDuration;
  }

  @override
  Widget build(BuildContext context) {
    final TimingService timingService = ref.read(timingMasterProvider);

    List<Widget> snippetItemWidgets = [];
    List<Widget> timingPointIndicatorWidgets = [];
    for (LyricSnippet snippet in snippets) {
      snippetItemWidgets.add(getSnippetItemWidget(snippet));
      if (timingPointIndicatorWidgets.isEmpty) {
        timingPointIndicatorWidgets += getTimingPointIndicatorWidgets(snippet);
      }
    }
    return Stack(
      children: snippetItemWidgets + timingPointIndicatorWidgets,
    );
  }

  Widget getSnippetItemWidget(LyricSnippet snippet) {
    Size itemSize = Size(
      duration2Length(snippet.endTimestamp - snippet.startTimestamp),
      30.0,
    );
    Widget snippetItem = Positioned(
      left: duration2Length(snippet.startTimestamp),
      top: 5.0,
      child: CustomPaint(
        size: itemSize,
        painter: RectanglePainter(
          sentence: snippet.sentence,
          color: vocalistColor,
          isSelected: false,
          borderLineWidth: 2.0,
        ),
      ),
    );
    return snippetItem;
  }

  List<Widget> getTimingPointIndicatorWidgets(LyricSnippet snippet) {
    Size itemSize = Size(
      10.0,
      10.0,
    );

    List<Widget> indicatorWidgets = [];
    for (int index = 0; index < snippet.timingPoints.length; index++) {
      TimingPoint timingPoint = snippet.timingPoints[index];
      Widget indicator = Positioned(
        left: duration2Length(snippet.startTimestamp + timingPoint.seekPosition),
        child: CustomPaint(
          size: itemSize,
          painter: TrianglePainter(
            x: 0.0,
            y: 5.0,
            width: 5.0,
            height: 5.0,
          ),
        ),
      );
      indicatorWidgets.add(indicator);
    }
    return indicatorWidgets;
  }
}
