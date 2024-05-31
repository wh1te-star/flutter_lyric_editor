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

  static const String cursorChar = '●';
  static const String timingPointChar = '|';
  static const String linefeedChar = '\n';
  //static const String sectionChar = '\n\n';

  //String entireLyricString = "";
  int cursorPositionChar = 0;
  int cursorPositionLine = 0;
  List<int> timingPoints = [1, 4, 5, 16, 24, 36, 46, 50, 67, 90];
  List<int> linefeedPoints = [19, 38, 57, 70, 98, 100];
  //List<int> sectionPoints = [82];

  List<List<int>> timingPointsForEachLine = [];

  List<String> listItems = [];
  Map<int, String> timingPointMap = {};
  Map<int, String> linefeedPointMap = {};
  Map<int, String> sectionPointMap = {};

  _TextPaneState(this.masterSubject);

  @override
  void initState() {
    super.initState();

    timingPointMap = timingPoints
        .asMap()
        .map((key, value) => MapEntry(value, timingPointChar));
    linefeedPointMap = linefeedPoints
        .asMap()
        .map((key, value) => MapEntry(value, linefeedChar));
    //sectionPointMap = sectionPoints.asMap().map((key, value) => MapEntry(value, sectionChar));

    masterSubject.stream.listen((signal) {
      if (signal is NotifyLyricParsed) {
        var entireLyricString = signal.entireLyricString;
        var combinedLineMap = <int, String>{};
        combinedLineMap.addAll(linefeedPointMap);
        //combinedMap.addAll(sectionPointMap);
        entireLyricString = InsertChars(entireLyricString, combinedLineMap);
        listItems = entireLyricString.split("\n");

        timingPointsForEachLine = divideLists(timingPoints, linefeedPoints);
        for (int i = 0; i < timingPointsForEachLine.length; i++) {
          Map<int, String> timingPointsForEachLineMap =
              timingPointsForEachLine[i]
                  .asMap()
                  .map((key, value) => MapEntry(value, timingPointChar));
          listItems[i] = InsertChars(listItems[i], timingPointsForEachLineMap);
        }
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
        child: lyricListWidget(),
      ),
    );
  }

  Widget lyricListWidget() {
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

        if (index == cursorPositionLine) {
          return Padding(
            padding: padding,
            child: Container(
              color: backgroundColor,
              child: highlightedLyricItemWidget(
                  listItems[index], cursorPositionLine, cursorPositionChar),
            ),
          );
        } else {
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
        }
      },
    );
  }

  Widget highlightedLyricItemWidget(
      String lyrics, int lineIndex, int charIndex) {
    int timingPointsBeforeCursor = 0;
    List<int> currentLineTimingPoint = timingPointsForEachLine[lineIndex];
    while (timingPointsBeforeCursor < currentLineTimingPoint.length &&
        currentLineTimingPoint[timingPointsBeforeCursor] < charIndex) {
      timingPointsBeforeCursor++;
    }
    int cursorIndexTimingPoints = currentLineTimingPoint.indexOf(charIndex);

    charIndex = charIndex + timingPointsBeforeCursor;
    if (cursorIndexTimingPoints >= 0) {
      lyrics = replaceNthCharacter(lyrics, charIndex, cursorChar);
    } else {
      lyrics = inserCharacterAt(lyrics, charIndex, cursorChar);
    }

    String beforeN = lyrics.substring(0, charIndex);
    String charAtN = lyrics[charIndex].toString();
    String afterN = lyrics.substring(charIndex + 1);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
              text: beforeN,
              style: const TextStyle(fontSize: 20, color: Colors.black)),
          TextSpan(
              text: charAtN,
              style: const TextStyle(fontSize: 40, color: Colors.red)),
          TextSpan(
              text: afterN,
              style: const TextStyle(fontSize: 20, color: Colors.black)),
        ],
      ),
    );
  }

  String replaceNthCharacter(String originalString, int index, String newChar) {
    return originalString.substring(0, index) +
        newChar +
        originalString.substring(index + 1);
  }

  String inserCharacterAt(
      String originalString, int index, String insertingChar) {
    return originalString.substring(0, index) +
        insertingChar +
        originalString.substring(index);
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

  List<List<int>> divideLists(
      List<int> timingPoints, List<int> linefeedPoints) {
    List<List<int>> result = [];
    int start = 0;

    for (int i = 0; i < linefeedPoints.length; i++) {
      int end = linefeedPoints[i];
      List<int> segment =
          timingPoints.where((point) => point > start && point <= end).toList();
      result.add(segment.map((point) => point - start).toList());
      start = end;
    }

    List<int> lastSegment =
        timingPoints.where((point) => point > start).toList();
    result.add(lastSegment.map((point) => point - start).toList());

    return result;
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    focusNode.dispose();
    super.dispose();
  }
}

class TogglePlayPauseShortcut extends Intent {}
