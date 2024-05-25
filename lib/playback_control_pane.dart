import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'square_icon_button.dart';

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
        const double height = 30.0;

        Widget volumeControlWidget = const Row(children: [
          Text('Volume: 1.000'),
          SquareIconButton(
            icon: Icons.volume_down,
            size: height,
          ),
          SquareIconButton(
            icon: Icons.volume_up,
            size: height,
          ),
        ]);

        Widget playbackSpeedWidget = const Row(children: [
          Text('Playback Speed: ×1.00'),
          SquareIconButton(
            icon: Icons.arrow_left,
            size: height,
          ),
          SquareIconButton(
            icon: Icons.arrow_right,
            size: height,
          ),
        ]);

        Widget playbackControlWidget = const Row(children: [
          SquareIconButton(
            icon: Icons.arrow_left,
            size: height,
          ),
          SquareIconButton(
            icon: Icons.arrow_right,
            size: height,
          ),
          SquareIconButton(
            icon: Icons.arrow_right,
            size: height,
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

        return Container(
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
        );
      },
    );
  }
}
