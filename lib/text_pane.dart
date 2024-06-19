import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lyric_editor/lyric_snippet.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';
import 'sorted_list.dart';

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

  static const String cursorChar = '●';
  static const String timingPointChar = '|';
  static const String linefeedChar = '\n';
  //static const String sectionChar = '\n\n';

  String entireLyricString = "";
  int cursorPosition = 0;
  int seekPosition = 0;

  List<LyricSnippet> lyricSnippets = [];
  List<String> lyricAppearance = [];
  int cursorPositionChar = 0;
  int cursorPositionLine = 0;

  List<List<int>> timingPointsForEachLine = [];

  SortedMap<int, String> timingPointMap = SortedMap<int, String>();
  SortedMap<int, String> sectionPointMap = SortedMap<int, String>();

  _TextPaneState(this.masterSubject, this.focusNode);

  @override
  void initState() {
    super.initState();

    masterSubject.stream.listen((signal) {
      if (signal is NotifyLyricParsed) {
        lyricSnippets = signal.lyricSnippetList;
        lyricAppearance = List.filled(lyricSnippets.length, '');

        updateIndicators();

        setState(() {});
      }

      if (signal is RequestMoveDownCharCursor) {
        moveDownCursor();
      }

      if (signal is RequestMoveUpCharCursor) {
        moveUpCursor();
      }

      if (signal is RequestMoveLeftCharCursor) {
        moveLeftCursor();
      }

      if (signal is RequestMoveRightCharCursor) {
        moveRightCursor();
      }

      if (signal is NotifyTimingPointAdded) {
        timingPointMap[signal.characterPosition] = timingPointChar;
        updateIndicators();
        setState(() {});
      }

      if (signal is NotifyTimingPointDeletion) {
        timingPointMap.remove(signal.characterPosition);
        updateIndicators();
        setState(() {});
      }

      if (signal is NotifySeekPosition) {
        seekPosition = signal.seekPosition;
      }
    });
  }

  void updateIndicators() {
    timingPointsForEachLine = lyricSnippets
        .map((snippet) => snippet.timingPoints
            .take(snippet.timingPoints.length - 1)
            .map((timingPoint) => timingPoint.characterLength)
            .fold<List<int>>(
                [], (acc, pos) => acc..add((acc.isEmpty ? 0 : acc.last) + pos)))
        .toList();
    for (int i = 0; i < timingPointsForEachLine.length; i++) {
      Map<int, String> timingPointsForEachLineMap = timingPointsForEachLine[i]
          .asMap()
          .map((key, value) => MapEntry(value, timingPointChar));
      lyricAppearance[i] =
          InsertChars(lyricSnippets[i].sentence, timingPointsForEachLineMap);
    }
  }

  void moveUpCursor() {
    if (cursorPositionLine > 0) {
      cursorPositionLine--;
      cursorPosition = lyricSnippets
              .take(cursorPositionLine)
              .fold(0, (prev, curr) => prev + curr.sentence.length) +
          cursorPositionChar;
      setState(() {});
      debugPrint(
          "K key: cursor: $cursorPosition, LineCursor: $cursorPositionLine, CharCursor: $cursorPositionChar");
    }
  }

  void moveDownCursor() {
    if (cursorPositionLine < lyricSnippets.length - 1) {
      cursorPositionLine++;
      cursorPosition = lyricSnippets
              .take(cursorPositionLine)
              .fold(0, (prev, curr) => prev + curr.sentence.length) +
          cursorPositionChar;
      setState(() {});
      debugPrint(
          "J key: cursor: $cursorPosition, LineCursor: $cursorPositionLine, CharCursor: $cursorPositionChar");
    }
  }

  void moveLeftCursor() {
    if (cursorPositionChar > 0) {
      cursorPositionChar--;
      cursorPosition--;
      setState(() {});
      debugPrint(
          "H key: cursor: $cursorPosition, LineCursor: $cursorPositionLine, CharCursor: $cursorPositionChar");
    }
  }

  void moveRightCursor() {
    if (cursorPositionChar <=
        lyricSnippets[cursorPositionLine].sentence.length) {
      cursorPositionChar++;
      cursorPosition++;
      setState(() {});
      debugPrint(
          "L key: cursor: $cursorPosition, LineCursor: $cursorPositionLine, CharCursor: $cursorPositionChar");
    }
  }

  void addTimingPoint(int charPosition, int seekPosition) {
    masterSubject.add(RequestToAddLyricTiming(cursorPosition, seekPosition));
    debugPrint(
        "request to add a lyric timing point between ${cursorPosition} and ${cursorPosition + 1} th characters.");
  }

  void deleteTimingPoint(int charPosition) {
    masterSubject.add(RequestToDeleteLyricTiming(cursorPosition));
    debugPrint(
        "request to delete a lyric timing point between ${cursorPosition} and ${cursorPosition + 1} th characters.");
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
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
      itemCount: lyricSnippets.length,
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
              child: highlightedLyricItemWidget(lyricAppearance[index],
                  cursorPositionLine, cursorPositionChar),
            ),
          );
        } else {
          return Padding(
            padding: padding,
            child: Container(
              color: backgroundColor,
              child: Text(
                lyricAppearance[index],
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
}
