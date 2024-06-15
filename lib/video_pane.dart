import 'package:flutter/material.dart';
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
  String text = "outlined text";

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

  Widget outlinedText(String text, String fontFamily) {
    return Center(
      child: Stack(
        children: [
          Text(
            text,
            style: TextStyle(
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
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 40,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.white,
            ),
          ),
          Text(
            text,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 40,
              color: Colors.green,
            ),
          ),
        ],
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
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: fontFamilies.map((fontFamily) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: outlinedText("Outlined Text", fontFamily),
              );
            }).toList(),
          ),
        ),
      ),
      PlaybackControlPane(masterSubject: masterSubject),
    ]);
  }
}
