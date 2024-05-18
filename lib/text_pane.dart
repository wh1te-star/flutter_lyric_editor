import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class TextPane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;

  TextPane({required this.masterSubject}) : super(key: Key('TextPane'));

  @override
  _TextPaneState createState() => _TextPaneState(masterSubject);
}

class _TextPaneState extends State<TextPane> {
  final PublishSubject<dynamic> masterSubject;
  _TextPaneState(this.masterSubject);
  bool isPlaying = true;
  int time = 0;

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

  String defaultText = "Text Pane";

  String formatMillisec(int inMillisecFormat) {
    int hours = inMillisecFormat ~/ Duration.millisecondsPerHour;
    int minutes = inMillisecFormat ~/ Duration.millisecondsPerMinute;
    int seconds = inMillisecFormat ~/ Duration.millisecondsPerSecond;
    int millisec = inMillisecFormat % Duration.millisecondsPerSecond;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        masterSubject.add(RequestPlayPause());
      },
      child: Container(
        color: Colors.blue,
        child: Center(child: Text(defaultText)),
      ),
    );
  }
}
