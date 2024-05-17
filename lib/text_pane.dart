import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class TextPane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;

  TextPane({required this.masterSubject}) : super(key: Key('TextPane'));

  @override
  _TextPaneState createState() => _TextPaneState(masterSubject);
}

class _TextPaneState extends State<TextPane> {
  final PublishSubject<dynamic> masterSubject;
  _TextPaneState(this.masterSubject);

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {
      if (signal['type'] == 'play') {
        updateString();
        print('TextPane: Handling play signal');
      }
    });
  }

  bool isPlaying = true;
  String time = "";
  String defaultText = "Text Pane";

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
        print('TextPane: Tapped');
        masterSubject.add({
          'sender': 'TextPane',
          'type': 'play',
          'data': 'Tapped from TextPane'
        });
      },
      child: Container(
        color: Colors.green,
        child: Center(child: Text(defaultText)),
      ),
    );
  }
}
