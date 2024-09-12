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

  late CursorBlinker cursorBlinker;

  SnippetID cursorLinePosition = SnippetID(0);
  int cursorCharPosition = 0;
  Option cursorPositionOption = Option.former;

  static const String timingPointChar = '▲';

  TextPaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    musicPlayerProvider.addListener(() {
      updateCursorIfNeed();
    });

    cursorBlinker = CursorBlinker(
      blinkIntervalInMillisec: 1000,
      onTick: () {
        notifyListeners();
      },
    );
  }

  void updateCursorIfNeed() {
    Map<SnippetID, LyricSnippet> currentSnippets = timingService.getCurrentSeekPositionSnippets();
    if (currentSnippets.isEmpty) {
      return;
    }

    if (!currentSnippets.keys.toList().contains(cursorLinePosition)) {
      cursorLinePosition = currentSnippets.keys.toList()[0];
      cursorCharPosition = 1;
      cursorPositionOption = Option.former;
      cursorBlinker.restartCursorTimer();
      return;
    }

    LyricSnippet snippet = currentSnippets.values.toList()[0];
    int currentSnippetPosition = snippet.getSeekPositionSegmentIndex(musicPlayerProvider.seekPosition);
    PositionTypeInfo nextSnippetPosition = snippet.getCharPositionIndex(cursorCharPosition);
    if (currentSnippetPosition != nextSnippetPosition.index) {
      cursorCharPosition = snippet.timingPoints[currentSnippetPosition].charPosition + 1;
      cursorPositionOption = Option.former;
      cursorBlinker.restartCursorTimer();
    }
  }

  LyricSnippet getSnippetWithID(SnippetID id) {
    final Map<SnippetID, LyricSnippet> lyricSnippetList = timingService.lyricSnippetList;
    return lyricSnippetList[id]!;
  }

  int countOccurrences(List<int> list, int number) {
    return list.where((element) => element == number).length;
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
    Map<SnippetID, LyricSnippet> currentSnippets = timingService.getCurrentSeekPositionSnippets();
    int index = currentSnippets.keys.toList().indexWhere((id) => id == cursorLinePosition);
    if (index == -1) {
      return;
    }
    if (index - 1 < 0) {
      return;
    }
    cursorLinePosition = currentSnippets.keys.toList()[index - 1];
    updateCursorIfNeed();

    notifyListeners();
  }

  void moveDownCursor() {
    Map<SnippetID, LyricSnippet> currentSnippets = timingService.getCurrentSeekPositionSnippets();
    int index = currentSnippets.keys.toList().indexWhere((id) => id == cursorLinePosition);
    if (index == -1) {
      return;
    }
    if (index + 1 >= currentSnippets.length) {
      return;
    }
    cursorLinePosition = currentSnippets.keys.toList()[index + 1];
    updateCursorIfNeed();

    notifyListeners();
  }

  void moveLeftCursor() {
    if (!timingService.lyricSnippetList.containsKey(cursorLinePosition)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetList[cursorLinePosition]!;
    PositionTypeInfo snippetPositionInfo = snippet.getCharPositionIndex(cursorCharPosition);
    int seekPositionInfo = snippet.getSeekPositionSegmentIndex(musicPlayerProvider.seekPosition);
    int charPositionIndex = snippetPositionInfo.index;
    if (cursorPositionOption == Option.latter && snippetPositionInfo.duplicate) {
      charPositionIndex++;
    }

    if (snippetPositionInfo.duplicate && cursorPositionOption == Option.latter) {
      cursorPositionOption = Option.former;
    } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo + 1) {
      if (cursorCharPosition - 1 > 0) {
        cursorCharPosition--;

        if (snippet.getCharPositionIndex(cursorCharPosition).duplicate) {
          cursorPositionOption = Option.latter;
        } else {
          cursorPositionOption = Option.former;
        }
      }
    } else {
      if (snippet.timingPoints[charPositionIndex - 1].charPosition > 0) {
        cursorCharPosition = snippet.timingPoints[charPositionIndex - 1].charPosition;

        if (snippet.getCharPositionIndex(cursorCharPosition).duplicate) {
          cursorPositionOption = Option.latter;
        } else {
          cursorPositionOption = Option.former;
        }
      }
    }
    debugPrint("cursorCharPosition: $cursorCharPosition of ${cursorPositionOption}");

    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveRightCursor() {
    if (!timingService.lyricSnippetList.containsKey(cursorLinePosition)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetList[cursorLinePosition]!;
    PositionTypeInfo snippetPositionInfo = snippet.getCharPositionIndex(cursorCharPosition);
    int seekPositionInfo = snippet.getSeekPositionSegmentIndex(musicPlayerProvider.seekPosition);
    int charPositionIndex = snippetPositionInfo.index;
    if (cursorPositionOption == Option.latter && snippetPositionInfo.duplicate) {
      charPositionIndex++;
    }

    if (snippetPositionInfo.duplicate && cursorPositionOption == Option.former) {
      cursorPositionOption = Option.latter;
    } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo) {
      if (cursorCharPosition + 1 < snippet.sentence.length) {
        cursorCharPosition++;
        cursorPositionOption = Option.former;
      }
    } else {
      if (snippet.timingPoints[charPositionIndex + 1].charPosition < snippet.sentence.length) {
        cursorCharPosition = snippet.timingPoints[charPositionIndex + 1].charPosition;
        cursorPositionOption = Option.former;
      }
    }
    debugPrint("cursorCharPosition: $cursorCharPosition of ${cursorPositionOption}");

    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }
}

class TextPane extends ConsumerStatefulWidget {
  final FocusNode focusNode;

  TextPane({required this.focusNode}) : super(key: const Key('TextPane'));

  @override
  _TextPaneState createState() => _TextPaneState(focusNode);
}

class _TextPaneState extends ConsumerState<TextPane> {
  final FocusNode focusNode;

  static const String cursorChar = '\xa0';
  //static const String sectionChar = '\n\n';

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
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: snippetEditColumn(),
        ),
      ),
    );
  }

  Widget snippetEditColumn() {
    final TimingService timingService = ref.read(timingMasterProvider);
    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    List<Widget> elements = [];
    for (var entry in timingService.getCurrentSeekPositionSnippets().entries) {
      SnippetID id = entry.key;
      LyricSnippet snippet = entry.value;
      elements.add(snippetEditLine(
        snippet,
        id == textPaneProvider.cursorLinePosition,
      ));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: elements,
      ),
    );
  }

  Widget snippetEditLine(LyricSnippet snippet, bool isInCursor) {
    MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    List<Widget> coloredTextWidgets = [];
    int highlightIndex = snippet.getSeekPositionSegmentIndex(musicPlayerService.seekPosition);
    PositionTypeInfo cursorPositionInfo = snippet.getCharPositionIndex(textPaneProvider.cursorCharPosition);

    for (int index = 0; index < snippet.sentenceSegments.length; index++) {
      String segmentWord = snippet.segmentWord(index);
      TimingService timingService = ref.read(timingMasterProvider);

      if (index == highlightIndex) {
        int cursorPositionSentence = textPaneProvider.cursorCharPosition;
        int cursorPositionWordStart = timingService.lyricSnippetList[textPaneProvider.cursorLinePosition]!.timingPoints[highlightIndex].charPosition;
        coloredTextWidgets.add(
          Center(
            child: segmentEdit(segmentWord, cursorPositionSentence - cursorPositionWordStart),
          ),
        );
      } else {
        coloredTextWidgets.add(
          Center(
            child: Text(
              segmentWord,
              style: TextStyle(
                color: Colors.black,
                background: Paint()..color = isInCursor ? Colors.yellowAccent : Colors.white,
              ),
            ),
          ),
        );
      }

      if (index < snippet.sentenceSegments.length - 1) {
        int timingPointIndex = cursorPositionInfo.index;
        if (textPaneProvider.cursorPositionOption == Option.latter) {
          timingPointIndex++;
        }
        if (textPaneProvider.cursorBlinker.isCursorVisible && cursorPositionInfo.type == PositionType.timingPoint && index == timingPointIndex - 1) {
          coloredTextWidgets.add(
            Center(
              child: Text(
                TextPaneProvider.timingPointChar,
                style: TextStyle(
                  color: Colors.white,
                  background: Paint()..color = isInCursor ? Colors.yellowAccent : Colors.black,
                ),
              ),
            ),
          );
        } else {
          coloredTextWidgets.add(
            Center(
              child: Text(
                TextPaneProvider.timingPointChar,
                style: TextStyle(
                  color: Colors.black,
                  background: Paint()..color = isInCursor ? Colors.yellowAccent : Colors.white,
                ),
              ),
            ),
          );
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: coloredTextWidgets,
    );
  }

  Widget segmentEdit(String segmentWord, int cursorPositionWord) {
    const double charSize = 18.0;
    const double charWidth = 10.0;
    const double cursorWidth = 2.0;
    const double cursorHeight = 24.0;
    const double letterSpacing = 2.0;
    const Color cursorColor = Colors.black;

    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    if (0 < cursorPositionWord && cursorPositionWord < segmentWord.length) {}
    double cursorCoordinate = calculateCursorPosition(segmentWord, cursorPositionWord, charSize, letterSpacing);

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          segmentWord,
          style: TextStyle(
            color: Colors.red,
            fontSize: charSize,
            letterSpacing: letterSpacing,
          ),
        ),
        textPaneProvider.cursorBlinker.isCursorVisible && 0 < cursorPositionWord && cursorPositionWord < segmentWord.length
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

  double calculateCursorPosition(String text, int cursorPositionWord, double charSize, double letterSpacing) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: charSize,
            letterSpacing: letterSpacing,
          )),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final TextPosition position = TextPosition(offset: cursorPositionWord);
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
