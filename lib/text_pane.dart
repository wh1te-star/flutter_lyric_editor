import 'package:flutter/material.dart';
import 'media_control_interface.dart';

class TextPane extends StatefulWidget {
  @override
  _TextPaneState createState() => _TextPaneState();
}

class _TextPaneState extends State<TextPane> implements MediaControlInterface {
  bool isPlaying = true;
  String time = "";
  String defaultText = "Text Pane";

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
  void onChangeColor() {
    debugPrint("Play/Pause button tapped in the text_pane.dart");
  }

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
        color: Colors.green,
        child: Center(child: Text(defaultText)),
      ),
    );
  }
}
