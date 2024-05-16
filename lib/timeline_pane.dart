import 'package:flutter/material.dart';
import 'media_control_interface.dart';

class TimelinePane extends StatelessWidget implements MediaControlInterface {
  bool isPlaying = false;
  String time = "";

  @override
  void onPlayPause() {}

  @override
  void onChangeColor() {
    debugPrint("Play/Pause button tapped in the timeline_pane.dart");
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChangeColor();
      },
      child: Container(
        color: Colors.red,
        child: Center(child: Text('Timeline Pane')),
      ),
    );
  }
}
