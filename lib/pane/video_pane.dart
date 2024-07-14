import 'package:flutter/material.dart';
import 'package:lyric_editor/painter/partial_text_painter.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:rxdart/rxdart.dart';

class VideoPane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  VideoPane({required this.masterSubject, required this.focusNode})
      : super(key: Key('VideoPane'));

  @override
  _VideoPaneState createState() => _VideoPaneState(masterSubject, focusNode);
}

class _VideoPaneState extends State<VideoPane> {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;
  _VideoPaneState(this.masterSubject, this.focusNode);
  bool isPlaying = true;
  int currentSeekPosition = 0;
  List<LyricSnippet> lyricSnippetList = [];
  Map<String, int> vocalistColorList = {};
  Map<String, List<String>> vocalistCombinationCorrespondence = {};

  int maxLanes = 0;

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {
      if (signal is NotifyIsPlaying) {
        isPlaying = signal.isPlaying;
      }
      if (signal is NotifySeekPosition) {
        currentSeekPosition = signal.seekPosition;
      }
      if (signal is NotifyLyricParsed) {
        lyricSnippetList = signal.lyricSnippetList;
        vocalistColorList = signal.vocalistColorList;
        vocalistCombinationCorrespondence =
            signal.vocalistCombinationCorrespondence;
        maxLanes = getMaxLanes(lyricSnippetList);
      }
      if (signal is NotifySnippetDivided ||
          signal is NotifySnippetConcatenated) {
        lyricSnippetList = signal.lyricSnippetList;
        maxLanes = getMaxLanes(lyricSnippetList);
      }
      if (signal is NotifyTimingPointAdded ||
          signal is NotifyTimingPointDeletion) {
        LyricSnippet snippet = getLyricSnippetWithID(signal.snippetID);
        snippet.timingPoints = signal.timingPoints;
      }
      setState(() {});
    });
  }

  String defaultText = "Video Pane";

  LyricSnippet getLyricSnippetWithID(LyricSnippetID id) {
    return lyricSnippetList.firstWhere((snippet) => snippet.id == id);
  }

  Widget outlinedText(LyricSnippet snippet, String fontFamily) {
    int currentCharIndex = snippet.timingPoints.length - 1;
    List<TimingPoint> accumulatedTimingPoints = getAccumulatedTimingPoints(
        snippet.startTimestamp, snippet.timingPoints);
    for (int currentIndex = 0;
        currentIndex < snippet.timingPoints.length - 1;
        currentIndex++) {
      if (accumulatedTimingPoints[currentIndex].wordDuration <=
              currentSeekPosition &&
          currentSeekPosition <=
              accumulatedTimingPoints[currentIndex + 1].wordDuration) {
        currentCharIndex = currentIndex;
      }
    }
    int startChar = 0;
    for (int currentIndex = 0;
        currentIndex < currentCharIndex;
        currentIndex++) {
      startChar += snippet.timingPoints[currentIndex].wordLength;
    }
    double percent;
    percent = (currentSeekPosition -
            accumulatedTimingPoints[currentCharIndex].wordDuration) /
        snippet.timingPoints[currentCharIndex].wordDuration;
    Color fontColor = Color(0);
    if (vocalistColorList.containsKey(snippet.vocalist.name)) {
      fontColor = Color(vocalistColorList[snippet.vocalist.name]!);
    }
    return Expanded(
      child: CustomPaint(
        painter: PartialTextPainter(
          text: snippet.sentence,
          start: startChar,
          end: startChar + snippet.timingPoints[currentCharIndex].wordLength,
          percent: percent,
          fontFamily: fontFamily,
          fontSize: 40,
          fontBaseColor: fontColor,
          firstOutlineWidth: 2,
          secondOutlineWidth: 4,
        ),
        size: Size(double.infinity, double.infinity),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fontFamily = "Times New Roman";
    List<LyricSnippet> currentSnippets = getSnippetsAtCurrentSeekPosition();

    LyricSnippet emptySnippet = LyricSnippet(
        vocalist: Vocalist("", 0),
        index: 0,
        sentence: "",
        startTimestamp: currentSeekPosition,
        timingPoints: [TimingPoint(1, 1)]);
    List<Widget> content =
        List<Widget>.generate(maxLanes, (index) => Container());
    for (int i = 0; i < content.length && i < maxLanes; i++) {
      if (i < currentSnippets.length) {
        content[i] = outlinedText(currentSnippets[i], fontFamily);
      } else {
        content[i] = outlinedText(emptySnippet, fontFamily);
      }
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
  }

  int getMaxLanes(List<LyricSnippet> lyricSnippetList) {
    if (lyricSnippetList.isEmpty) return 0;

    lyricSnippetList
        .sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));

    int maxOverlap = 0;
    int currentOverlap = 0;
    int currentEndTime = lyricSnippetList[0].endTimestamp;

    for (int i = 1; i < lyricSnippetList.length; ++i) {
      if (lyricSnippetList[i].startTimestamp <= currentEndTime) {
        ++currentOverlap;
      } else {
        currentOverlap = 1;
        currentEndTime = lyricSnippetList[i].endTimestamp;
      }
      if (currentOverlap > maxOverlap) {
        maxOverlap = currentOverlap;
      }
    }

    return maxOverlap;
  }

  List<LyricSnippet> getSnippetsAtCurrentSeekPosition() {
    return lyricSnippetList.where((snippet) {
      return snippet.startTimestamp < currentSeekPosition &&
          currentSeekPosition < snippet.endTimestamp;
    }).toList();
  }

  List<TimingPoint> getAccumulatedTimingPoints(
      int startTime, List<TimingPoint> timingPoints) {
    List<TimingPoint> accumulatedList = [];

    accumulatedList.add(TimingPoint(0, startTime));
    for (int i = 0; i < timingPoints.length - 1; i++) {
      accumulatedList.add(TimingPoint(
          accumulatedList.last.wordLength + timingPoints[i].wordLength,
          accumulatedList.last.wordDuration + timingPoints[i].wordDuration));
    }
    return accumulatedList;
  }
}
