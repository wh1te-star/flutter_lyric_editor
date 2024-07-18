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

  DisplayMode displayMode = DisplayMode.appearDissappear;
  ScrollController scrollController = ScrollController();

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
        scrollController
            .jumpTo(currentSeekPosition / 60 % (lyricSnippetTrack.length * 60));
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
    lyricSnippetList
        .sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));

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

      lyricSnippetTrack
          .add(LyricSnippetTrack(lyricSnippetList[i], currentOverlap - 1));
      if (currentOverlap > maxLanes) {
        maxLanes = currentOverlap;
      }
    }

    return lyricSnippetTrack;
  }

  PartialTextPainter getBeforeSnippetPainter(
      LyricSnippet snippet, fontFamily, Color fontColor) {
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

  PartialTextPainter getAfterSnippetPainter(
      LyricSnippet snippet, fontFamily, Color fontColor) {
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

  CustomPaint getColorHilightedText(LyricSnippet snippet, int seekPosition,
      String fontFamily, Color fontColor) {
    if (currentSeekPosition < snippet.startTimestamp) {
      return CustomPaint(
        painter: getBeforeSnippetPainter(snippet, fontFamily, fontColor),
        size: Size(double.infinity, double.infinity),
      );
    } else if (snippet.endTimestamp < currentSeekPosition) {
      return CustomPaint(
        painter: getAfterSnippetPainter(snippet, fontFamily, fontColor),
        size: Size(double.infinity, double.infinity),
      );
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
      return CustomPaint(
        painter: PartialTextPainter(
          text: snippet.sentence,
          start: startChar,
          end: startChar + snippet.timingPoints[wordIndex].wordLength,
          percent: percent,
          fontFamily: fontFamily,
          fontSize: 40,
          fontBaseColor: fontColor,
          firstOutlineWidth: 2,
          secondOutlineWidth: 4,
        ),
        size: Size(double.infinity, double.infinity),
      );
    }
  }

  Widget outlinedText(LyricSnippet snippet, String fontFamily) {
    Color fontColor = Color(0);
    if (vocalistColorList.containsKey(snippet.vocalist.name)) {
      fontColor = Color(vocalistColorList[snippet.vocalist.name]!);
    }
    return Expanded(
      child: getColorHilightedText(
          snippet, currentSeekPosition, fontFamily, fontColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fontFamily = "Times New Roman";
    List<LyricSnippetTrack> currentSnippets =
        getSnippetsAtCurrentSeekPosition();

    if (displayMode == DisplayMode.appearDissappear) {
      LyricSnippet emptySnippet = LyricSnippet(
          vocalist: Vocalist("", 0),
          index: 0,
          sentence: "",
          startTimestamp: currentSeekPosition,
          timingPoints: [TimingPoint(1, 1)]);
      List<Widget> content =
          List<Widget>.generate(maxLanes, (index) => Container());

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
      lyricSnippetTrack.forEach((LyricSnippetTrack snippet) {
        columnSnippets.add(CustomPaint(
          size: Size(double.infinity, height),
          painter: PartialTextPainter(
              text: snippet.lyricSnippet.sentence,
              start: 0,
              end: 5,
              percent: 0.5,
              fontFamily: fontFamily,
              fontSize: 40,
              fontBaseColor: Colors.purple,
              firstOutlineWidth: 2,
              secondOutlineWidth: 4),
        ));
      });
      return Focus(
        focusNode: focusNode,
        child: GestureDetector(
          onTap: () {
            widget.masterSubject.add(RequestPlayPause());
            focusNode.requestFocus();
            debugPrint("The video pane is focused");
          },
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: columnSnippets,
            ),
          ),
        ),
      );
    }
  }

  List<LyricSnippetTrack> getSnippetsAtCurrentSeekPosition() {
    return lyricSnippetTrack.where((snippet) {
      return snippet.lyricSnippet.startTimestamp - startBulge <
              currentSeekPosition &&
          currentSeekPosition < snippet.lyricSnippet.endTimestamp + endBulge;
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

enum DisplayMode {
  appearDissappear,
  verticalScroll,
}
