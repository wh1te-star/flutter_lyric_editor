import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';

class SnippetTimeline extends ConsumerStatefulWidget {
  final List<LyricSnippet> snippets;
  final Color vocalistColor;
  final double songDuration;
  final double intervalLength;
  final double intervalDuration;
  final ScrollController scrollController;

  SnippetTimeline(
    this.snippets,
    this.vocalistColor,
    this.songDuration,
    this.intervalLength,
    this.intervalDuration,
    this.scrollController,
  );

  @override
  _SnippetTimelineState createState() => _SnippetTimelineState(
        snippets,
        vocalistColor,
        songDuration,
        intervalLength,
        intervalDuration,
        scrollController,
      );
}

class _SnippetTimelineState extends ConsumerState<SnippetTimeline> {
  List<LyricSnippet> snippets;
  Color vocalistColor;
  double songDuration;
  double intervalLength;
  double intervalDuration;
  ScrollController scrollController;

  _SnippetTimelineState(
    this.snippets,
    this.vocalistColor,
    this.songDuration,
    this.intervalLength,
    this.intervalDuration,
    this.scrollController,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: vocalistColor,
    );
  }
}
