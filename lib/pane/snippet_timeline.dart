import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:lyric_editor/dialog/snippet_detail_dialog.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/timing_point/timing_point.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
import 'package:lyric_editor/painter/triangle_painter.dart';
import 'package:lyric_editor/pane/timeline_pane.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet.dart';

class SnippetTimeline extends ConsumerStatefulWidget {
  VocalistID vocalistID;

  SnippetTimeline(this.vocalistID, {super.key});

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
  double get trackHeight {
    return topMargin + timingPointIndicatorHeight + annotationItemHeight + annotationSnippetMargin + snippetItemHeight + bottomMargin;
  }

  double timingPointIndicatorWidth = 5.0;

  VocalistID vocalistID;
  Map<SnippetID, int> snippetTracks = {};

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

    Map<SnippetID, LyricSnippet> snippets = timingService.snippetsForeachVocalist[vocalistID]!;
    snippetTracks = getTrack(snippets);
    for (MapEntry<SnippetID, LyricSnippet> entry in snippets.entries) {
      SnippetID snippetID = entry.key;
      LyricSnippet snippet = entry.value;

      snippetItemWidgets.add(getSnippetItemWidget(snippetID, snippet));
      timingPointIndicatorWidgets += getTimingPointIndicatorWidgets(snippetID, snippet);
      annotationItemWidgets += getAnnotationItemWidget(snippetID, snippet);
      annotationTimingPointIndicatorWidgets += getAnnotationTimingPointIndicatorWidgets(snippetID, snippet);
    }
    return Stack(
      children: snippetItemWidgets + timingPointIndicatorWidgets + annotationItemWidgets + annotationTimingPointIndicatorWidgets,
    );
  }

  Map<SnippetID, int> getTrack(Map<SnippetID, LyricSnippet> snippets) {
    Map<SnippetID, int> tracks = {};
    int currentTrack = 0;
    int previousEndtime = 0;
    for (MapEntry<SnippetID, LyricSnippet> entry in snippets.entries) {
      SnippetID id = entry.key;
      LyricSnippet snippet = entry.value;

      if (snippet.sentence == "") {
        tracks[id] = -1;
        continue;
      }

      final endtime = snippet.endTimestamp;
      if (snippet.startTimestamp < previousEndtime) {
        currentTrack++;
      } else {
        currentTrack = 0;
        previousEndtime = endtime;
      }

      tracks[id] = currentTrack;
    }

    return tracks;
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
      top: trackHeight * snippetTracks[snippetID]! + topMargin + timingPointIndicatorHeight + annotationItemHeight + annotationSnippetMargin,
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
        onDoubleTap: () {
          displaySnippetDetailDialog(context, snippetID, snippet);
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
        top: trackHeight * snippetTracks[snippetID]! + topMargin + timingPointIndicatorHeight,
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

  List<Widget> getTimingPointIndicatorWidgets(SnippetID snippetID, LyricSnippet snippet) {
    Size itemSize = Size(
      timingPointIndicatorWidth,
      timingPointIndicatorHeight,
    );

    List<Widget> indicatorWidgets = [];
    for (int index = 0; index < snippet.timingPoints.length; index++) {
      TimingPoint timingPoint = snippet.timingPoints[index];
      Widget indicator = Positioned(
        left: duration2Length(snippet.startTimestamp + timingPoint.seekPosition),
        top: trackHeight * snippetTracks[snippetID]! + topMargin + timingPointIndicatorHeight + annotationItemHeight + annotationSnippetMargin + snippetItemHeight,
        child: CustomPaint(
          size: itemSize,
          painter: TrianglePainter(
            x: 0.0,
            y: 0.0,
            width: timingPointIndicatorWidth,
            height: -timingPointIndicatorHeight,
          ),
        ),
      );
      indicatorWidgets.add(indicator);
    }
    return indicatorWidgets;
  }

  List<Widget> getAnnotationTimingPointIndicatorWidgets(SnippetID snippetID, LyricSnippet snippet) {
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
          top: trackHeight * snippetTracks[snippetID]! + topMargin,
          child: CustomPaint(
            size: itemSize,
            painter: TrianglePainter(
              x: 0.0,
              y: timingPointIndicatorHeight,
              width: timingPointIndicatorWidth,
              height: timingPointIndicatorHeight,
            ),
          ),
        );
        indicatorWidgets.add(indicator);
      }
    }
    return indicatorWidgets;
  }
}
