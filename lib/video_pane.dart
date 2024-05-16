import 'package:flutter/material.dart';
import 'media_control_interface.dart';

class VideoPane extends StatefulWidget {
  @override
  _VideoPaneState createState() => _VideoPaneState();
}

class _VideoPaneState extends State<VideoPane>
    implements MediaControlInterface {
  bool isPlaying = true;
  String time = "";
  String defaultText = "Video Pane";

  @override
  void onPlayPause() {
    if (isPlaying == false) {
      isPlaying = true;
    } else {
      isPlaying = false;
    }
    updateString();
    debugPrint("Play/Pause button tapped in the video_pane.dart");
  }

  @override
  void onChangeColor() {}

  void updateString() {
    String newText;
    if (isPlaying) {
      newText = "Playing, $time";
    } else {
      newText = "Stopping, $time";
    }
    setState(() {
      defaultText = newText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPlayPause();
      },
      child: Container(
        color: Colors.blue,
        child: Center(child: Text(defaultText)),
      ),
    );
  }
}
