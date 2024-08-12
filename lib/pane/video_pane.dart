import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/painter/partial_text_painter.dart';
import 'package:lyric_editor/pane/text_pane.dart';
import 'package:lyric_editor/pane/timeline_pane.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';

final videoPaneMasterProvider = ChangeNotifierProvider((ref) {
  final musicPlayer = ref.watch(musicPlayerMasterProvider);
  final timing = ref.watch(timingMasterProvider);
  return VideoPaneNotifier(musicPlayer, timing);
});

class VideoPaneNotifier with ChangeNotifier {
  final MusicPlayerNotifier musicPlayerProvider;
  final TimingNotifier timingProvider;

  VideoPaneNotifier(this.musicPlayerProvider, this.timingProvider) {
    musicPlayerProvider.addListener(() {});
    timingProvider.addListener(() {
      lyricSnippetTrack = assignTrackNumber(timingProvider.lyricSnippetList);
    });
  }

  bool isPlaying = true;
  int startBulge = 1000;
  int endBulge = 1000;
  int currentSeekPosition = 0;
  List<LyricSnippetTrack> lyricSnippetTrack = [];
  DisplayMode displayMode = DisplayMode.verticalScroll;

  int maxLanes = 0;

  requestSwitchDisplayMode() {
    if (displayMode == DisplayMode.appearDissappear) {
      displayMode = DisplayMode.verticalScroll;
    } else {
      displayMode = DisplayMode.appearDissappear;
    }
  }

  LyricSnippetTrack getLyricSnippetWithID(LyricSnippetID id) {
    return lyricSnippetTrack.firstWhere((snippet) => snippet.lyricSnippet.id == id);
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
}

class VideoPane extends ConsumerStatefulWidget {
  final FocusNode focusNode;

  VideoPane(this.focusNode);
  @override
  _VideoPaneState createState() => _VideoPaneState(focusNode);
}

class _VideoPaneState extends ConsumerState<VideoPane> {
  final FocusNode focusNode;
  late final KeyboardShortcutsNotifier keyboardShortcutsProvider = ref.watch(keyboardShortcutsMasterProvider);
  late final MusicPlayerNotifier musicPlayerProvider = ref.watch(musicPlayerMasterProvider);
  late final TimingNotifier timingProvider = ref.watch(timingMasterProvider);
  late final TextPaneNotifier textPaneProvider = ref.watch(textPaneMasterProvider);
  late final TimelinePaneNotifier timelinePaneProvider = ref.watch(timelinePaneMasterProvider);
  late final VideoPaneNotifier videoPaneProvider = ref.watch(videoPaneMasterProvider);

  _VideoPaneState(this.focusNode);

  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);

    /*
      if (signal is NotifySeekPosition) {
        currentSeekPosition = signal.seekPosition;
        if (displayMode == DisplayMode.verticalScroll && isPlaying) {
          scrollController.jumpTo(getScrollOffsetFromSeekPosition(currentSeekPosition));
        }
      }
      if (signal is NotifyLyricParsed) {
        lyricSnippetTrack = assignTrackNumber(signal.lyricSnippetList);
        vocalistColorList = signal.vocalistColorList;
        vocalistCombinationCorrespondence = signal.vocalistCombinationCorrespondence;
      }
      if (signal is NotifySnippetDivided || signal is NotifySnippetConcatenated || signal is NotifyUndo) {
        lyricSnippetTrack = assignTrackNumber(signal.lyricSnippetList);
      }
      if (signal is NotifyTimingPointAdded || signal is NotifyTimingPointDeleted) {
        lyricSnippetTrack = assignTrackNumber(signal.lyricSnippetList);
      }
      */
  }

  String defaultText = "Video Pane";

  @override
  Widget build(BuildContext context) {
    ref.listen<KeyboardShortcutsNotifier>(keyboardShortcutsMasterProvider, (previous, current) {
      setState(() {});
    });
    ref.listen<MusicPlayerNotifier>(musicPlayerMasterProvider, (previous, current) {
      setState(() {});
      if (videoPaneProvider.displayMode == DisplayMode.verticalScroll && musicPlayerProvider.isPlaying) {
        scrollController.jumpTo(getScrollOffsetFromSeekPosition(musicPlayerProvider.seekPosition));
      }
    });
    ref.listen<TimingNotifier>(timingMasterProvider, (previous, current) {
      setState(() {});
    });
    ref.listen<TextPaneNotifier>(textPaneMasterProvider, (previous, current) {
      setState(() {});
    });
    ref.listen<TimelinePaneNotifier>(timelinePaneMasterProvider, (previous, current) {
      setState(() {});
    });
    ref.listen<VideoPaneNotifier>(videoPaneMasterProvider, (previous, current) {
      setState(() {});
    });

    String fontFamily = "Times New Roman";
    List<LyricSnippetTrack> currentSnippets = getSnippetsAtCurrentSeekPosition();

    if (videoPaneProvider.displayMode == DisplayMode.appearDissappear) {
      int maxLanes = videoPaneProvider.maxLanes;
      int currentSeekPosition = musicPlayerProvider.seekPosition;
      LyricSnippet emptySnippet = LyricSnippet(vocalist: Vocalist("", 0), index: 0, sentence: "", startTimestamp: currentSeekPosition, timingPoints: [TimingPoint(1, 1)]);
      List<Widget> content = List<Widget>.generate(maxLanes, (index) => Container());

      for (int i = 0; i < maxLanes; i++) {
        LyricSnippet targetSnippet = currentSnippets
            .firstWhere(
              (LyricSnippetTrack snippet) => snippet.trackNumber == i,
              orElse: () => LyricSnippetTrack(emptySnippet, i),
            )
            .lyricSnippet;
        content[i] = outlinedText(targetSnippet, fontFamily);
      }

      return Focus(
        focusNode: focusNode,
        child: GestureDetector(
          onTap: () {
            musicPlayerProvider.requestPlayPause();
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

      List<LyricSnippetTrack> lyricSnippetTrack = videoPaneProvider.lyricSnippetTrack;
      Map<String, int> vocalistColorList = timingProvider.vocalistColorList;
      lyricSnippetTrack.forEach((LyricSnippetTrack trackSnippet) {
        LyricSnippet snippet = trackSnippet.lyricSnippet;
        Color fontColor = Color(0);
        if (vocalistColorList.containsKey(snippet.vocalist.name)) {
          fontColor = Color(vocalistColorList[snippet.vocalist.name]!);
        }
        int currentSeekPosition = musicPlayerProvider.seekPosition;
        columnSnippets.add(
          CustomPaint(
            painter: getColorHilightedText(snippet, currentSeekPosition, fontFamily, fontColor),
            size: Size(double.infinity, height),
          ),
        );
      });
      columnSnippets.add(Container(color: Color.fromARGB(255, 164, 240, 156), height: 1000));
      return Focus(
        focusNode: focusNode,
        child: GestureDetector(
          onTap: () {
            musicPlayerProvider.requestPlayPause();
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

  Widget outlinedText(LyricSnippet snippet, String fontFamily) {
    Map<String, int> vocalistColorList = timingProvider.vocalistColorList;
    int currentSeekPosition = musicPlayerProvider.seekPosition;
    Color fontColor = Color(0);
    if (vocalistColorList.containsKey(snippet.vocalist.name)) {
      fontColor = Color(vocalistColorList[snippet.vocalist.name]!);
    }
    return Expanded(
      child: CustomPaint(
        painter: getColorHilightedText(snippet, currentSeekPosition, fontFamily, fontColor),
        size: Size(double.infinity, double.infinity),
      ),
    );
  }

  PartialTextPainter getColorHilightedText(LyricSnippet snippet, int seekPosition, String fontFamily, Color fontColor) {
    int currentSeekPosition = musicPlayerProvider.seekPosition;
    if (currentSeekPosition < snippet.startTimestamp) {
      return getBeforeSnippetPainter(snippet, fontFamily, fontColor);
    } else if (snippet.endTimestamp < currentSeekPosition) {
      return getAfterSnippetPainter(snippet, fontFamily, fontColor);
    } else {
      int wordIndex = 0;
      int startChar = 0;
      int restDuration = seekPosition - snippet.startTimestamp;
      while (restDuration - snippet.timingPoints[wordIndex].wordDuration > 0) {
        startChar += snippet.timingPoints[wordIndex].wordLength;
        restDuration -= snippet.timingPoints[wordIndex].wordDuration;
        wordIndex++;
      }
      double percent;
      percent = restDuration / snippet.timingPoints[wordIndex].wordDuration;
      return PartialTextPainter(
        text: snippet.sentence,
        start: startChar,
        end: startChar + snippet.timingPoints[wordIndex].wordLength,
        percent: percent,
        fontFamily: fontFamily,
        fontSize: 40,
        fontBaseColor: fontColor,
        firstOutlineWidth: 2,
        secondOutlineWidth: 4,
      );
    }
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

  double getSeekPositionFromScrollOffset(double scrollOffset) {
    List<LyricSnippetTrack> lyricSnippetTrack = videoPaneProvider.lyricSnippetTrack;
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

  List<LyricSnippetTrack> getSnippetsAtCurrentSeekPosition() {
    List<LyricSnippetTrack> lyricSnippetTrack = videoPaneProvider.lyricSnippetTrack;
    int currentSeekPosition = musicPlayerProvider.seekPosition;
    int startBulge = videoPaneProvider.startBulge;
    int endBulge = videoPaneProvider.endBulge;
    return lyricSnippetTrack.where((snippet) {
      return snippet.lyricSnippet.startTimestamp - startBulge < currentSeekPosition && currentSeekPosition < snippet.lyricSnippet.endTimestamp + endBulge;
    }).toList();
  }

  double getMiddlePoint(LyricSnippet snippet) {
    return (snippet.startTimestamp + snippet.endTimestamp) / 2;
  }

  double getScrollOffsetFromSeekPosition(int seekPosition) {
    List<LyricSnippetTrack> lyricSnippetTrack = videoPaneProvider.lyricSnippetTrack;
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

  void _onScroll() {
    if (!musicPlayerProvider.isPlaying) {
      int position = getSeekPositionFromScrollOffset(scrollController.offset).toInt();
      musicPlayerProvider.requestSeek(position);
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
