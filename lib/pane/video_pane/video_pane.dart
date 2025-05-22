import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/pane/text_pane/text_pane_provider.dart';
import 'package:lyric_editor/pane/video_pane/colored_caption.dart';
import 'package:lyric_editor/pane/video_pane/show_hide_mode/show_hide_mode_screen.dart';
import 'package:lyric_editor/pane/video_pane/video_pane_provider.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist.dart';
import 'package:lyric_editor/pane/video_pane/colored_text_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/timeline_pane.dart';
import 'package:lyric_editor/position/segment_index.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

class VideoPane extends ConsumerStatefulWidget {
  final FocusNode focusNode;

  const VideoPane({required this.focusNode}) : super(key: const Key('VideoPane'));

  @override
  _VideoPaneState createState() => _VideoPaneState(focusNode);
}

class _VideoPaneState extends ConsumerState<VideoPane> {
  final FocusNode focusNode;
  _VideoPaneState(this.focusNode);

  ScrollController scrollController = ScrollController();

  int maxLanes = 0;

  final GlobalKey _videoPaneKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);

    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);
    final VideoPaneProvider videoPaneProvider = ref.read(videoPaneMasterProvider);
    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
    final KeyboardShortcutsNotifier keyboardShortcutsNotifier = ref.read(keyboardShortcutsMasterProvider);

    musicPlayerService.addListener(() {
      final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
      bool isPlaying = musicPlayerService.isPlaying;
      if (videoPaneProvider.displayMode == DisplayMode.verticalScroll && isPlaying) {
        SeekPosition seekPosition = musicPlayerService.seekPosition;
        scrollController.jumpTo(getScrollOffsetFromSeekPosition(seekPosition.position));
      }
      setState(() {});
    });

    timingService.addListener(() {
      setState(() {});
    });

    videoPaneProvider.addListener(() {
      setState(() {});
    });

    textPaneProvider.addListener(() {
      setState(() {});
    });

    timelinePaneProvider.addListener(() {
      setState(() {});
    });

    keyboardShortcutsNotifier.addListener(() {
      setState(() {});
    });
  }

  String defaultText = "Video Pane";

  int getMaxRequiredLanes(Map<LyricSnippetID, int> lyricSnippetList) {
    return lyricSnippetList.values.toList().reduce(max);
  }

  double getMiddlePoint(LyricSnippet snippet) {
    return (snippet.startTimestamp.position + snippet.endTimestamp.position) / 2;
  }

  double getScrollOffsetFromSeekPosition(int seekPosition) {
    int justBeforeIndex = 0;
    int justAfterIndex = 0;
    double justBeforePosition = 0;
    double justAfterPosition = double.maxFinite;

    final Map<LyricSnippetID, LyricSnippet> lyricSnippetList = ref.read(timingMasterProvider).lyricSnippetMap.map;
    for (int index = 0; index < lyricSnippetList.length; index++) {
      double currentTime = getMiddlePoint(lyricSnippetList.values.toList()[index]);
      if (currentTime < seekPosition) {
        if (justBeforePosition < currentTime) {
          justBeforePosition = currentTime;
          justBeforeIndex = index;
        }
      } else {
        if (currentTime < justAfterPosition) {
          justAfterPosition = currentTime;
          justAfterIndex = index;
        }
      }
    }

    double snippetOffset = (justAfterIndex - justBeforeIndex) * 60;
    double midSnippetOffset = snippetOffset * (seekPosition - justBeforePosition) / (justAfterPosition - justBeforePosition);
    double scrollOffset = 60.0 * (justBeforeIndex + 1) + midSnippetOffset;

    return scrollOffset;
  }

  double getSeekPositionFromScrollOffset(double scrollOffset) {
    final TimingService timingService = ref.read(timingMasterProvider);
    final List<LyricSnippet> lyricSnippetList = timingService.lyricSnippetMap.values.toList();

    if (scrollOffset < 30) {
      return lyricSnippetList[0].startTimestamp.position.toDouble();
    }
    int snippetIndex = (scrollOffset - 30) ~/ 60;
    debugPrint("scroll offset: $scrollOffset, snippetIndex: $snippetIndex");
    late double startPosition;
    late double endPosition;
    if ((scrollOffset - 30) % 60 < 30) {
      if (snippetIndex == 0) {
        startPosition = 2 * getMiddlePoint(lyricSnippetList[snippetIndex]) - getMiddlePoint(lyricSnippetList[snippetIndex + 1]);
      } else {
        startPosition = getMiddlePoint(lyricSnippetList[snippetIndex - 1]);
      }
      endPosition = getMiddlePoint(lyricSnippetList[snippetIndex]);
    } else {
      startPosition = getMiddlePoint(lyricSnippetList[snippetIndex]);
      endPosition = getMiddlePoint(lyricSnippetList[snippetIndex + 1]);
    }
    double scrollExtra = (scrollOffset % 60) / 60;
    double seekPosition = startPosition + (endPosition - startPosition) * scrollExtra;
    return seekPosition;
  }

  double getAnnotationSizePosition(LyricSnippet snippet, SentenceSegmentIndex segmentIndex) {
    int startIndex = snippet.annotationMap.map.keys.toList()[segmentIndex.index].startIndex.index;
    double sumPosition = 0;
    int index = 0;
    for (index = 0; index < startIndex; index++) {
      sumPosition += getSizeFromTextStyle(snippet.sentenceSegments[index].word, const TextStyle(fontSize: 40)).width;
    }
    sumPosition += getSizeFromTextStyle(snippet.sentenceSegments[index].word, const TextStyle(fontSize: 40)).width / 2;
    return sumPosition - getSizeFromTextStyle(snippet.sentence, const TextStyle(fontSize: 40)).width / 2;
  }

  @override
  Widget build(BuildContext context) {
    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);

    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTap: () {
          musicPlayerService.playPause();
          focusNode.requestFocus();
          debugPrint("The video pane is focused");
        },
        child: ShowHideModeScreen(
          lyricSnippetMap: timingService.lyricSnippetMap,
          vocalistColorMap: timingService.vocalistColorMap,
          seekPosition: musicPlayerService.seekPosition,
        ),
      ),
    );
    /*
    } else {
      double height = 60;
      List<Widget> columnSnippets = [];
      columnSnippets.add(Container(color: const Color.fromARGB(255, 164, 240, 156), height: 200));
      columnSnippets.add(Container(color: Colors.blueAccent, height: height));
      for (var snippet in lyricSnippetList.values.toList()) {
        Color fontColor = const Color(0x00000000);
        if (vocalistColorList.containsKey(snippet.vocalistID)) {
          fontColor = Color(vocalistColorList[snippet.vocalistID]!.color);
        }
        columnSnippets.add(
          getColorHilightedText(snippet, seekPosition, fontSize, fontFamily, fontColor),
        );
      }
      columnSnippets.add(Container(color: const Color.fromARGB(255, 164, 240, 156), height: 1000));
      return Focus(
        focusNode: focusNode,
        child: GestureDetector(
          onTap: () {
            musicPlayerService.playPause();
            focusNode.requestFocus();
            debugPrint("The video pane is focused");
          },
          child: Scrollbar(
            thumbVisibility: true,
            controller: scrollController,
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: columnSnippets,
              ),
            ),
          ),
        ),
      );
    }
      */
  }

  Size getLogicalSize() {
    double pixelRatio = window.devicePixelRatio;
    Size physicalSize = window.physicalSize;
    double logicalWidth = physicalSize.width / pixelRatio;
    double logicalHeight = physicalSize.height / pixelRatio;
    return Size(logicalWidth, logicalHeight);
  }

  void _onScroll() {
    MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    if (!musicPlayerService.isPlaying) {
      int position = getSeekPositionFromScrollOffset(scrollController.offset).round();
      musicPlayerService.seek(position);
    }
    setState(() {});
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}

enum DisplayMode {
  appearDissappear,
  verticalScroll,
}
