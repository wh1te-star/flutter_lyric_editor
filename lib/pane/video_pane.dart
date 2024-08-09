import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lyric_editor/painter/partial_text_painter.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:rxdart/rxdart.dart';

class VideoPane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  VideoPane({required this.masterSubject, required this.focusNode}) : super(key: Key('VideoPane'));

  @override
  _VideoPaneState createState() => _VideoPaneState(masterSubject, focusNode);
}

class _VideoPaneState extends State<VideoPane> {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;
  _VideoPaneState(this.masterSubject, this.focusNode);
  bool isPlaying = true;
  int startBulge = 1000;
  int endBulge = 1000;
  int currentSeekPosition = 0;
  List<LyricSnippetTrack> lyricSnippetTrack = [];
  Map<String, int> vocalistColorList = {};
  Map<String, List<String>> vocalistCombinationCorrespondence = {};

  DisplayMode displayMode = DisplayMode.verticalScroll;
  ScrollController scrollController = ScrollController();

  int maxLanes = 0;

  final GlobalKey _videoPaneKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);

    masterSubject.stream.listen((signal) {
      if (signal is RequestSwitchDisplayMode) {
        if (displayMode == DisplayMode.appearDissappear) {
          displayMode = DisplayMode.verticalScroll;
        } else {
          displayMode = DisplayMode.appearDissappear;
        }
      }
      if (signal is NotifyIsPlaying) {
        isPlaying = signal.isPlaying;
      }
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
      setState(() {});
    });
  }

  String defaultText = "Video Pane";

  LyricSnippetTrack getLyricSnippetWithID(LyricSnippetID id) {
    return lyricSnippetTrack.firstWhere((snippet) => snippet.lyricSnippet.id == id);
  }

  List<LyricSnippetTrack> getSnippetsAtCurrentSeekPosition() {
    return lyricSnippetTrack.where((snippet) {
      return snippet.lyricSnippet.startTimestamp - startBulge < currentSeekPosition && currentSeekPosition < snippet.lyricSnippet.endTimestamp + endBulge;
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

  Widget outlinedText(LyricSnippet snippet, String fontFamily) {
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

  @override
  Widget build(BuildContext context) {
    String fontFamily = "Times New Roman";
    List<LyricSnippetTrack> currentSnippets = getSnippetsAtCurrentSeekPosition();

    if (displayMode == DisplayMode.appearDissappear) {
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
            widget.masterSubject.add(RequestPlayPause());
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
            widget.masterSubject.add(RequestPlayPause());
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
    if (!isPlaying) {
      int position = getSeekPositionFromScrollOffset(scrollController.offset).toInt();
      masterSubject.add(RequestSeek(position));
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
