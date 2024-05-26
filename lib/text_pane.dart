import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isFocused = false;

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
    setState(() {
      _isFocused = focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.masterSubject.add(RequestPlayPause());
        focusNode.requestFocus();
        debugPrint("The text pane is focused");
        setState(() {
          _isFocused = true;
        });
      },
      child: _isFocused ? _editableView() : _displayView(),
    );
  }

  Widget _editableView() {
    return TextField(
      maxLines: null,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Edit your text...',
      ),
      focusNode: focusNode,
    );
  }

  Widget _displayView() {
    double screenWidth = MediaQuery.of(context).size.width;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: sentenceList.length,
      itemBuilder: (context, index) {
        Color backgroundColor = Colors.transparent;
        if (index == highlightPosition) {
          backgroundColor = Colors.yellowAccent;
        }
        itemCount = sentenceList.length;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            color: backgroundColor,
            child: Text(sentenceList[index],
                style: TextStyle(fontSize: 16, color: Colors.black)),
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
