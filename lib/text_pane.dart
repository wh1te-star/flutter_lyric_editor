import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class TextPane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  TextPane({required this.masterSubject, required this.focusNode})
      : super(key: Key('TextPane'));

  @override
  _TextPaneState createState() => _TextPaneState(masterSubject, focusNode);
}

class _TextPaneState extends State<TextPane> {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  List<String> sentenceList = [];
  var highlightPosition = 0;
  var itemCount = 100;

  _TextPaneState(this.masterSubject, this.focusNode);

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {
      if (signal is NotifyIsPlaying) {
        setState(() {
          highlightPosition = (highlightPosition + 1) % itemCount;
        });
      }
      if (signal is NotifyLyricParsed) {
        setState(() {
          sentenceList = signal.sentenceList;
        });
      }
    });
    focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    //setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.masterSubject.add(RequestPlayPause());
        focusNode.requestFocus();
        debugPrint("The text pane is focused");
        setState(() {});
      },
      child: _displayView(),
    );
  }

  Widget _displayView() {
    double screenWidth = MediaQuery.of(context).size.width;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: sentenceList.length,
      itemBuilder: (context, index) {
        Color backgroundColor = Colors.transparent;
        double fontSize = 16;
        EdgeInsets padding = const EdgeInsets.symmetric(vertical: 1.0);
        if (index == highlightPosition) {
          backgroundColor = Colors.yellowAccent;
          fontSize = 20;
          padding = const EdgeInsets.symmetric(vertical: 10.0);
        }

        return Padding(
          padding: padding,
          child: Container(
            color: backgroundColor,
            child: Text(
              sentenceList[index],
              style: TextStyle(fontSize: fontSize, color: Colors.black),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    focusNode.dispose();
    super.dispose();
  }
}
