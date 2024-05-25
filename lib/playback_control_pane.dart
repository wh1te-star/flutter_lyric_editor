import 'package:flutter/material.dart';
import 'package:lyric_editor/signal_structure.dart';
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

  GlobalKey volumeControlKey = GlobalKey();
  GlobalKey speedControlKey = GlobalKey();
  GlobalKey playbackControlKey = GlobalKey();
  GlobalKey seekbarKey = GlobalKey();

  double getTotalWidth() {
    final RenderBox? volumeControlBox =
        volumeControlKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? speedControlBox =
        speedControlKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? playbackControlBox =
        playbackControlKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? seekbarBox =
        seekbarKey.currentContext?.findRenderObject() as RenderBox?;

    if (volumeControlBox != null &&
        speedControlBox != null &&
        playbackControlBox != null &&
        seekbarBox != null) {
      double volumeControlWidth = volumeControlBox.size.width;
      double speedControlWidth = speedControlBox.size.width;
      double playbackControlWidth = playbackControlBox.size.width;
      double seekbarWidth = seekbarBox.size.width;

      double totalWidth = volumeControlWidth +
          speedControlWidth +
          playbackControlWidth +
          seekbarWidth;

      //debugPrint('Volume Control Width: $volumeControlWidth');
      //debugPrint('Speed Control Width: $speedControlWidth');
      //debugPrint('Playback Control Width: $playbackControlWidth');
      //debugPrint('Seekbar Width: $seekbarWidth');
      //debugPrint('Total Width: $totalWidth');
      return totalWidth;
    } else {
      debugPrint('One or more widgets have not been rendered yet.');
      return -1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      masterSubject.add(NotifyVideoPaneWidthLimit(getTotalWidth()));
    });
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth;
        const double height = 30.0;

        Widget volumeControlWidget =
            Row(key: volumeControlKey, children: const [
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

        Widget playbackSpeedWidget = Row(key: speedControlKey, children: const [
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

        Widget playbackControlWidget =
            Row(key: playbackControlKey, children: const [
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

        Widget seekPositionWidget = Row(key: seekbarKey, children: [
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
