import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class TimelinePane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;

  TimelinePane({required this.masterSubject}) : super(key: Key('TimelinePane'));

  @override
  _TimelinePaneState createState() => _TimelinePaneState(masterSubject);
}

class _TimelinePaneState extends State<TimelinePane> {
  final PublishSubject<dynamic> masterSubject;
  _TimelinePaneState(this.masterSubject);

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {
      if (signal['type'] == 'play') {
        updateString();
        print('TimelinePane: Handling play signal');
      }
    });
  }

  bool isPlaying = true;
  String time = "";
  String defaultText = "Timeline Pane";

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
        print('TimelinePane: Tapped');
        masterSubject.add({
          'sender': 'TimelinePane',
          'type': 'play',
          'data': 'Tapped from TimelinePane'
        });
      },
      child: Container(
        color: Colors.red,
        child: Center(child: Text(defaultText)),
      ),
    );
  }
}
