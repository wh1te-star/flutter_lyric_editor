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

  TextPaneCursor cursor = TextPaneCursor(SnippetID(0), 0, Option.former);

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

    if (!currentSnippets.keys.toList().contains(cursor.linePosition)) {
      cursor.linePosition = currentSnippets.keys.toList()[0];
    }

    LyricSnippet snippet = currentSnippets.values.toList()[0];
    int currentSnippetPosition = snippet.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    PositionTypeInfo nextSnippetPosition = snippet.getCharPositionIndex(cursor.charPosition);
    if (currentSnippetPosition != nextSnippetPosition.index) {
      cursor = getDefaultCursorPosition(cursor.linePosition);
      cursorBlinker.restartCursorTimer();
    }
  }

  TextPaneCursor getDefaultCursorPosition(SnippetID id) {
    TextPaneCursor defaultCursor = TextPaneCursor(id, 0, Option.former);

    LyricSnippet snippet = getSnippetWithID(id);
    int currentSnippetPosition = snippet.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    defaultCursor.charPosition = snippet.timingPoints[currentSnippetPosition].charPosition + 1;
    defaultCursor.option = Option.former;

    return defaultCursor;
  }

  LyricSnippet getSnippetWithID(SnippetID id) {
    final Map<SnippetID, LyricSnippet> lyricSnippetList = timingService.lyricSnippetList;
    return lyricSnippetList[id]!;
  }

  int countOccurrences(List<int> list, int number) {
    return list.where((element) => element == number).length;
  }

  void moveUpCursor() {
    Map<SnippetID, LyricSnippet> currentSnippets = timingService.getCurrentSeekPositionSnippets();
    int index = currentSnippets.keys.toList().indexWhere((id) => id == cursor.linePosition);
    if (index == -1) {
      return;
    }
    if (index - 1 < 0) {
      return;
    }
    cursor.linePosition = currentSnippets.keys.toList()[index - 1];
    cursor = getDefaultCursorPosition(cursor.linePosition);

    notifyListeners();
  }

  void moveDownCursor() {
    Map<SnippetID, LyricSnippet> currentSnippets = timingService.getCurrentSeekPositionSnippets();
    int index = currentSnippets.keys.toList().indexWhere((id) => id == cursor.linePosition);
    if (index == -1) {
      return;
    }
    if (index + 1 >= currentSnippets.length) {
      return;
    }
    cursor.linePosition = currentSnippets.keys.toList()[index + 1];
    cursor = getDefaultCursorPosition(cursor.linePosition);

    notifyListeners();
  }

  void moveLeftCursor() {
    if (!timingService.lyricSnippetList.containsKey(cursor.linePosition)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetList[cursor.linePosition]!;
    PositionTypeInfo snippetPositionInfo = snippet.getCharPositionIndex(cursor.charPosition);
    int seekPositionInfo = snippet.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    int charPositionIndex = snippetPositionInfo.index;
    if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
      charPositionIndex++;
    }

    if (snippetPositionInfo.duplicate && cursor.option == Option.latter) {
      cursor.option = Option.former;
    } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo + 1) {
      if (cursor.charPosition - 1 > 0) {
        cursor.charPosition--;

        if (snippet.getCharPositionIndex(cursor.charPosition).duplicate) {
          cursor.option = Option.latter;
        } else {
          cursor.option = Option.former;
        }
      }
    } else {
      if (snippet.timingPoints[charPositionIndex - 1].charPosition > 0) {
        cursor.charPosition = snippet.timingPoints[charPositionIndex - 1].charPosition;

        if (snippet.getCharPositionIndex(cursor.charPosition).duplicate) {
          cursor.option = Option.latter;
        } else {
          cursor.option = Option.former;
        }
      }
    }
    debugPrint("cursor.charPosition: $cursor.charPosition of ${cursor.option}");

    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveRightCursor() {
    if (!timingService.lyricSnippetList.containsKey(cursor.linePosition)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetList[cursor.linePosition]!;
    PositionTypeInfo snippetPositionInfo = snippet.getCharPositionIndex(cursor.charPosition);
    int seekPositionInfo = snippet.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    int charPositionIndex = snippetPositionInfo.index;
    if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
      charPositionIndex++;
    }

    if (snippetPositionInfo.duplicate && cursor.option == Option.former) {
      cursor.option = Option.latter;
    } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo) {
      if (cursor.charPosition + 1 < snippet.sentence.length) {
        cursor.charPosition++;
        cursor.option = Option.former;
      }
    } else {
      if (snippet.timingPoints[charPositionIndex + 1].charPosition < snippet.sentence.length) {
        cursor.charPosition = snippet.timingPoints[charPositionIndex + 1].charPosition;
        cursor.option = Option.former;
      }
    }
    debugPrint("cursor.charPosition: $cursor.charPosition of ${cursor.option}");

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
    var currentSnippets = timingService.getCurrentSeekPositionSnippets();
    double maxWidth = 0.0;
    TextStyle style = TextStyle(letterSpacing: 2.0);

    double rowHeight = calculateTextSize("dummy text", style).height;
    for (var entry in currentSnippets.entries) {
      LyricSnippet snippet = entry.value;
      String timingPointString = TextPaneProvider.timingPointChar * (snippet.timingPoints.length - 2);
      double sentenceWidth = calculateTextSize(snippet.sentence + timingPointString, style).width + 10.0;
      if (sentenceWidth > maxWidth) {
        maxWidth = sentenceWidth;
      }
    }
    double sideBandWidth = 30.0;
    for (var entry in currentSnippets.entries) {
      SnippetID id = entry.key;
      LyricSnippet snippet = entry.value;
      Color vocalistColor = Color(timingService.vocalistColorMap[snippet.vocalistID]!.color);
      elements.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: sideBandWidth,
              height: rowHeight,
              color: vocalistColor,
            ),
            Container(
              width: maxWidth,
              color: id == textPaneProvider.cursor.linePosition ? Colors.yellowAccent : null,
              child: snippetEditLine(
                snippet,
                id == textPaneProvider.cursor.linePosition,
              ),
            ),
            Container(
              width: sideBandWidth,
              height: rowHeight,
              color: vocalistColor,
            ),
          ],
        ),
      );
    }

    return Column(
      children: elements,
    );
  }

  Widget snippetEditLine(LyricSnippet snippet, bool isInCursor) {
    MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    TimingService timingService = ref.read(timingMasterProvider);
    TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    List<Widget> coloredTextWidgets = [];
    int highlightIndex = snippet.getSegmentIndexFromSeekPosition(musicPlayerService.seekPosition);
    PositionTypeInfo cursorPositionInfo = snippet.getCharPositionIndex(textPaneProvider.cursor.charPosition);

    if (isInCursor) {
      for (int index = 0; index < snippet.sentenceSegments.length; index++) {
        String segmentWord = snippet.segmentWord(index);

        if (index == highlightIndex) {
          int cursorPositionSentence = textPaneProvider.cursor.charPosition;
          int cursorPositionWordStart = timingService.lyricSnippetList[textPaneProvider.cursor.linePosition]!.timingPoints[highlightIndex].charPosition;
          coloredTextWidgets.add(
            segmentEdit(segmentWord, cursorPositionSentence - cursorPositionWordStart),
          );
        } else {
          coloredTextWidgets.add(
            Text(
              segmentWord,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          );
        }

        if (index < snippet.sentenceSegments.length - 1) {
          int timingPointIndex = cursorPositionInfo.index;
          if (textPaneProvider.cursor.option == Option.latter) {
            timingPointIndex++;
          }
          if (textPaneProvider.cursorBlinker.isCursorVisible && cursorPositionInfo.type == PositionType.timingPoint && index == timingPointIndex - 1) {
            coloredTextWidgets.add(
              Text(
                TextPaneProvider.timingPointChar,
                style: TextStyle(
                  color: Colors.white,
                  background: Paint()..color = Colors.black,
                ),
              ),
            );
          } else {
            coloredTextWidgets.add(
              const Text(
                TextPaneProvider.timingPointChar,
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            );
          }
        }
      }
    } else {
      Map<int, String> timingPointMap = {};
      for (int i = 1; i < snippet.timingPoints.length - 1; i++) {
        TimingPoint timingPoint = snippet.timingPoints[i];
        timingPointMap[timingPoint.charPosition] = TextPaneProvider.timingPointChar;
      }

      String outputSentence = insertChars(snippet.sentence, timingPointMap);

      coloredTextWidgets.add(
        Text(
          outputSentence,
          style: TextStyle(
            color: Colors.black,
          ),
        ),
      );
    }

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: coloredTextWidgets,
      ),
    );
  }

  Widget segmentEdit(String segmentWord, int cursorPositionWord) {
    const double charSize = 18.0;
    const double charWidth = 10.0;
    const double cursorWidth = 2.0;
    const double cursorHeight = 24.0;
    const double letterSpacing = 2.0;
    const Color cursorColor = Colors.black;
    TextStyle style = TextStyle(
      //fontSize: charSize,
      letterSpacing: letterSpacing,
    );

    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    if (0 < cursorPositionWord && cursorPositionWord < segmentWord.length) {}
    double cursorCoordinate = calculateCursorPosition(segmentWord, cursorPositionWord, style);

    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          segmentWord,
          style: TextStyle(
            color: Colors.red,
            //fontSize: charSize,
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

  double calculateCursorPosition(String text, int cursorPositionWord, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final TextPosition position = TextPosition(offset: cursorPositionWord);
    final Rect caretPrototype = Rect.fromLTWH(0, 0, 0, textPainter.height);
    final Offset caretOffset = textPainter.getOffsetForCaret(position, caretPrototype);
    return caretOffset.dx;
  }

  Size calculateTextSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return textPainter.size;
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

class TextPaneCursor {
  SnippetID linePosition;
  int charPosition;
  Option option;
  TextPaneCursor(this.linePosition, this.charPosition, this.option);
}
