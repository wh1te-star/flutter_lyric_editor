import 'package:flutter/material.dart';
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
    //debugPrint("startChar: ${startChar}, endCar:${startChar + snippet.timingPoints[currentCharIndex].wordLength}, percent: ${percent}");
    Color fontColor = Color(0);
    if (vocalistColorList.containsKey(snippet.vocalist.name)) {
      fontColor = Color(vocalistColorList[snippet.vocalist.name]!);
    }
    return CustomPaint(
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
      size: const Size(double.infinity, 60),
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
        timingPoints: [TimingPoint(0, 0)]);
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

class PartialTextPainter extends CustomPainter {
  final String text;
  final int start;
  final int end;
  final double percent;
  final String fontFamily;
  final double fontSize;
  final Color fontBaseColor;
  final double firstOutlineWidth;
  final double secondOutlineWidth;
  late final TextStyle textStyleBeforeInner;
  late final TextStyle textStyleBeforeMiddle;
  late final TextStyle textStyleBeforeOuter;
  late final TextSpan textSpanBeforeInner;
  late final TextSpan textSpanBeforeMiddle;
  late final TextSpan textSpanBeforeOuter;
  late final TextPainter textPainterBeforeInner;
  late final TextPainter textPainterBeforeMiddle;
  late final TextPainter textPainterBeforeOuter;
  late final TextStyle textStyleAfterInner;
  late final TextStyle textStyleAfterMiddle;
  late final TextStyle textStyleAfterOuter;
  late final TextSpan textSpanAfterInner;
  late final TextSpan textSpanAfterMiddle;
  late final TextSpan textSpanAfterOuter;
  late final TextPainter textPainterAfterInner;
  late final TextPainter textPainterAfterMiddle;
  late final TextPainter textPainterAfterOuter;

  PartialTextPainter({
    required this.text,
    required this.start,
    required this.end,
    required this.percent,
    required this.fontFamily,
    required this.fontSize,
    required this.fontBaseColor,
    required this.firstOutlineWidth,
    required this.secondOutlineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Color(0xFFEEEEEE);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    setupTextStyle();
    setupTextSpan();
    setupTextPainter(size);
    paintText(canvas, size);
  }

  void setupTextStyle() {
    Shadow shadow = Shadow(
      color: fontBaseColor,
      blurRadius: 30.0,
      offset: Offset(0.0, 0.0),
    );
    textStyleBeforeInner = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: Colors.white,
    );
    textStyleBeforeMiddle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = firstOutlineWidth
        ..color = Colors.black,
    );
    textStyleBeforeOuter = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = firstOutlineWidth + secondOutlineWidth
        ..color = fontBaseColor,
      shadows: [shadow],
    );

    textStyleAfterInner = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: fontBaseColor,
    );
    textStyleAfterMiddle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = firstOutlineWidth
        ..color = Colors.white,
    );
    textStyleAfterOuter = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = firstOutlineWidth + secondOutlineWidth
        ..color = Colors.black,
      shadows: [shadow],
    );
  }

  void setupTextSpan() {
    textSpanBeforeInner = TextSpan(text: text, style: textStyleBeforeInner);
    textSpanBeforeMiddle = TextSpan(text: text, style: textStyleBeforeMiddle);
    textSpanBeforeOuter = TextSpan(text: text, style: textStyleBeforeOuter);
    textSpanAfterInner = TextSpan(text: text, style: textStyleAfterInner);
    textSpanAfterMiddle = TextSpan(text: text, style: textStyleAfterMiddle);
    textSpanAfterOuter = TextSpan(text: text, style: textStyleAfterOuter);
  }

  void setupTextPainter(Size size) {
    textPainterAfterInner = TextPainter(
        text: textSpanAfterInner,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    textPainterAfterMiddle = TextPainter(
        text: textSpanAfterMiddle,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    textPainterAfterOuter = TextPainter(
        text: textSpanAfterOuter,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);

    textPainterAfterInner.layout(maxWidth: size.width);
    textPainterAfterMiddle.layout(maxWidth: size.width);
    textPainterAfterOuter.layout(maxWidth: size.width);

    textPainterBeforeInner = TextPainter(
        text: textSpanBeforeInner,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);

    textPainterBeforeMiddle = TextPainter(
        text: textSpanBeforeMiddle,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);

    textPainterBeforeOuter = TextPainter(
        text: textSpanBeforeOuter,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);

    textPainterBeforeInner.layout(maxWidth: size.width);
    textPainterBeforeMiddle.layout(maxWidth: size.width);
    textPainterBeforeOuter.layout(maxWidth: size.width);
  }

  void paintText(Canvas canvas, Size size) {
    final textWidth = textPainterBeforeInner.width;
    final textHeight = textPainterBeforeInner.height;

    final actualX = (size.width - textWidth) / 2;
    final actualY = (size.height - textHeight) / 2;
    final centerOffset = Offset(actualX, actualY);

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    textPainterBeforeOuter.paint(canvas, centerOffset);
    textPainterBeforeMiddle.paint(canvas, centerOffset);
    textPainterBeforeInner.paint(canvas, centerOffset);

    final startOffset = textPainterAfterInner
        .getOffsetForCaret(TextPosition(offset: start), Rect.zero)
        .dx;
    final endOffset = textPainterAfterInner
        .getOffsetForCaret(TextPosition(offset: end), Rect.zero)
        .dx;
    final sliceWidth =
        actualX + startOffset + (endOffset - startOffset) * percent;

    canvas.clipRect(Rect.fromLTWH(0, 0, sliceWidth, size.height));

    textPainterAfterOuter.paint(canvas, centerOffset);
    textPainterAfterMiddle.paint(canvas, centerOffset);
    textPainterAfterInner.paint(canvas, centerOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
