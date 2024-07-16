import 'package:collection/collection.dart';
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
  int startBulge = 1000;
  int endBulge = 1000;
  int currentSeekPosition = 0;
  List<LyricSnippetTrack> lyricSnippetTrack = [];
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
        lyricSnippetTrack = assignTrackNumber(signal.lyricSnippetList);
        vocalistColorList = signal.vocalistColorList;
        vocalistCombinationCorrespondence =
            signal.vocalistCombinationCorrespondence;
      }
      if (signal is NotifySnippetDivided ||
          signal is NotifySnippetConcatenated) {
        lyricSnippetTrack = signal.lyricSnippetList;
      }
      if (signal is NotifyTimingPointAdded ||
          signal is NotifyTimingPointDeletion) {
        LyricSnippet snippet =
            getLyricSnippetWithID(signal.snippetID).lyricSnippet;
        snippet.timingPoints = signal.timingPoints;
      }
      setState(() {});
    });
  }

  String defaultText = "Video Pane";

  LyricSnippetTrack getLyricSnippetWithID(LyricSnippetID id) {
    return lyricSnippetTrack
        .firstWhere((snippet) => snippet.lyricSnippet.id == id);
  }

  List<LyricSnippetTrack> assignTrackNumber(
      List<LyricSnippet> lyricSnippetList) {
    if (lyricSnippetList.isEmpty) return [];

    List<LyricSnippetTrack> lyricSnippetTrack = [];
    lyricSnippetList
        .sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));

    int maxOverlap = 0;
    int currentOverlap = 0;
    int currentEndTime = lyricSnippetList[0].endTimestamp;
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

      lyricSnippetTrack
          .add(LyricSnippetTrack(lyricSnippetList[i], currentOverlap - 1));
      if (currentOverlap > maxLanes) {
        maxLanes = currentOverlap;
      }
    }

    return lyricSnippetTrack;
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
    List<LyricSnippetTrack> currentSnippets =
        getSnippetsAtCurrentSeekPosition();

    LyricSnippet emptySnippet = LyricSnippet(
        vocalist: Vocalist("", 0),
        index: 0,
        sentence: "",
        startTimestamp: currentSeekPosition,
        timingPoints: [TimingPoint(1, 1)]);
    List<Widget> content =
        List<Widget>.generate(maxLanes, (index) => Container());

    String debug = "";
    for (int i = 0; i < maxLanes; i++) {
      LyricSnippet targetSnippet = currentSnippets
          .firstWhere(
            (LyricSnippetTrack snippet) => snippet.trackNumber == i,
            orElse: () => LyricSnippetTrack(emptySnippet, i),
          )
          .lyricSnippet;
      content[i] = outlinedText(targetSnippet, fontFamily);
      debug = debug + "$i: ${targetSnippet.sentence} /// ";
    }
    debugPrint("${debug}");

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

  List<LyricSnippetTrack> getSnippetsAtCurrentSeekPosition() {
    return lyricSnippetTrack.where((snippet) {
      return snippet.lyricSnippet.startTimestamp < currentSeekPosition &&
          currentSeekPosition < snippet.lyricSnippet.endTimestamp;
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

class LyricSnippetTrack {
  LyricSnippet lyricSnippet;
  int trackNumber;
  LyricSnippetTrack(this.lyricSnippet, this.trackNumber);
}
