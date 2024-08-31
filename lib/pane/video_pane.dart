import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/painter/partial_text_painter.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:rxdart/rxdart.dart';

final videoPaneMasterProvider = ChangeNotifierProvider((ref) {
  return VideoPaneProvider();
});

class VideoPaneProvider with ChangeNotifier {
  DisplayMode displayMode = DisplayMode.verticalScroll;

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

  VideoPane({required this.focusNode}) : super(key: Key('VideoPane'));

  @override
  _VideoPaneState createState() => _VideoPaneState(focusNode);
}

class _VideoPaneState extends ConsumerState<VideoPane> {
  final FocusNode focusNode;
  _VideoPaneState(this.focusNode);
  int startBulge = 1000;
  int endBulge = 1000;
  List<LyricSnippetTrack> lyricSnippetTrack = [];

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
      int seekPosition = musicPlayerService.seekPosition;
      bool isPlaying = musicPlayerService.isPlaying;
      if (videoPaneProvider.displayMode == DisplayMode.verticalScroll && isPlaying) {
        scrollController.jumpTo(getScrollOffsetFromSeekPosition(seekPosition));
      }
      setState(() {});
    });

    timingService.addListener(() {
      lyricSnippetTrack = assignTrackNumber(timingService.lyricSnippetList);
      setState(() {});
    });

    videoPaneProvider.addListener(() {
      setState(() {});
    });
  }

  String defaultText = "Video Pane";

  LyricSnippetTrack getLyricSnippetWithID(SnippetID id) {
    return lyricSnippetTrack.firstWhere((snippet) => snippet.lyricSnippet.id == id);
  }

  List<LyricSnippetTrack> getSnippetsAtCurrentSeekPosition() {
    int seekPosition = ref.read(musicPlayerMasterProvider).seekPosition;
    return lyricSnippetTrack.where((snippet) {
      return snippet.lyricSnippet.startTimestamp - startBulge < seekPosition && seekPosition < snippet.lyricSnippet.endTimestamp + endBulge;
    }).toList();
  }

  List<LyricSnippetTrack> assignTrackNumber(List<LyricSnippet> lyricSnippetList) {
    if (lyricSnippetList.isEmpty) return [];
    lyricSnippetList.sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));

    List<LyricSnippetTrack> lyricSnippetTrack = [];

    int maxOverlap = 0;
    int currentOverlap = 1;
    int currentEndTime = lyricSnippetList[0].endTimestamp + endBulge;
    lyricSnippetTrack.add(LyricSnippetTrack(lyricSnippetList[0], 0));

    for (int i = 1; i < lyricSnippetList.length; ++i) {
      int start = lyricSnippetList[i].startTimestamp - startBulge;
      int end = lyricSnippetList[i].endTimestamp + endBulge;
      if (start <= currentEndTime) {
        currentOverlap++;
      } else {
        currentOverlap = 1;
        currentEndTime = end;
      }
      if (currentOverlap > maxOverlap) {
        maxOverlap = currentOverlap;
      }

      lyricSnippetTrack.add(LyricSnippetTrack(lyricSnippetList[i], currentOverlap - 1));
      if (currentOverlap > maxLanes) {
        maxLanes = currentOverlap;
      }
    }

    return lyricSnippetTrack;
  }

  double getMiddlePoint(LyricSnippet snippet) {
    return (snippet.startTimestamp + snippet.endTimestamp) / 2;
  }

  double getScrollOffsetFromSeekPosition(int seekPosition) {
    int justBeforeIndex = 0;
    int justAfterIndex = 0;
    double justBeforePosition = 0;
    double justAfterPosition = 240000;
    for (int index = 0; index < lyricSnippetTrack.length; index++) {
      double currentTime = getMiddlePoint(lyricSnippetTrack[index].lyricSnippet);
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
    if (scrollOffset < 30) {
      return lyricSnippetTrack[0].lyricSnippet.startTimestamp.toDouble();
    }
    int snippetIndex = (scrollOffset - 30) ~/ 60;
    debugPrint("scroll offset: ${scrollOffset}, snippetIndex: ${snippetIndex}");
    late double startPosition;
    late double endPosition;
    if ((scrollOffset - 30) % 60 < 30) {
      if (snippetIndex == 0) {
        startPosition = 2 * getMiddlePoint(lyricSnippetTrack[snippetIndex].lyricSnippet) - getMiddlePoint(lyricSnippetTrack[snippetIndex + 1].lyricSnippet);
      } else {
        startPosition = getMiddlePoint(lyricSnippetTrack[snippetIndex - 1].lyricSnippet);
      }
      endPosition = getMiddlePoint(lyricSnippetTrack[snippetIndex].lyricSnippet);
    } else {
      startPosition = getMiddlePoint(lyricSnippetTrack[snippetIndex].lyricSnippet);
      endPosition = getMiddlePoint(lyricSnippetTrack[snippetIndex + 1].lyricSnippet);
    }
    double scrollExtra = (scrollOffset % 60) / 60;
    double seekPosition = startPosition + (endPosition - startPosition) * scrollExtra;
    return seekPosition;
  }

  PartialTextPainter getBeforeSnippetPainter(LyricSnippet snippet, fontFamily, Color fontColor) {
    return PartialTextPainter(
      text: snippet.sentence,
      start: 0,
      end: 0,
      percent: 0.0,
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
      start: 0,
      end: snippet.sentence.length,
      percent: 1.0,
      fontFamily: fontFamily,
      fontSize: 40,
      fontBaseColor: fontColor,
      firstOutlineWidth: 2,
      secondOutlineWidth: 4,
    );
  }

  PartialTextPainter getColorHilightedText(LyricSnippet snippet, int seekPosition, String fontFamily, Color fontColor) {
    int seekPosition = ref.read(musicPlayerMasterProvider).seekPosition;
    if (seekPosition < snippet.startTimestamp) {
      return getBeforeSnippetPainter(snippet, fontFamily, fontColor);
    } else if (snippet.endTimestamp < seekPosition) {
      return getAfterSnippetPainter(snippet, fontFamily, fontColor);
    } else {
      int wordIndex = 0;
      int startChar = 0;
      int restDuration = seekPosition - snippet.startTimestamp;
      while (restDuration - snippet.sentenceSegments[wordIndex].wordDuration > 0) {
        startChar += snippet.sentenceSegments[wordIndex].wordLength;
        restDuration -= snippet.sentenceSegments[wordIndex].wordDuration;
        wordIndex++;
      }
      double percent;
      percent = restDuration / snippet.sentenceSegments[wordIndex].wordDuration;
      return PartialTextPainter(
        text: snippet.sentence,
        start: startChar,
        end: startChar + snippet.sentenceSegments[wordIndex].wordLength,
        percent: percent,
        fontFamily: fontFamily,
        fontSize: 40,
        fontBaseColor: fontColor,
        firstOutlineWidth: 2,
        secondOutlineWidth: 4,
      );
    }
  }

  Widget outlinedText(LyricSnippet snippet, String fontFamily) {
    int seekPosition = ref.read(musicPlayerMasterProvider).seekPosition;
    Color fontColor = Color(0);
    final Map<String, int> vocalistColorList = ref.read(timingMasterProvider).vocalistColorMap;
    if (vocalistColorList.containsKey(snippet.vocalist.name)) {
      fontColor = Color(vocalistColorList[snippet.vocalist.name]!);
    }
    if (snippet.sentence == "") {
      return Expanded(
        child: CustomPaint(
          painter: PartialTextPainter(
            text: "",
            start: 0,
            end: 0,
            percent: 0.0,
            fontFamily: fontFamily,
            fontSize: 40,
            fontBaseColor: fontColor,
            firstOutlineWidth: 2,
            secondOutlineWidth: 4,
          ),
          size: Size(double.infinity, double.infinity),
        ),
      );
    } else {
      return Expanded(
        child: CustomPaint(
          painter: getColorHilightedText(snippet, seekPosition, fontFamily, fontColor),
          size: Size(double.infinity, double.infinity),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    int seekPosition = musicPlayerService.seekPosition;
    final Map<String, int> vocalistColorList = ref.read(timingMasterProvider).vocalistColorMap;

    String fontFamily = "Times New Roman";
    List<LyricSnippetTrack> currentSnippets = getSnippetsAtCurrentSeekPosition();

    final VideoPaneProvider videoPaneProvider = ref.read(videoPaneMasterProvider);
    DisplayMode displayMode = videoPaneProvider.displayMode;
    if (displayMode == DisplayMode.appearDissappear) {
      List<Widget> content = List<Widget>.generate(maxLanes, (index) => Container());

      for (int i = 0; i < maxLanes; i++) {
        LyricSnippet targetSnippet = currentSnippets
            .firstWhere(
              (LyricSnippetTrack snippet) => snippet.trackNumber == i,
              orElse: () => LyricSnippetTrack(LyricSnippet.emptySnippet, i),
            )
            .lyricSnippet;
        content[i] = outlinedText(targetSnippet, fontFamily);
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
      columnSnippets.add(Container(color: Color.fromARGB(255, 164, 240, 156), height: 200));
      columnSnippets.add(Container(color: Colors.blueAccent, height: height));
      lyricSnippetTrack.forEach((LyricSnippetTrack trackSnippet) {
        LyricSnippet snippet = trackSnippet.lyricSnippet;
        Color fontColor = Color(0);
        if (vocalistColorList.containsKey(snippet.vocalist.name)) {
          fontColor = Color(vocalistColorList[snippet.vocalist.name]!);
        }
        columnSnippets.add(
          CustomPaint(
            painter: getColorHilightedText(snippet, seekPosition, fontFamily, fontColor),
            size: Size(double.infinity, height),
          ),
        );
      });
      columnSnippets.add(Container(color: Color.fromARGB(255, 164, 240, 156), height: 1000));
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

  void _onScroll() {
    MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    if (!musicPlayerService.isPlaying) {
      int position = getSeekPositionFromScrollOffset(scrollController.offset).toInt();
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

class LyricSnippetTrack {
  LyricSnippet lyricSnippet;
  int trackNumber;
  LyricSnippetTrack(this.lyricSnippet, this.trackNumber);
}

enum DisplayMode {
  appearDissappear,
  verticalScroll,
}
