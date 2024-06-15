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
    return SizedBox(
      height: 60,
      child: CustomPaint(
        painter: PartialTextPainter(
          text: snippet.sentence,
          start: 0,
          end: snippet.sentence.length,
          percent: time / 10000,
          fontFamily: fontFamily,
        ),
        size: Size(double.infinity, 60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> fontFamilies = [
      'Roboto',
      'Arial',
      'Courier',
      'Times New Roman',
      'Verdana',
      'Georgia',
      'Trebuchet MS',
      '.SF UI Display',
      '.SF UI Text',
      'Helvetica',
    ];
    if (lyricSnippets.length == 0) return Container(color: Colors.white);
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: fontFamilies.map((fontFamily) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: outlinedText(lyricSnippets[0], fontFamily),
              );
            }).toList(),
          ),
        ),
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

  PartialTextPainter({
    required this.text,
    required this.start,
    required this.end,
    required this.percent,
    required this.fontFamily,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textStyleAfterInner = TextStyle(
      fontFamily: fontFamily,
      fontSize: 40,
      color: Colors.green,
    );
    final textStyleAfterMiddle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 40,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    final textStyleAfterOuter = TextStyle(
      fontFamily: fontFamily,
      fontSize: 40,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.black,
      shadows: [
        Shadow(
          color: Colors.green,
          blurRadius: 30.0,
          offset: Offset(0.0, 0.0),
        ),
      ],
    );

    final textStyleBeforeInner = TextStyle(
      fontFamily: fontFamily,
      fontSize: 40,
      color: Colors.white,
    );
    final textStyleBeforeMiddle = TextStyle(
      fontFamily: fontFamily,
      fontSize: 40,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.green,
    );
    final textStyleBeforeOuter = TextStyle(
      fontFamily: fontFamily,
      fontSize: 40,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = Colors.black,
      shadows: [
        Shadow(
          color: Colors.green,
          blurRadius: 30.0,
          offset: Offset(0.0, 0.0),
        ),
      ],
    );

    final textSpanAfterInner = TextSpan(text: text, style: textStyleAfterInner);
    final textSpanAfterMiddle =
        TextSpan(text: text, style: textStyleAfterMiddle);
    final textSpanAfterOuter = TextSpan(text: text, style: textStyleAfterOuter);

    final textPainterAfterInner =
        TextPainter(text: textSpanAfterInner, textDirection: TextDirection.ltr);
    final textPainterAfterMiddle = TextPainter(
        text: textSpanAfterMiddle, textDirection: TextDirection.ltr);
    final textPainterAfterOuter =
        TextPainter(text: textSpanAfterOuter, textDirection: TextDirection.ltr);

    textPainterAfterInner.layout(maxWidth: size.width);
    textPainterAfterMiddle.layout(maxWidth: size.width);
    textPainterAfterOuter.layout(maxWidth: size.width);

    final startOffset = textPainterAfterInner
        .getOffsetForCaret(TextPosition(offset: start), Rect.zero)
        .dx;
    final endOffset = textPainterAfterInner
        .getOffsetForCaret(TextPosition(offset: end), Rect.zero)
        .dx;

    final sliceWidth = startOffset + (endOffset - startOffset) * percent;

    //canvas.save();

    final textSpanBeforeInner =
        TextSpan(text: text, style: textStyleBeforeInner);
    final textPainterBeforeInner = TextPainter(
        text: textSpanBeforeInner, textDirection: TextDirection.ltr);
    textPainterBeforeInner.layout(maxWidth: size.width);

    final textSpanBeforeMiddle =
        TextSpan(text: text, style: textStyleBeforeMiddle);
    final textPainterBeforeMiddle = TextPainter(
        text: textSpanBeforeMiddle, textDirection: TextDirection.ltr);
    textPainterBeforeMiddle.layout(maxWidth: size.width);

    final textSpanBeforeOuter =
        TextSpan(text: text, style: textStyleBeforeOuter);
    final textPainterBeforeOuter = TextPainter(
        text: textSpanBeforeOuter, textDirection: TextDirection.ltr);
    textPainterBeforeOuter.layout(maxWidth: size.width);

    textPainterBeforeOuter.paint(canvas, Offset.zero);
    textPainterBeforeMiddle.paint(canvas, Offset.zero);
    textPainterBeforeInner.paint(canvas, Offset.zero);

    canvas.clipRect(Rect.fromLTWH(0, 0, sliceWidth, size.height));

    textPainterAfterOuter.paint(canvas, Offset.zero);
    textPainterAfterMiddle.paint(canvas, Offset.zero);
    textPainterAfterInner.paint(canvas, Offset.zero);

    //canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
