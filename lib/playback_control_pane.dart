import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class PlaybackControlPane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;

  PlaybackControlPane({required this.masterSubject})
      : super(key: Key('PlaybackControlPane'));

  @override
  _PlaybackControlPaneState createState() =>
      _PlaybackControlPaneState(masterSubject);
}

class _PlaybackControlPaneState extends State<PlaybackControlPane> {
  final PublishSubject<dynamic> masterSubject;
  _PlaybackControlPaneState(this.masterSubject);

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth;
        double height = 30;
        double aspectRatio = 30.0;

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            height: height,
            color: Colors.yellow,
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
        );
      },
    );
  }

  Widget volumeControlWidget = Row(children: [
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

  Widget playbackSpeedWidget = Row(children: [
    const Text('Playback Speed: ×1.00'),
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
