import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';

class TextPane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;

  TextPane({required this.masterSubject}) : super(key: Key('TextPane'));

  @override
  _TextPaneState createState() => _TextPaneState(masterSubject);
}

class _TextPaneState extends State<TextPane> {
  final PublishSubject<dynamic> masterSubject;
  late final FocusNode focusNode;

  //String entireLyricString = "";
  var cursorPositionChar = 0;
  var cursorPositionLine = 0;
  var timingPoints = [1, 4, 5, 16, 24, 36, 46, 50, 67, 90];
  var linefeedPoints = [19, 38, 57, 100];
  var sectionPoints = [82];

  List<String> listItems = [];
  Map<int, String> timingPointMap = {};
  Map<int, String> linefeedPointMap = {};
  Map<int, String> sectionPointMap = {};

  _TextPaneState(this.masterSubject);

  @override
  void initState() {
    super.initState();

    timingPointMap =
        timingPoints.asMap().map((key, value) => MapEntry(value, "|"));
    linefeedPointMap =
        linefeedPoints.asMap().map((key, value) => MapEntry(value, "\n"));
    sectionPointMap =
        sectionPoints.asMap().map((key, value) => MapEntry(value, "\n\n"));

    masterSubject.stream.listen((signal) {
      if (signal is NotifyLyricParsed) {
        var entireLyricString = signal.entireLyricString;
        var combinedMap = <int, String>{};
        combinedMap.addAll(timingPointMap);
        combinedMap.addAll(linefeedPointMap);
        combinedMap.addAll(sectionPointMap);
        entireLyricString = InsertChars(entireLyricString, combinedMap);
        listItems = entireLyricString.split('\n');
        setState(() {});
      }
    });
    focusNode = FocusNode();
    focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (focusNode.hasFocus)
      debugPrint("focus enabled");
    else
      debugPrint("focus released");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyK) {
          if (cursorPositionLine > 0) {
            cursorPositionLine--;
            setState(() {});
            debugPrint("K key: ${cursorPositionLine}");
          }
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyJ) {
          if (cursorPositionLine < listItems.length - 1) {
            cursorPositionLine++;
            setState(() {});
            debugPrint("J key: ${cursorPositionLine}");
          }
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyH) {
          if (cursorPositionChar > 0) {
            cursorPositionChar--;
            setState(() {});
            debugPrint("H key: ${cursorPositionChar}");
          }
          return KeyEventResult.handled;
        }
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyL) {
          if (cursorPositionChar <= listItems[cursorPositionLine].length) {
            cursorPositionChar++;
            setState(() {});
            debugPrint("L key: ${cursorPositionChar}");
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: () {
          widget.masterSubject.add(RequestPlayPause());
          focusNode.requestFocus();
          debugPrint("The text pane is focused");
          setState(() {});
        },
        child: _displayView(),
      ),
    );
  }

  Widget _displayView() {
    //cursor code.

    return ListView.builder(
      shrinkWrap: true,
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        Color backgroundColor = Colors.transparent;
        double fontSize = 16;
        EdgeInsets padding = const EdgeInsets.symmetric(vertical: 1.0);

        if (index == cursorPositionLine) {
          backgroundColor = Colors.yellowAccent;
          fontSize = 20;
          padding = const EdgeInsets.symmetric(vertical: 10.0);
        }

        return Padding(
          padding: padding,
          child: Container(
            color: backgroundColor,
            child: Text(
              listItems[index],
              style: TextStyle(fontSize: fontSize, color: Colors.black),
            ),
          ),
        );
      },
    );
  }

  Map<int, String> AddChar(
      Map<int, String> mapToBeAdded, Map<int, String> mapToAdd) {
    Map<int, String> charPositions = {...mapToBeAdded};
    for (var entry in mapToAdd.entries) {
      charPositions[entry.key] = entry.value;
    }
    return charPositions;
  }

  String InsertChars(String originalString, Map<int, String> charPositions) {
    List<MapEntry<int, String>> sortedCharPositions =
        charPositions.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    String resultString = "";
    int previousPosition = 0;

    for (MapEntry<int, String> entry in sortedCharPositions) {
      resultString +=
          originalString.substring(previousPosition, entry.key) + entry.value;
      previousPosition = entry.key;
    }
    resultString += originalString.substring(previousPosition);

    return resultString;
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    focusNode.dispose();
    super.dispose();
  }
}

class TogglePlayPauseShortcut extends Intent {}
