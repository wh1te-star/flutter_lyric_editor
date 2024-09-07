import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/sorted_list.dart';
import 'package:tuple/tuple.dart';

final textPaneMasterProvider = ChangeNotifierProvider((ref) {
  final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
  final TimingService timingService = ref.read(timingMasterProvider);
  return TextPaneProvider(musicPlayerProvider: musicPlayerService, timingService: timingService);
});

class TextPaneProvider with ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;
  final TimingService timingService;

  List<String> lyricAppearance = [];

  SnippetID cursorLinePosition = SnippetID(0);
  int cursorCharPosition = 0;
  int cursorCharPositionRestore = 0;
  Option cursorPositionOption = Option.former;

  List<SnippetID> highlightingSnippetsIDs = [];
  List<List<int>> timingPointsForEachLine = [];
  static const String timingPointChar = '|';

  TextPaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    musicPlayerProvider.addListener(() {
      updateCursorIfNeed();
    });
    timingService.addListener(() {
      Map<SnippetID, LyricSnippet> lyricSnippets = timingService.lyricSnippetList;
      lyricAppearance = List.filled(lyricSnippets.length, '');
      updateLyricAppearance();
    });
  }

  void updateCursorIfNeed() {
    if (highlightingSnippetsIDs.isNotEmpty && !highlightingSnippetsIDs.contains(cursorLinePosition)) {
      cursorLinePosition = highlightingSnippetsIDs[0];
      LyricSnippet nextSnippet = getSnippetWithID(cursorLinePosition);

      if (cursorCharPositionRestore != 0) {
        cursorCharPosition = cursorCharPositionRestore;
      }
      if (cursorCharPosition > nextSnippet.sentence.length) {
        cursorCharPositionRestore = cursorCharPosition;
        cursorCharPosition = nextSnippet.sentence.length;
      }

      //cursorBlinker.restartCursorTimer();
    }
  }

  LyricSnippet getSnippetWithID(SnippetID id) {
    final Map<SnippetID, LyricSnippet> lyricSnippetList = timingService.lyricSnippetList;
    return lyricSnippetList[id]!;
  }

  int countOccurrences(List<int> list, int number) {
    return list.where((element) => element == number).length;
  }

  void updateLyricAppearance() {
    final List<LyricSnippet> lyricSnippetList = timingService.lyricSnippetList.values.toList();
    timingPointsForEachLine = lyricSnippetList.map((snippet) => snippet.sentenceSegments.take(snippet.sentenceSegments.length - 1).map((sentenceSegmentMap) => sentenceSegmentMap.wordLength).fold<List<int>>([], (acc, pos) => acc..add((acc.isEmpty ? 0 : acc.last) + pos))).toList();
    for (int index = 0; index < timingPointsForEachLine.length; index++) {
      Map<int, String> timingPointsForEachLineMap = {};
      for (int i = 0; i < timingPointsForEachLine[index].length; i++) {
        int key = timingPointsForEachLine[index][i];
        if (timingPointsForEachLineMap.containsKey(key)) {
          timingPointsForEachLineMap[key] = timingPointsForEachLineMap[key]! + timingPointChar;
        } else {
          timingPointsForEachLineMap[key] = timingPointChar;
        }
      }
      lyricAppearance[index] = insertChars(lyricSnippetList[index].sentence, timingPointsForEachLineMap);
    }

    notifyListeners();
  }

  String insertChars(String originalString, Map<int, String> charPositions) {
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

  void moveUpCursor() {
    /*
    int highlightSnippetsIndex = highlightingSnippetsIDs.indexWhere((id) => id == cursorLinePosition);
    if (highlightSnippetsIndex > 0) {
      cursorPositionOption = Option.former;

      cursorLinePosition = highlightingSnippetsIDs[highlightSnippetsIndex - 1];
      LyricSnippet nextSnippet = getSnippetWithID(cursorLinePosition);

      if (cursorCharPositionRestore != 0) {
        cursorCharPosition = cursorCharPositionRestore;
      }
      if (cursorCharPosition > nextSnippet.sentence.length) {
        cursorCharPositionRestore = cursorCharPosition;
        cursorCharPosition = nextSnippet.sentence.length;
      }

      //cursorBlinker.restartCursorTimer();
      debugPrint("K key: LineCursor: ${cursorLinePosition}, CharCursor: ${cursorCharPosition}_${cursorPositionOption}");

      notifyListeners();
    }
    */
  }

  void moveDownCursor() {
    /*
    int highlightSnippetsIndex = highlightingSnippetsIDs.indexWhere((id) => id == cursorLinePosition);
    if (highlightSnippetsIndex < highlightingSnippetsIDs.length - 1) {
      cursorPositionOption = Option.former;

      cursorLinePosition = highlightingSnippetsIDs[highlightSnippetsIndex + 1];
      LyricSnippet nextSnippet = getSnippetWithID(cursorLinePosition);

      if (cursorCharPositionRestore != 0) {
        cursorCharPosition = cursorCharPositionRestore;
      }
      if (cursorCharPosition > nextSnippet.sentence.length) {
        cursorCharPositionRestore = cursorCharPosition;
        cursorCharPosition = nextSnippet.sentence.length;
      }

      //cursorBlinker.restartCursorTimer();
      debugPrint("J key: LineCursor: ${cursorLinePosition}, CharCursor: ${cursorCharPosition}_${cursorPositionOption}");

      notifyListeners();
    }
    */
  }

  void moveLeftCursor() {
    /*
    if (cursorCharPosition > 0) {
      cursorCharPositionRestore = 0;

      int snippetIndex = getSnippetIndexWithID(cursorLinePosition);
      if (cursorPositionOption == Option.former) {
        cursorCharPosition--;
        if (countOccurrences(timingPointsForEachLine[snippetIndex], cursorCharPosition) >= 2) {
          cursorPositionOption = Option.latter;
        }
      } else {
        cursorPositionOption = Option.former;
      }

      //cursorBlinker.restartCursorTimer();
      debugPrint("H key: LineCursor: ${cursorLinePosition}, CharCursor: ${cursorCharPosition}_${cursorPositionOption}");

      notifyListeners();
    }
    */
  }

  void moveRightCursor() {
    /*
    if (cursorCharPosition < getSnippetWithID(cursorLinePosition).sentence.length) {
      cursorCharPositionRestore = 0;

      int snippetIndex = getSnippetIndexWithID(cursorLinePosition);
      if (cursorPositionOption == Option.former) {
        if (countOccurrences(timingPointsForEachLine[snippetIndex], cursorCharPosition) >= 2) {
          cursorPositionOption = Option.latter;
        } else {
          cursorCharPosition++;
        }
      } else {
        cursorCharPosition++;
        cursorPositionOption = Option.former;
      }

      //cursorBlinker.restartCursorTimer();
      debugPrint("L key: LineCursor: ${cursorLinePosition}, CharCursor: ${cursorCharPosition}_${cursorPositionOption}");

      notifyListeners();
    }
    */
  }
}

class TextPane extends ConsumerStatefulWidget {
  final FocusNode focusNode;

  TextPane({required this.focusNode}) : super(key: Key('TextPane'));

  @override
  _TextPaneState createState() => _TextPaneState(focusNode);
}

class _TextPaneState extends ConsumerState<TextPane> {
  final FocusNode focusNode;

  static const String cursorChar = '\xa0';
  //static const String sectionChar = '\n\n';

  late CursorBlinker cursorBlinker;

  double lineHeight = 20;

  List<SnippetID> selectingSnippets = [];

  SortedMap<int, String> sentenceSegmentMap = SortedMap<int, String>();
  SortedMap<int, String> sectionPointMap = SortedMap<int, String>();

  int selectionBasePosition = 0;

  _TextPaneState(this.focusNode);

  @override
  void initState() {
    super.initState();

    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);
    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);

    musicPlayerService.addListener(() {
      setState(() {});
    });

    timingService.addListener(() {
      setState(() {});
    });

    textPaneProvider.addListener(() {
      setState(() {});
    });

    cursorBlinker = CursorBlinker(
        blinkIntervalInMillisec: 1000,
        onTick: () {
          setState(() {});
        });
  }

  LyricSnippet getSnippetWithID(SnippetID id) {
    final Map<SnippetID, LyricSnippet> lyricSnippetList = ref.read(timingMasterProvider).lyricSnippetList;
    return lyricSnippetList[id]!;
  }

  int countOccurrences(List<int> list, int number) {
    return list.where((element) => element == number).length;
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
        child: snippetEditColumn(),
      ),
    );
  }

  Widget snippetEditColumn() {
    final TimingService timingService = ref.read(timingMasterProvider);
    List<Widget> elements = [];
    timingService.getCurrentSeekPositionSnippets().values.toList().forEach((snippet) {
      elements.add(snippetEditLine(snippet));
    });

    return Column(
      children: elements,
    );
  }

  Widget snippetEditLine(LyricSnippet snippet) {
    MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    List<Widget> coloredTextWidgets = [];
    PositionTypeInfo position = snippet.getSeekPositionIndex(musicPlayerService.seekPosition);

    for (int index = 0; index < snippet.sentenceSegments.length; index++) {
      String segmentWord = snippet.segmentWord(index);

      if (position.type == PositionType.sentenceSegment && index == position.index) {
        coloredTextWidgets.add(
          segmentEdit(segmentWord),
        );
      } else {
        coloredTextWidgets.add(
          Text(
            segmentWord,
            style: TextStyle(color: Colors.black),
          ),
        );
      }
    }

    return Row(
      children: coloredTextWidgets,
    );
  }

  Widget segmentEdit(String segmentWord) {
    final double charSize = 18.0;
    final double charWidth = 10.0;
    final double cursorWidth = 2.0;
    final double cursorHeight = 24.0;
    final Color cursorColor = Colors.black;

    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    final int cursorPosition = textPaneProvider.cursorCharPosition;
    double cursorCoordinate = calculateCursorPosition(segmentWord, cursorPosition, charSize);
    return Stack(
      children: [
        Text(
          segmentWord,
          style: TextStyle(color: Colors.red),
        ),
        cursorBlinker.isCursorVisible
            ? Positioned(
                left: cursorCoordinate - cursorWidth / 2,
                child: Container(
                  width: cursorWidth,
                  height: cursorHeight,
                  color: cursorColor,
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  double calculateCursorPosition(String text, int cursorPosition, double charSize) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: charSize)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final TextPosition position = TextPosition(offset: cursorPosition);
    final Rect caretPrototype = Rect.fromLTWH(0, 0, 0, textPainter.height);
    final Offset caretOffset = textPainter.getOffsetForCaret(position, caretPrototype);
    return caretOffset.dx;
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
}
