import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {
      if (signal['type'] == 'play') {
        updateString();
        print('VideoPane: Handling play signal');
      }
    });
  }

  bool isPlaying = true;
  String time = "";
  String defaultText = "Video Pane";

  void updateString() {
    String newText;
    if (isPlaying) {
      isPlaying = false;
      newText = "Stopping, $time";
    } else {
      isPlaying = true;
      newText = "Playing, $time";
    }
    setState(() {
      defaultText = newText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('VideoPane: Tapped');
        masterSubject.add({
          'sender': 'VideoPane',
          'type': 'play',
          'data': 'Tapped from VideoPane'
        });
      },
      child: Container(
        color: Colors.blue,
        child: Center(child: Text(defaultText)),
      ),
    );
  }
}
