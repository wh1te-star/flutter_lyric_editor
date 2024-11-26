import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
import 'package:lyric_editor/painter/triangle_painter.dart';
import 'package:lyric_editor/pane/text_pane.dart';
import 'package:lyric_editor/pane/timeline_pane.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';

class SnippetTimeline extends ConsumerStatefulWidget {
  VocalistID vocalistID;

  SnippetTimeline(this.vocalistID);

  @override
  _SnippetTimelineState createState() => _SnippetTimelineState(
        vocalistID,
      );
}

class _SnippetTimelineState extends ConsumerState<SnippetTimeline> {
  double topMargin = 5.0;
  double timingPointIndicatorHeight = 5.0;
  double annotationItemHeight = 15.0;
  double annotationSnippetMargin = 1.0;
  double snippetItemHeight = 30.0;
  double bottomMargin = 2.0;

  double timingPointIndicatorWidth = 5.0;

  VocalistID vocalistID;

  _SnippetTimelineState(
    this.vocalistID,
  );

  double length2Duration(double length) {
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
    int intervalDuration = timelinePaneProvider.intervalDuration;
    double intervalLength = timelinePaneProvider.intervalLength;
    return length * intervalDuration / intervalLength;
  }

  double duration2Length(int duration) {
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
    int intervalDuration = timelinePaneProvider.intervalDuration;
    double intervalLength = timelinePaneProvider.intervalLength;
    return duration.toDouble() * intervalLength / intervalDuration;
  }

  @override
  Widget build(BuildContext context) {
    final TimingService timingService = ref.read(timingMasterProvider);
    List<Widget> snippetItemWidgets = [];
    List<Widget> timingPointIndicatorWidgets = [];
    List<Widget> annotationItemWidgets = [];
    List<Widget> annotationTimingPointIndicatorWidgets = [];
    for (MapEntry<SnippetID, LyricSnippet> entry in timingService.snippetsForeachVocalist[vocalistID]!.entries) {
      SnippetID snippetID = entry.key;
      LyricSnippet snippet = entry.value;

      snippetItemWidgets.add(getSnippetItemWidget(snippetID, snippet));
      timingPointIndicatorWidgets += getTimingPointIndicatorWidgets(snippet);
      annotationItemWidgets += getAnnotationItemWidget(snippetID, snippet);
      annotationTimingPointIndicatorWidgets += getAnnotationTimingPointIndicatorWidgets(snippet);
    }
    return Stack(
      children: snippetItemWidgets + timingPointIndicatorWidgets + annotationItemWidgets + annotationTimingPointIndicatorWidgets,
    );
  }

  Widget getSnippetItemWidget(SnippetID snippetID, LyricSnippet snippet) {
    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Color vocalistColor = Color(timingService.vocalistColorMap[vocalistID]!.color);

    Size itemSize = Size(
      duration2Length(snippet.endTimestamp - snippet.startTimestamp),
      snippetItemHeight,
    );
    Widget snippetItem = Positioned(
      left: duration2Length(snippet.startTimestamp),
      top: topMargin + timingPointIndicatorHeight + annotationItemHeight + annotationSnippetMargin,
      child: GestureDetector(
        onTap: () {
          List<SnippetID> selectingSnippets = timelinePaneProvider.selectingSnippets;
          if (selectingSnippets.contains(snippetID)) {
            timelinePaneProvider.selectingSnippets.remove(snippetID);
          } else {
            timelinePaneProvider.selectingSnippets.add(snippetID);
          }
          setState(() {});
        },
        child: CustomPaint(
          size: itemSize,
          painter: RectanglePainter(
            sentence: snippet.sentence,
            color: vocalistColor,
            isSelected: timelinePaneProvider.selectingSnippets.contains(snippetID),
            borderLineWidth: 2.0,
          ),
        ),
      ),
    );
    return snippetItem;
  }

  List<Widget> getAnnotationItemWidget(SnippetID snippetID, LyricSnippet snippet) {
    List<Widget> annotaitonItems = [];

    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Color vocalistColor = Color(timingService.vocalistColorMap[vocalistID]!.color);

    for (MapEntry<SegmentRange, Annotation> entry in snippet.annotations.entries) {
      SegmentRange range = entry.key;
      Annotation annotation = entry.value;
      Size itemSize = Size(
        duration2Length(annotation.endTimestamp - annotation.startTimestamp),
        annotationItemHeight,
      );
      Widget annotationItem = Positioned(
        left: duration2Length(annotation.startTimestamp),
        top: topMargin + timingPointIndicatorHeight,
        child: GestureDetector(
          onTap: () {
            List<SnippetID> selectingSnippets = timelinePaneProvider.selectingSnippets;
            if (selectingSnippets.contains(snippetID)) {
              timelinePaneProvider.selectingSnippets.remove(snippetID);
            } else {
              timelinePaneProvider.selectingSnippets.add(snippetID);
            }
            setState(() {});
          },
          child: CustomPaint(
            size: itemSize,
            painter: RectanglePainter(
              sentence: "",
              color: vocalistColor,
              isSelected: timelinePaneProvider.selectingSnippets.contains(snippetID),
              borderLineWidth: 2.0,
            ),
          ),
        ),
      );
      annotaitonItems.add(annotationItem);
    }
    return annotaitonItems;
  }

  List<Widget> getTimingPointIndicatorWidgets(LyricSnippet snippet) {
    Size itemSize = Size(
      timingPointIndicatorWidth,
      timingPointIndicatorHeight,
    );

    List<Widget> indicatorWidgets = [];
    for (int index = 0; index < snippet.timingPoints.length; index++) {
      TimingPoint timingPoint = snippet.timingPoints[index];
      Widget indicator = Positioned(
        left: duration2Length(snippet.startTimestamp + timingPoint.seekPosition),
        top: topMargin + timingPointIndicatorHeight + annotationItemHeight + annotationSnippetMargin + snippetItemHeight,
        child: CustomPaint(
          size: itemSize,
          painter: TrianglePainter(
            x: 0.0,
            y: 0.0,
            width: 5.0,
            height: -5.0,
          ),
        ),
      );
      indicatorWidgets.add(indicator);
    }
    return indicatorWidgets;
  }

  List<Widget> getAnnotationTimingPointIndicatorWidgets(LyricSnippet snippet) {
    Size itemSize = Size(
      timingPointIndicatorWidth,
      timingPointIndicatorHeight,
    );

    List<Widget> indicatorWidgets = [];
    for (MapEntry<SegmentRange, Annotation> entry in snippet.annotations.entries) {
      SegmentRange range = entry.key;
      Annotation annotation = entry.value;
      for (int index = 0; index < annotation.timingPoints.length; index++) {
        TimingPoint timingPoint = annotation.timingPoints[index];
        Widget indicator = Positioned(
          left: duration2Length(annotation.startTimestamp + timingPoint.seekPosition),
          top: topMargin,
          child: CustomPaint(
            size: itemSize,
            painter: TrianglePainter(
              x: 0.0,
              y: timingPointIndicatorHeight,
              width: 5.0,
              height: 5.0,
            ),
          ),
        );
        indicatorWidgets.add(indicator);
      }
    }
    return indicatorWidgets;
  }
}
