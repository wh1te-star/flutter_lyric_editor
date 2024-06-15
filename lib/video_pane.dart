import 'package:flutter/material.dart';
import 'package:lyric_editor/lyric_snippet.dart';
import 'package:lyric_editor/signal_structure.dart';
import 'package:rxdart/rxdart.dart';
import 'playback_control_pane.dart';

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
  int time = 0;
  List<LyricSnippet> lyricSnippets = [];

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {
      if (signal is NotifyIsPlaying) {
        isPlaying = signal.isPlaying;
      }
      if (signal is NotifySeekPosition) {
        time = signal.seekPosition;
      }
      if (signal is NotifyLyricParsed) {
        lyricSnippets = signal.lyricSnippetList;
      }
      updateString(isPlaying, time);
    });
  }

  String defaultText = "Video Pane";

  String formatMillisec(int inMillisecFormat) {
    int remainingMillisec = inMillisecFormat;

    int hours = remainingMillisec ~/ Duration.millisecondsPerHour;
    remainingMillisec = remainingMillisec % Duration.millisecondsPerHour;

    int minutes = remainingMillisec ~/ Duration.millisecondsPerMinute;
    remainingMillisec = remainingMillisec % Duration.millisecondsPerMinute;

    int seconds = remainingMillisec ~/ Duration.millisecondsPerSecond;
    remainingMillisec = remainingMillisec % Duration.millisecondsPerSecond;

    int millisec = remainingMillisec % Duration.millisecondsPerSecond;

    String formattedHours = hours.toString().padLeft(2, '0');
    String formattedMinutes = minutes.toString().padLeft(2, '0');
    String formattedSeconds = seconds.toString().padLeft(2, '0');
    String formattedMillisec = millisec.toString().padLeft(3, '0');

    return "$formattedHours:$formattedMinutes:$formattedSeconds.$formattedMillisec";
  }

  void updateString(bool isPlaying, int timeMillisec) {
    String newText;
    if (isPlaying) {
      newText = "Playing, ${formatMillisec(timeMillisec)}";
    } else {
      newText = "Stopping, ${formatMillisec(timeMillisec)}";
    }
    setState(() {
      defaultText = newText;
    });
  }

  Widget outlinedText(LyricSnippet snippet, String fontFamily) {
    return CustomPaint(
      painter: PartialTextPainter(
        text: snippet.sentence,
        start: 0,
        end: snippet.sentence.length,
        percent: time / 10000,
        fontFamily: fontFamily,
        fontSize: 40,
        firstOutlineWidth: 2,
        secondOutlineWidth: 4,
      ),
      size: const Size(double.infinity, 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fontFamily = "Times New Roman";
    if (lyricSnippets.isEmpty) return Container(color: Colors.white);
    return Column(children: [
      Expanded(
        child: outlinedText(lyricSnippets[0], fontFamily),
      ),
      PlaybackControlPane(masterSubject: masterSubject),
    ]);
  }
}

class PartialTextPainter extends CustomPainter {
  final String text;
  final int start;
  final int end;
  final double percent;
  final String fontFamily;
  final double fontSize;
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
    required this.firstOutlineWidth,
    required this.secondOutlineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    setupTextStyle();
    setupTextSpan();
    setupTextPainter(size);
    paintText(canvas, size);
  }

  void setupTextStyle() {
    Shadow shadow = Shadow(
      color: Colors.green,
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
        ..color = Colors.green,
      shadows: [shadow],
    );

    textStyleAfterInner = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      color: Colors.green,
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
    final actualX = (size.width - textPainterBeforeInner.width) / 2;
    final actualY = (size.height - textPainterBeforeInner.height) / 2;
    final centerOffset = Offset(actualX, actualY);

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
