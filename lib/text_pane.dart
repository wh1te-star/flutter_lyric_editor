import 'package:flutter/material.dart';
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
  _TextPaneState(this.masterSubject, this.focusNode);

  Terminal terminal = Terminal();

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {});

    terminal.onOutput = (output) {
      debugPrint('output: $output');
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        masterSubject.add(RequestPlayPause());
        focusNode.requestFocus();
        debugPrint("The text pane is focused");
      },
      child: TerminalView(terminal),
    );
  }
}
