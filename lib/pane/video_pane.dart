import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/vocalist.dart';
import 'package:lyric_editor/painter/partial_text_painter.dart';
import 'package:lyric_editor/pane/text_pane.dart';
import 'package:lyric_editor/pane/timeline_pane.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/id_generator.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/utility/utility_functions.dart';
import 'package:tuple/tuple.dart';

final videoPaneMasterProvider = ChangeNotifierProvider((ref) {
  return VideoPaneProvider();
});

class VideoPaneProvider with ChangeNotifier {
  DisplayMode displayMode = DisplayMode.appearDissappear;

  VideoPaneProvider();

  void switchDisplayMode() {
    if (displayMode == DisplayMode.appearDissappear) {
      displayMode = DisplayMode.verticalScroll;
    } else {
      displayMode = DisplayMode.appearDissappear;
    }
    notifyListeners();
  }
}

class VideoPane extends ConsumerStatefulWidget {
  final FocusNode focusNode;

  const VideoPane({required this.focusNode}) : super(key: const Key('VideoPane'));

  @override
  _VideoPaneState createState() => _VideoPaneState(focusNode);
}

class _VideoPaneState extends ConsumerState<VideoPane> {
  final FocusNode focusNode;
  _VideoPaneState(this.focusNode);
  int startBulge = 1000;
  int endBulge = 1000;

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
        int seekPosition = musicPlayerService.seekPosition;
        scrollController.jumpTo(getScrollOffsetFromSeekPosition(seekPosition));
      }
      setState(() {});
    });

    timingService.addListener(() {
      maxLanes = getMaxRequiredLanes(timingService.getTrackNumber(timingService.lyricSnippetList, startBulge, endBulge)) + 1;
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
    return (snippet.startTimestamp + snippet.endTimestamp) / 2;
  }

  double getScrollOffsetFromSeekPosition(int seekPosition) {
    int justBeforeIndex = 0;
    int justAfterIndex = 0;
    double justBeforePosition = 0;
    double justAfterPosition = double.maxFinite;

    final Map<LyricSnippetID, LyricSnippet> lyricSnippetList = ref.read(timingMasterProvider).lyricSnippetList;
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
    final List<LyricSnippet> lyricSnippetList = timingService.lyricSnippetList.values.toList();

    if (scrollOffset < 30) {
      return lyricSnippetList[0].startTimestamp.toDouble();
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

  PartialTextPainter getBeforeSnippetPainter(LyricSnippet snippet, fontFamily, Color fontColor) {
    return PartialTextPainter(
      text: snippet.sentence,
      //start: 0,
      //end: 0,
      progress: 0.0,
      fontFamily: fontFamily,
      fontSize: 40,
      fontBaseColor: fontColor,
      firstOutlineWidth: 2,
      secondOutlineWidth: 4,
    );
  }

  PartialTextPainter getAfterSnippetPainter(LyricSnippet snippet, fontFamily, Color fontColor) {
    return PartialTextPainter(
      text: snippet.sentence,
      //start: 0,
      //end: snippet.sentence.length,
      progress: 1.0,
      fontFamily: fontFamily,
      fontSize: 40,
      fontBaseColor: fontColor,
      firstOutlineWidth: 2,
      secondOutlineWidth: 4,
    );
  }

  double getAnnotationSizePosition(LyricSnippet snippet, int segmentIndex) {
    int startIndex = snippet.annotationMap.keys.toList()[segmentIndex].startIndex;
    double sumPosition = 0;
    int index = 0;
    for (index = 0; index < startIndex; index++) {
      sumPosition += getSizeFromTextStyle(snippet.sentenceSegments[index].word, const TextStyle(fontSize: 40)).width;
    }
    sumPosition += getSizeFromTextStyle(snippet.sentenceSegments[index].word, const TextStyle(fontSize: 40)).width / 2;
    return sumPosition - getSizeFromTextStyle(snippet.sentence, const TextStyle(fontSize: 40)).width / 2;
  }

  Widget snippetItem(LyricSnippet snippet, double sentenceFontSize, double annotationFontSize, String fontFamily) {
    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    int seekPosition = musicPlayerService.seekPosition;

    Color fontColor = const Color(0x00000000);
    final Map<VocalistID, Vocalist> vocalistColorList = ref.read(timingMasterProvider).vocalistColorMap;
    if (vocalistColorList.containsKey(snippet.vocalistID)) {
      fontColor = Color(vocalistColorList[snippet.vocalistID]!.color);
    }

    bool doesAnnotationExist = false;
    if (snippet.annotationMap.isNotEmpty) {
      doesAnnotationExist = true;
    }
    List<Widget> segmentWidgets = [];

    List<Tuple2<SegmentRange, Annotation?>> rangeList = getRangeListForAnnotations(snippet.annotationMap, snippet.sentenceSegments.length);

    for (int rangeIndex = 0; rangeIndex < rangeList.length; rangeIndex++) {
      Tuple2<SegmentRange, Annotation?> element = rangeList[rangeIndex];
      SegmentRange segmentRange = element.item1;
      Annotation? annotation = element.item2;

      if (annotation == null) {
        for (int index = segmentRange.startIndex; index <= segmentRange.endIndex; index++) {
          SentenceSegment segment = snippet.sentenceSegments[index];
          Size sentenceSize = getSizeFromFontInfo(segment.word, sentenceFontSize, fontFamily);
          Size annotationSize = Size(sentenceSize.width, getSizeFromFontInfo("", annotationFontSize, fontFamily).height);

          int segmentStartPosition = snippet.startTimestamp + snippet.timingPoints[index].seekPosition;
          int segmentEndPosition = snippet.startTimestamp + snippet.timingPoints[index + 1].seekPosition;
          double progress = 0.0;
          if (seekPosition < segmentStartPosition) {
            progress = 0.0;
          } else if (seekPosition < segmentEndPosition) {
            progress = (seekPosition - segmentStartPosition) / segment.duration;
          } else {
            progress = 1.0;
          }

          segmentWidgets.add(
            Column(
              children: [
                SizedBox(
                  width: annotationSize.width,
                  height: annotationSize.height,
                ),
                CustomPaint(
                  size: sentenceSize,
                  painter: PartialTextPainter(
                    text: segment.word,
                    progress: progress,
                    fontFamily: fontFamily,
                    fontSize: sentenceFontSize,
                    fontBaseColor: fontColor,
                    firstOutlineWidth: 2,
                    secondOutlineWidth: 4,
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        String partSentence = snippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1).map((segment) => segment.word).join('');
        Size sentenceSize = getSizeFromFontInfo(partSentence, sentenceFontSize, fontFamily);
        Size annotationSize = getSizeFromFontInfo(annotation.sentence, annotationFontSize, fontFamily);
        double width = max(sentenceSize.width, annotationSize.width);

        List<Widget> partSentenceWidgets = [];
        for (int index = segmentRange.startIndex; index <= segmentRange.endIndex; index++) {
          SentenceSegment segment = snippet.sentenceSegments[index];
          int segmentStartPosition = snippet.startTimestamp + snippet.timingPoints[index].seekPosition;
          int segmentEndPosition = snippet.startTimestamp + snippet.timingPoints[index + 1].seekPosition;
          double progress = 0.0;
          if (seekPosition < segmentStartPosition) {
            progress = 0.0;
          } else if (seekPosition < segmentEndPosition) {
            progress = (seekPosition - segmentStartPosition) / segment.duration;
          } else {
            progress = 1.0;
          }

          partSentenceWidgets.add(
            CustomPaint(
              size: getSizeFromFontInfo(segment.word, sentenceFontSize, fontFamily),
              painter: PartialTextPainter(
                text: segment.word,
                progress: progress,
                fontFamily: fontFamily,
                fontSize: sentenceFontSize,
                fontBaseColor: fontColor,
                firstOutlineWidth: 2,
                secondOutlineWidth: 4,
              ),
            ),
          );
        }

        List<Widget> partAnnotationWidgets = [];
        for (int index = 0; index < annotation.sentenceSegments.length; index++) {
          SentenceSegment segment = annotation.sentenceSegments[index];
          int segmentStartPosition = annotation.startTimestamp + annotation.timingPoints[index].seekPosition;
          int segmentEndPosition = annotation.startTimestamp + annotation.timingPoints[index + 1].seekPosition;
          double progress = 0.0;
          if (seekPosition < segmentStartPosition) {
            progress = 0.0;
          } else if (seekPosition < segmentEndPosition) {
            progress = (seekPosition - segmentStartPosition) / segment.duration;
          } else {
            progress = 1.0;
          }

          partAnnotationWidgets.add(
            CustomPaint(
              size: getSizeFromFontInfo(segment.word, annotationFontSize, fontFamily),
              painter: PartialTextPainter(
                text: segment.word,
                progress: progress,
                fontFamily: fontFamily,
                fontSize: annotationFontSize,
                fontBaseColor: fontColor,
                firstOutlineWidth: 2,
                secondOutlineWidth: 4,
              ),
            ),
          );
        }

        segmentWidgets.add(
          Column(
            children: [
              SizedBox(
                width: width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: partAnnotationWidgets,
                ),
              ),
              SizedBox(
                width: width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: partSentenceWidgets,
                ),
              ),
            ],
          ),
        );
      }
    }
    return Wrap(
      children: segmentWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);
    final int seekPosition = musicPlayerService.seekPosition;
    final Map<VocalistID, Vocalist> vocalistColorList = ref.read(timingMasterProvider).vocalistColorMap;

    Map<LyricSnippetID, LyricSnippet> lyricSnippetList = timingService.lyricSnippetList;
    Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition(
      startBulge: startBulge,
      endBulge: endBulge,
    );

    double fontSize = 40.0;
    String fontFamily = "Times New Roman";
    final VideoPaneProvider videoPaneProvider = ref.read(videoPaneMasterProvider);

    DisplayMode displayMode = videoPaneProvider.displayMode;
    //if (displayMode == DisplayMode.appearDissappear) {
    final Map<LyricSnippetID, int> tracks = timingService.getTrackNumber(timingService.lyricSnippetList, startBulge, endBulge);

    List<Widget> content = List<Widget>.generate(maxLanes, (index) => Container());

    for (int i = 0; i < maxLanes; i++) {
      LyricSnippetID targetSnippetID = currentSnippets.keys.toList().firstWhere(
            (LyricSnippetID id) => tracks[id] == i,
            orElse: () => LyricSnippetID(0),
          );
      if (targetSnippetID != LyricSnippetID(0)) {
        LyricSnippet targetSnippet = timingService.getSnippetWithID(targetSnippetID);
        content[i] = Expanded(
          child: Center(
            child: snippetItem(
              targetSnippet,
              fontSize,
              fontSize / 2,
              fontFamily,
            ),
          ),
        );
      } else {
        content[i] = Expanded(
          child: Center(
            child: snippetItem(
              LyricSnippet(
                vocalistID: VocalistID(0),
                startTimestamp: seekPosition,
                sentenceSegments: [SentenceSegment(" ", 1)],
                annotationMap: {},
              ),
              fontSize,
              fontSize / 2,
              fontFamily,
            ),
          ),
        );
      }
    }

    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTap: () {
          musicPlayerService.playPause();
          focusNode.requestFocus();
          debugPrint("The video pane is focused");
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: content,
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
