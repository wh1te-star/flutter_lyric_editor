import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class TimelinePane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  TimelinePane({required this.masterSubject, required this.focusNode})
      : super(key: Key('TimelinePane'));

  @override
  _TimelinePaneState createState() =>
      _TimelinePaneState(masterSubject, focusNode);
}

class _TimelinePaneState extends State<TimelinePane> {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;
  _TimelinePaneState(this.masterSubject, this.focusNode);
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

  String defaultText = "Timeline Pane";

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

  Widget TwoDimensionalScrollWidget() {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Container(
            width: 12000,
            height: 12000,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.yellow,
                  Colors.red,
                  Colors.indigo,
                  Colors.teal,
                ],
              ),
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          children: <Widget>[
            Container(
              height: 30,
              child: Row(
                children: <Widget>[
                  Container(width: 100, color: Colors.purple),
                  Expanded(child: Container(color: Colors.orange)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Container(width: 100, color: Colors.orangeAccent),
                  Expanded(child: TwoDimensionalScrollWidget()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
