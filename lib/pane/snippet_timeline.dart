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
    for (MapEntry<SnippetID, LyricSnippet> entry in timingService.snippetsForeachVocalist[vocalistID]!.entries) {
      SnippetID snippetID = entry.key;
      LyricSnippet snippet = entry.value;

      snippetItemWidgets.add(getSnippetItemWidget(snippetID, snippet));
      timingPointIndicatorWidgets += getTimingPointIndicatorWidgets(snippet);
    }
    return Stack(
      children: snippetItemWidgets + timingPointIndicatorWidgets,
    );
  }

  Widget getSnippetItemWidget(SnippetID snippetID, LyricSnippet snippet) {
    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Color vocalistColor = Color(timingService.vocalistColorMap[vocalistID]!.color);

    Size itemSize = Size(
      duration2Length(snippet.endTimestamp - snippet.startTimestamp),
      30.0,
    );
    Widget snippetItem = Positioned(
      left: duration2Length(snippet.startTimestamp),
      top: 5.0,
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
