import 'package:flutter/material.dart';
import 'package:lyric_editor/signal_structure.dart';
import 'package:rxdart/rxdart.dart';

class VideoPane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;

  VideoPane({required this.masterSubject}) : super(key: Key('VideoPane'));

  @override
  _VideoPaneState createState() => _VideoPaneState(masterSubject);
}

class _VideoPaneState extends State<VideoPane> {
  final PublishSubject<dynamic> masterSubject;
  _VideoPaneState(this.masterSubject);
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

  String defaultText = "Video Pane";

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
    return Column(
      children: <Widget>[
        Flexible(
          child: GestureDetector(
            onTap: () {
              masterSubject.add(RequestPlayPause());
            },
            child: Container(
              color: Colors.green,
              child: Center(child: Text(defaultText)),
            ),
          ),
        ),
        Container(
          height: 30,
          color: Colors.yellow,
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                playbackSpeedWidget,
                volumeControlWidget,
                playbackControlWidget,
                seekPositionWidget,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget playbackSpeedWidget = Row(children: [
    const Text('Volume: 1.000'),
    IconButton(
      icon: const Icon(Icons.volume_down),
      onPressed: () {},
    ),
    IconButton(
      icon: const Icon(Icons.volume_up),
      onPressed: () {},
    ),
  ]);
  Widget volumeControlWidget = Row(children: [
    const Text('Playback Speed: ×1.0'),
    IconButton(
      icon: const Icon(Icons.arrow_left),
      onPressed: () {},
    ),
    IconButton(
      icon: const Icon(Icons.arrow_right),
      onPressed: () {},
    ),
  ]);
  Widget playbackControlWidget = Row(children: [
    IconButton(
      icon: const Icon(Icons.arrow_left),
      onPressed: () {},
    ),
    IconButton(
      icon: const Icon(Icons.arrow_right),
      onPressed: () {},
    ),
    IconButton(
      icon: const Icon(Icons.arrow_right),
      onPressed: () {},
    ),
  ]);
  Widget seekPositionWidget = Row(children: [
    const Text('Seek Position: 01:23:45.678'),
    IconButton(
      icon: const Icon(Icons.arrow_left),
      onPressed: () {},
    ),
    Slider(
      value: 50,
      min: 0,
      max: 100,
      divisions: 5,
      label: "50",
      onChanged: (double newValue) {},
    ),
  ]);
}
