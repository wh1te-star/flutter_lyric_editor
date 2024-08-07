import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lyric_editor/pane/video_pane.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:lyric_editor/utility/sorted_list.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tuple/tuple.dart';

class TextPane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  TextPane({required this.masterSubject, required this.focusNode}) : super(key: Key('TextPane'));

  @override
  _TextPaneState createState() => _TextPaneState(masterSubject, focusNode);
}

class _TextPaneState extends State<TextPane> {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  static const String cursorChar = '\xa0';
  static const String timingPointChar = '|';
  static const String linefeedChar = '\n';
  //static const String sectionChar = '\n\n';

  int cursorBlinkInterval = 1;
  bool isCursorVisible = true;
  late Timer cursorTimer;

  int seekPosition = 0;

  int maxLanes = 0;
  double lineHeight = 20;
  List<LyricSnippet> lyricSnippets = [];
  List<String> lyricAppearance = [];
  LyricSnippetID cursorLinePosition = LyricSnippetID(Vocalist("", 0), 0);
  int cursorCharPosition = 0;
  int cursorCharPositionRestore = 0;

  List<LyricSnippetID> selectingSnippets = [];

  List<List<int>> timingPointsForEachLine = [];

  List<LyricSnippetID> highlightingSnippetsIDs = [];

  SortedMap<int, String> timingPointMap = SortedMap<int, String>();
  SortedMap<int, String> sectionPointMap = SortedMap<int, String>();

  bool TextSelectMode = false;
  int selectionBasePosition = 0;

  _TextPaneState(this.masterSubject, this.focusNode);

  @override
  void initState() {
    super.initState();

    masterSubject.stream.listen((signal) {
      if (signal is NotifyLyricParsed || signal is NotifySnippetDivided || signal is NotifySnippetConcatenated || signal is NotifyUndo) {
        lyricSnippets = signal.lyricSnippetList;
        lyricAppearance = List.filled(lyricSnippets.length, '');
        updateIndicators();
        maxLanes = getMaxTracks(lyricSnippets);
      }

      if (signal is NotifyTimingPointAdded || signal is NotifyTimingPointDeleted) {
        lyricSnippets = signal.lyricSnippetList;
        lyricAppearance = List.filled(lyricSnippets.length, '');
        updateIndicators();
        maxLanes = getMaxTracks(lyricSnippets);
      }

      if (signal is RequestMoveDownCharCursor) {
        moveDownCursor();
        masterSubject.add(NotifyCharCursorPosition(cursorCharPosition));
        masterSubject.add(NotifyLineCursorPosition(cursorLinePosition));
      }

      if (signal is RequestMoveUpCharCursor) {
        moveUpCursor();
        masterSubject.add(NotifyCharCursorPosition(cursorCharPosition));
        masterSubject.add(NotifyLineCursorPosition(cursorLinePosition));
      }

      if (signal is RequestMoveLeftCharCursor) {
        moveLeftCursor();
        masterSubject.add(NotifyCharCursorPosition(cursorCharPosition));
        masterSubject.add(NotifyLineCursorPosition(cursorLinePosition));
      }

      if (signal is RequestMoveRightCharCursor) {
        moveRightCursor();
        masterSubject.add(NotifyCharCursorPosition(cursorCharPosition));
        masterSubject.add(NotifyLineCursorPosition(cursorLinePosition));
      }

      if (signal is NotifySelectingSnippets) {
        selectingSnippets = signal.snippetIDs;
      }

      if (signal is NotifySeekPosition) {
        seekPosition = signal.seekPosition;
        updateCursorIfNeed();
      }

      if (signal is RequestToEnterTextSelectMode) {
        TextSelectMode = true;
        selectionBasePosition = cursorCharPosition;
      }

      if (signal is RequestToExitTextSelectMode) {
        TextSelectMode = false;
        lyricAppearance = List.filled(lyricSnippets.length, '');
        updateIndicators();
        cursorCharPosition = getSnippetWithID(cursorLinePosition).sentence.length;
      }
      setState(() {});
    });

    cursorTimer = Timer.periodic(Duration(seconds: cursorBlinkInterval), (timer) {
      isCursorVisible = !isCursorVisible;
      setState(() {});
    });
  }

  int getSnippetIndexWithID(LyricSnippetID id) {
    return lyricSnippets.indexWhere((snippet) => snippet.id == id);
  }

  LyricSnippet getSnippetWithID(LyricSnippetID id) {
    return lyricSnippets.firstWhere((snippet) => snippet.id == id);
  }

  void updateCursorIfNeed() {
    if (highlightingSnippetsIDs.isNotEmpty && !highlightingSnippetsIDs.contains(cursorLinePosition)) {
      cursorLinePosition = highlightingSnippetsIDs[0];
    }
  }

  void updateIndicators() {
    timingPointsForEachLine = lyricSnippets.map((snippet) => snippet.timingPoints.take(snippet.timingPoints.length - 1).map((timingPoint) => timingPoint.wordLength).fold<List<int>>([], (acc, pos) => acc..add((acc.isEmpty ? 0 : acc.last) + pos))).toList();
    for (int i = 0; i < timingPointsForEachLine.length; i++) {
      Map<int, String> timingPointsForEachLineMap = timingPointsForEachLine[i].asMap().map((key, value) => MapEntry(value, timingPointChar));
      lyricAppearance[i] = InsertChars(lyricSnippets[i].sentence, timingPointsForEachLineMap);
    }
  }

  void moveUpCursor() {
    int highlightSnippetsIndex = highlightingSnippetsIDs.indexWhere((id) => id == cursorLinePosition);
    if (highlightSnippetsIndex > 0) {
      cursorLinePosition = highlightingSnippetsIDs[highlightSnippetsIndex - 1];
      LyricSnippet nextSnippet = getSnippetWithID(cursorLinePosition);

      if (cursorCharPositionRestore != 0) {
        cursorCharPosition = cursorCharPositionRestore;
      }
      if (cursorCharPosition > nextSnippet.sentence.length) {
        cursorCharPositionRestore = cursorCharPosition;
        cursorCharPosition = nextSnippet.sentence.length;
      }

      restartCursorTimer();
      debugPrint("K key: LineCursor: ${cursorLinePosition}, CharCursor: $cursorCharPosition");
    }
  }

  void moveDownCursor() {
    int highlightSnippetsIndex = highlightingSnippetsIDs.indexWhere((id) => id == cursorLinePosition);
    if (highlightSnippetsIndex < highlightingSnippetsIDs.length - 1) {
      cursorLinePosition = highlightingSnippetsIDs[highlightSnippetsIndex + 1];
      LyricSnippet nextSnippet = getSnippetWithID(cursorLinePosition);

      if (cursorCharPositionRestore != 0) {
        cursorCharPosition = cursorCharPositionRestore;
      }
      if (cursorCharPosition > nextSnippet.sentence.length) {
        cursorCharPositionRestore = cursorCharPosition;
        cursorCharPosition = nextSnippet.sentence.length;
      }

      restartCursorTimer();
      debugPrint("J key: LineCursor: ${cursorLinePosition}, CharCursor: $cursorCharPosition");
    }
  }

  void moveLeftCursor() {
    if (cursorCharPosition > 0) {
      cursorCharPositionRestore = 0;
      cursorCharPosition--;
      restartCursorTimer();
      debugPrint("H key: LineCursor: $cursorLinePosition, CharCursor: $cursorCharPosition");
    }
  }

  void moveRightCursor() {
    if (cursorCharPosition < getSnippetWithID(cursorLinePosition).sentence.length) {
      cursorCharPositionRestore = 0;
      cursorCharPosition++;
      restartCursorTimer();
      debugPrint("L key: LineCursor: $cursorLinePosition, CharCursor: $cursorCharPosition");
    }
  }

  void pauseCursorTimer() {
    cursorTimer.cancel();
  }

  void restartCursorTimer() {
    cursorTimer.cancel();
    isCursorVisible = true;
    cursorTimer = Timer.periodic(Duration(seconds: cursorBlinkInterval), (timer) {
      isCursorVisible = !isCursorVisible;
      setState(() {});
    });
  }

  Tuple3<List<LyricSnippetID>, List<LyricSnippetID>, List<LyricSnippetID>> getSnippetIDsAtCurrentSeekPosition() {
    List<LyricSnippetID> beforeSnippetIndexes = [];
    List<LyricSnippetID> currentSnippetIndexes = [];
    List<LyricSnippetID> afterSnippetIndexes = [];
    lyricSnippets.forEach((LyricSnippet snippet) {
      int start = snippet.startTimestamp;
      int end = snippet.endTimestamp;
      if (seekPosition < start) {
        beforeSnippetIndexes.add(snippet.id);
      } else if (seekPosition < end) {
        currentSnippetIndexes.add(snippet.id);
      } else {
        afterSnippetIndexes.add(snippet.id);
      }
    });
    return Tuple3(beforeSnippetIndexes, currentSnippetIndexes, afterSnippetIndexes);
  }

  int getMaxTracks(List<LyricSnippet> lyricSnippetList) {
    int maxOverlap = 0;
    int currentOverlap = 1;
    int currentEndTime = lyricSnippetList[0].endTimestamp;

    for (int i = 1; i < lyricSnippetList.length; ++i) {
      int start = lyricSnippetList[i].startTimestamp;
      int end = lyricSnippetList[i].endTimestamp;
      if (start <= currentEndTime) {
        currentOverlap++;
      } else {
        currentOverlap = 1;
        currentEndTime = end;
      }
      if (currentOverlap > maxOverlap) {
        maxOverlap = currentOverlap;
      }

      if (currentOverlap > maxLanes) {
        maxLanes = currentOverlap;
      }
    }
    return maxLanes;
  }

  List<int> getIndexFromIDs(List<LyricSnippetID> lyricSnippetIDs) {
    List<int> indexes = [];
    for (int i = 0; i < lyricSnippets.length; i++) {
      if (lyricSnippetIDs.contains(lyricSnippets[i].id)) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTap: () {
          focusNode.requestFocus();
          debugPrint("The text pane is focused");
          setState(() {});
        },
        child: lyricListWidget(),
      ),
    );
  }

  Widget lyricListWidget() {
    final indexesTuple = getSnippetIDsAtCurrentSeekPosition();
    late List<LyricSnippetID> beforeSnippetIDs;
    late List<LyricSnippetID> currentSnippetIDs;
    late List<LyricSnippetID> afterSnippetIDs;
    if (selectingSnippets.isEmpty) {
      beforeSnippetIDs = indexesTuple.item1;
      currentSnippetIDs = indexesTuple.item2;
      afterSnippetIDs = indexesTuple.item3;
    } else {
      beforeSnippetIDs = indexesTuple.item1 + indexesTuple.item2;
      currentSnippetIDs = selectingSnippets;
      afterSnippetIDs = indexesTuple.item3;
    }
    highlightingSnippetsIDs = currentSnippetIDs;

    late double height;
    if (selectingSnippets.length < maxLanes) {
      height = lineHeight * maxLanes;
    } else {
      height = lineHeight * selectingSnippets.length;
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: afterSnippetIDs.length,
            itemBuilder: (context, index) {
              int lyricSnippetIndex = getSnippetIndexWithID(afterSnippetIDs[index]);
              return Text(lyricAppearance[lyricSnippetIndex]);
            },
          ),
        ),
        Center(
          child: Container(
            height: height,
            color: Colors.yellowAccent,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: currentSnippetIDs.length,
              itemBuilder: (context, index) {
                int lyricSnippetIndex = getSnippetIndexWithID(currentSnippetIDs[index]);
                if (currentSnippetIDs[index] == cursorLinePosition) {
                  return highlightedLyricItem(lyricAppearance[lyricSnippetIndex], cursorLinePosition, cursorCharPosition);
                } else {
                  return Text(lyricAppearance[lyricSnippetIndex]);
                }
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: beforeSnippetIDs.length,
            itemBuilder: (context, index) {
              int lyricSnippetIndex = getSnippetIndexWithID(beforeSnippetIDs[index]);
              return Text(lyricAppearance[lyricSnippetIndex]);
            },
          ),
        ),
      ],
    );
  }

  Widget highlightedLyricItem(String lyrics, LyricSnippetID snippetID, int charIndex) {
    int timingPointsBeforeCursor = 0;
    int lineIndex = getSnippetIndexWithID(snippetID);
    List<int> currentLineTimingPoint = timingPointsForEachLine[lineIndex];
    while (timingPointsBeforeCursor < currentLineTimingPoint.length && currentLineTimingPoint[timingPointsBeforeCursor] < charIndex) {
      timingPointsBeforeCursor++;
    }
    int cursorIndexTimingPoints = currentLineTimingPoint.indexOf(charIndex);

    charIndex = charIndex + timingPointsBeforeCursor;
    if (cursorIndexTimingPoints >= 0) {
      lyrics = replaceNthCharacter(lyrics, charIndex, cursorChar);
    } else {
      lyrics = insertCharacterAt(lyrics, charIndex, cursorChar);
    }

    String beforeN = lyrics.substring(0, charIndex);
    String charAtN = lyrics[charIndex].toString();
    String afterN = lyrics.substring(charIndex + 1);

    Color cursorColor = isCursorVisible ? Colors.black : Colors.transparent;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: beforeN, style: TextStyle(fontSize: 14, color: Colors.black)),
          TextSpan(text: charAtN, style: TextStyle(fontSize: 14, backgroundColor: cursorColor)),
          TextSpan(text: afterN, style: TextStyle(fontSize: 14, color: Colors.black)),
        ],
      ),
    );
  }

  Widget highlightedLyricItemSelectionMode(String lyrics, int lineIndex, int charIndex) {
    String beforeSelect = lyrics.substring(0, selectionBasePosition);
    String selecting = lyrics.substring(selectionBasePosition, cursorCharPosition);
    String afterSelect = lyrics.substring(cursorCharPosition);

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: beforeSelect,
            style: const TextStyle(fontSize: 20, color: Colors.black),
          ),
          TextSpan(
            text: selecting,
            style: const TextStyle(fontSize: 20, color: Colors.black, backgroundColor: Colors.blue),
          ),
          TextSpan(
            text: afterSelect,
            style: const TextStyle(fontSize: 20, color: Colors.black),
          ),
        ],
      ),
    );
  }

  String replaceNthCharacter(String originalString, int index, String newChar) {
    return originalString.substring(0, index) + newChar + originalString.substring(index + 1);
  }

  String insertCharacterAt(String originalString, int index, String insertingChar) {
    return originalString.substring(0, index) + insertingChar + originalString.substring(index);
  }

  Map<int, String> AddChar(Map<int, String> mapToBeAdded, Map<int, String> mapToAdd) {
    Map<int, String> charPositions = {...mapToBeAdded};
    for (var entry in mapToAdd.entries) {
      charPositions[entry.key] = entry.value;
    }
    return charPositions;
  }

  String InsertChars(String originalString, Map<int, String> charPositions) {
    List<MapEntry<int, String>> sortedCharPositions = charPositions.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    String resultString = "";
    int previousPosition = 0;

    for (MapEntry<int, String> entry in sortedCharPositions) {
      resultString += originalString.substring(previousPosition, entry.key) + entry.value;
      previousPosition = entry.key;
    }
    resultString += originalString.substring(previousPosition);

    return resultString;
  }
}
