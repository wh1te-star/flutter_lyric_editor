import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
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

  @override
  Widget build(BuildContext context) {
    final TimingService timingService = ref.read(timingMasterProvider);

    List<Widget> snippetItemWidgets = [];
    for (LyricSnippet snippet in snippets) {
      Size itemSize = Size(
        (snippet.endTimestamp - snippet.startTimestamp) * intervalLength / intervalDuration,
        30.0,
      );
      Widget snippetItem = CustomPaint(
        size: itemSize,
        painter: RectanglePainter(
          sentence: snippet.sentence,
          color: vocalistColor,
          isSelected: false,
          borderLineWidth: 2.0,
        ),
      );
      snippetItemWidgets.add(
        Positioned(
          left: snippet.startTimestamp * intervalLength / intervalDuration,
          child: snippetItem,
        ),
      );
    }
    return Stack(
      children: snippetItemWidgets,
    );
  }
}
