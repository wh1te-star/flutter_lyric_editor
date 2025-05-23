import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/pane/text_pane/text_pane_provider.dart';
import 'package:lyric_editor/pane/video_pane/colored_caption.dart';
import 'package:lyric_editor/pane/video_pane/show_hide_mode/show_hide_mode_screen.dart';
import 'package:lyric_editor/pane/video_pane/video_pane_provider.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/pane/video_pane/colored_text_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/timeline_pane.dart';
import 'package:lyric_editor/position/word_index.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';
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

  int getMaxRequiredLanes(Map<SentenceID, int> sentenceList) {
    return sentenceList.values.toList().reduce(max);
  }

  double getMiddlePoint(Sentence sentence) {
    return (sentence.startTimestamp.position + sentence.endTimestamp.position) / 2;
  }

  double getScrollOffsetFromSeekPosition(int seekPosition) {
    int justBeforeIndex = 0;
    int justAfterIndex = 0;
    double justBeforePosition = 0;
    double justAfterPosition = double.maxFinite;

    final Map<SentenceID, Sentence> sentenceList = ref.read(timingMasterProvider).sentenceMap.map;
    for (int index = 0; index < sentenceList.length; index++) {
      double currentTime = getMiddlePoint(sentenceList.values.toList()[index]);
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

    double sentenceOffset = (justAfterIndex - justBeforeIndex) * 60;
    double midSentenceOffset = sentenceOffset * (seekPosition - justBeforePosition) / (justAfterPosition - justBeforePosition);
    double scrollOffset = 60.0 * (justBeforeIndex + 1) + midSentenceOffset;

    return scrollOffset;
  }

  double getSeekPositionFromScrollOffset(double scrollOffset) {
    final TimingService timingService = ref.read(timingMasterProvider);
    final List<Sentence> sentenceList = timingService.sentenceMap.values.toList();

    if (scrollOffset < 30) {
      return sentenceList[0].startTimestamp.position.toDouble();
    }
    int sentenceIndex = (scrollOffset - 30) ~/ 60;
    debugPrint("scroll offset: $scrollOffset, sentenceIndex: $sentenceIndex");
    late double startPosition;
    late double endPosition;
    if ((scrollOffset - 30) % 60 < 30) {
      if (sentenceIndex == 0) {
        startPosition = 2 * getMiddlePoint(sentenceList[sentenceIndex]) - getMiddlePoint(sentenceList[sentenceIndex + 1]);
      } else {
        startPosition = getMiddlePoint(sentenceList[sentenceIndex - 1]);
      }
      endPosition = getMiddlePoint(sentenceList[sentenceIndex]);
    } else {
      startPosition = getMiddlePoint(sentenceList[sentenceIndex]);
      endPosition = getMiddlePoint(sentenceList[sentenceIndex + 1]);
    }
    double scrollExtra = (scrollOffset % 60) / 60;
    double seekPosition = startPosition + (endPosition - startPosition) * scrollExtra;
    return seekPosition;
  }

  double getRubySizePosition(Sentence sentence, WordIndex wordIndex) {
    int startIndex = sentence.rubyMap.map.keys.toList()[wordIndex.index].startIndex.index;
    double sumPosition = 0;
    int index = 0;
    for (index = 0; index < startIndex; index++) {
      sumPosition += getSizeFromTextStyle(sentence.words[index].word, const TextStyle(fontSize: 40)).width;
    }
    sumPosition += getSizeFromTextStyle(sentence.words[index].word, const TextStyle(fontSize: 40)).width / 2;
    return sumPosition - getSizeFromTextStyle(sentence.sentence, const TextStyle(fontSize: 40)).width / 2;
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
          sentenceMap: timingService.sentenceMap,
          vocalistColorMap: timingService.vocalistColorMap,
          seekPosition: musicPlayerService.seekPosition,
        ),
      ),
    );
    /*
    } else {
      double height = 60;
      List<Widget> columnSentences = [];
      columnSentences.add(Container(color: const Color.fromARGB(255, 164, 240, 156), height: 200));
      columnSentences.add(Container(color: Colors.blueAccent, height: height));
      for (var sentence in lyricSentenceList.values.toList()) {
        Color fontColor = const Color(0x00000000);
        if (vocalistColorList.containsKey(sentence.vocalistID)) {
          fontColor = Color(vocalistColorList[sentence.vocalistID]!.color);
        }
        columnSentences.add(
          getColorHilightedText(sentence, seekPosition, fontSize, fontFamily, fontColor),
        );
      }
      columnSentences.add(Container(color: const Color.fromARGB(255, 164, 240, 156), height: 1000));
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
                children: columnSentences,
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
