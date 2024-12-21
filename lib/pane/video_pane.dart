import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/painter/partial_text_painter.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/text_size_functions.dart';

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

  VideoPane({required this.focusNode}) : super(key: const Key('VideoPane'));

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
  }

  String defaultText = "Video Pane";

  int getMaxRequiredLanes(Map<SnippetID, int> lyricSnippetList) {
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

    final Map<SnippetID, LyricSnippet> lyricSnippetList = ref.read(timingMasterProvider).lyricSnippetList;
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
      rate: 0.0,
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
      rate: 1.0,
      fontFamily: fontFamily,
      fontSize: 40,
      fontBaseColor: fontColor,
      firstOutlineWidth: 2,
      secondOutlineWidth: 4,
    );
  }

  double getAnnotationSizePosition(LyricSnippet snippet, int segmentIndex) {
    int startIndex = snippet.annotations.keys.toList()[segmentIndex].startIndex;
    double sumPosition = 0;
    int index = 0;
    for (index = 0; index < startIndex; index++) {
      sumPosition += getSizeFromTextStyle(snippet.sentenceSegments[index].word, TextStyle(fontSize: 40)).width;
    }
    sumPosition += getSizeFromTextStyle(snippet.sentenceSegments[index].word, TextStyle(fontSize: 40)).width / 2;
    return sumPosition - getSizeFromTextStyle(snippet.sentence, TextStyle(fontSize: 40)).width / 2;
  }

  Widget getColorHilightedText(LyricSnippet snippet, int seekPosition, double fontSize, String fontFamily, Color fontColor) {
    int seekPosition = ref.read(musicPlayerMasterProvider).seekPosition;
    Size annotationSize = getSizeFromFontInfo(snippet.sentence, fontSize / 2, fontFamily);
    Size sentenceSize = getSizeFromFontInfo(snippet.sentence, fontSize, fontFamily);
    Size snippetSize = Size(sentenceSize.width, sentenceSize.height + annotationSize.height);
    if (seekPosition < snippet.startTimestamp) {
      return CustomPaint(
        painter: getBeforeSnippetPainter(snippet, fontFamily, fontColor),
        size: snippetSize,
      );
    } else if (snippet.endTimestamp < seekPosition) {
      return CustomPaint(
        painter: getAfterSnippetPainter(snippet, fontFamily, fontColor),
        size: snippetSize,
      );
    } else {
      int wordIndex = 0;
      int startChar = 0;
      int restDuration = seekPosition - snippet.startTimestamp;
      while (restDuration - snippet.sentenceSegments[wordIndex].duration > 0) {
        startChar += snippet.sentenceSegments[wordIndex].word.length;
        restDuration -= snippet.sentenceSegments[wordIndex].duration;
        wordIndex++;
      }
      double percent;
      percent = restDuration / snippet.sentenceSegments[wordIndex].duration;
      return Stack(
        children: [
          CustomPaint(
            painter: PartialTextPainter(
              text: snippet.sentence,
              //start: startChar,
              //end: startChar + snippet.sentenceSegments[wordIndex].word.length,
              rate: percent,
              fontFamily: fontFamily,
              fontSize: fontSize,
              fontBaseColor: fontColor,
              firstOutlineWidth: 2,
              secondOutlineWidth: 4,
            ),
            size: snippetSize,
          ),
          Positioned(
            left: snippet.annotations.length == 0 ? 5.0 : getAnnotationSizePosition(snippet, 0),
            top: -30.0,
            child: snippet.annotations.isEmpty
                ? CustomPaint()
                : CustomPaint(
                    painter: PartialTextPainter(
                      text: snippet.annotations.entries.first.value.sentence,
                      //start: 0,
                      //end: snippet.annotations.entries.first.value.sentence.length,
                      rate: percent,
                      fontFamily: fontFamily,
                      fontSize: fontSize / 2.0,
                      fontBaseColor: fontColor,
                      firstOutlineWidth: 2,
                      secondOutlineWidth: 4,
                    ),
                    size: snippetSize,
                  ),
          ),
        ],
      );
    }
  }

  Widget snippetItem(LyricSnippet snippet, double fontSize, String fontFamily) {
    int seekPosition = ref.read(musicPlayerMasterProvider).seekPosition;
    Color fontColor = const Color(0x00000000);
    final Map<VocalistID, Vocalist> vocalistColorList = ref.read(timingMasterProvider).vocalistColorMap;
    if (vocalistColorList.containsKey(snippet.vocalistID)) {
      fontColor = Color(vocalistColorList[snippet.vocalistID]!.color);
    }
    if (snippet.sentence == "") {
      return Expanded(
        child: CustomPaint(
          painter: PartialTextPainter(
            text: "",
            //start: 0,
            //end: 0,
            rate: 0.0,
            fontFamily: fontFamily,
            fontSize: fontSize,
            fontBaseColor: fontColor,
            firstOutlineWidth: 2,
            secondOutlineWidth: 4,
          ),
          size: const Size(double.infinity, double.infinity),
        ),
      );
    } else {
      return Expanded(
        child: getColorHilightedText(snippet, seekPosition, fontSize, fontFamily, fontColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);
    final int seekPosition = musicPlayerService.seekPosition;
    final Map<VocalistID, Vocalist> vocalistColorList = ref.read(timingMasterProvider).vocalistColorMap;

    Map<SnippetID, LyricSnippet> lyricSnippetList = timingService.lyricSnippetList;
    Map<SnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition(
      startBulge: startBulge,
      endBulge: endBulge,
    );

    double fontSize = 40.0;
    String fontFamily = "Times New Roman";
    final VideoPaneProvider videoPaneProvider = ref.read(videoPaneMasterProvider);
    DisplayMode displayMode = videoPaneProvider.displayMode;
    if (displayMode == DisplayMode.appearDissappear) {
      final Map<SnippetID, int> tracks = timingService.getTrackNumber(timingService.lyricSnippetList, startBulge, endBulge);

      List<Widget> content = List<Widget>.generate(maxLanes, (index) => Container());

      for (int i = 0; i < maxLanes; i++) {
        SnippetID targetSnippetID = currentSnippets.keys.toList().firstWhere(
              (SnippetID id) => tracks[id] == i,
              orElse: () => SnippetID(0),
            );
        LyricSnippet targetSnippet = targetSnippetID == SnippetID(0) ? LyricSnippet.emptySnippet : lyricSnippetList[targetSnippetID]!;
        content[i] = snippetItem(targetSnippet, fontSize, fontFamily);
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
