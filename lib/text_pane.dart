import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';
import 'package:xterm/xterm.dart';

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
  bool _isFocused = false;

  _TextPaneState(this.masterSubject, this.focusNode);

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {});
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
      controller: _textEditingController,
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
    String text = _textEditingController.text;
    List<String> lines = text.split('\n');
    double screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        children: lines.map((line) {
          return Container(
            margin: EdgeInsets.all(8.0),
            child:
                Text(line, style: TextStyle(fontSize: 16, color: Colors.black)),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    focusNode.dispose();
    super.dispose();
  }

  final _textEditingController = TextEditingController(text: '''
    long text. long text. long text. long text. long text. long text. long text. long text. long text. long text. long text. long text. 
    long text. long text. long text. long text. long text. long text. long text. long text. long text. long text. long text.
    long text. long text. long text. long text. long text. long text. long text. long text. long text. long text.
    long text. long text. long text. long text. long text. long text. long text. long text. long text.
    long text. long text. long text. long text. long text. long text. long text. long text.
    long text. long text. long text. long text. long text. long text. long text.
    long text. long text. long text. long text. long text. long text.
    long text. long text. long text. long text. long text.
    long text. long text. long text. long text.
    long text. long text. long text.
    long text. long text.
    long text.''');
}
