import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/sorted_list.dart';
import 'package:lyric_editor/utility/text_size_functions.dart';
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

  TextPaneCursor cursor = TextPaneCursor(SnippetID(0), false, false, false, 0, Option.former, 0, 0);

  static const String timingPointChar = '|';
  static const String annotationEdgeChar = '▲';

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
    Map<SnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition();
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
    TextPaneCursor defaultCursor = TextPaneCursor(id, false, false, false, 0, Option.former, 0, 0);

    LyricSnippet snippet = getSnippetWithID(id);
    int currentSnippetPosition = snippet.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    defaultCursor.charPosition = snippet.timingPoints[currentSnippetPosition].charPosition + 1;
    defaultCursor.startSegmentIndex = currentSnippetPosition;
    defaultCursor.endSegmentIndex = currentSnippetPosition;
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
    if (!cursor.isSegmentSelectionMode) {
      Map<SnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition();
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
  }

  void moveDownCursor() {
    if (!cursor.isSegmentSelectionMode) {
      Map<SnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition();
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
  }

  void moveLeftCursor() {
    if (!timingService.lyricSnippetList.containsKey(cursor.linePosition)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetList[cursor.linePosition]!;

    if (!cursor.isSegmentSelectionMode) {
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
    } else {
      if (!cursor.isRangeSelection) {
        int nextSegmentIndex = cursor.startSegmentIndex - 1;
        if (nextSegmentIndex >= 0) {
          cursor.startSegmentIndex = nextSegmentIndex;
          cursor.endSegmentIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.endSegmentIndex - 1;
        if (nextSegmentIndex >= 0) {
          cursor.endSegmentIndex = nextSegmentIndex;
        }
      }
    }

    debugPrint("${cursor}");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveRightCursor() {
    if (!timingService.lyricSnippetList.containsKey(cursor.linePosition)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetList[cursor.linePosition]!;

    if (!cursor.isSegmentSelectionMode) {
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
    } else {
      if (!cursor.isRangeSelection) {
        int nextSegmentIndex = cursor.startSegmentIndex + 1;
        if (nextSegmentIndex < snippet.sentenceSegments.length) {
          cursor.startSegmentIndex = nextSegmentIndex;
          cursor.endSegmentIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.endSegmentIndex + 1;
        if (nextSegmentIndex < snippet.sentenceSegments.length) {
          cursor.endSegmentIndex = nextSegmentIndex;
        }
      }
    }

    debugPrint("${cursor}");
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
    var currentSnippets = timingService.getSnippetsAtSeekPosition();
    double maxWidth = 0.0;
    TextStyle style = TextStyle(letterSpacing: 2.0);

    double rowHeight = getSizeFromTextStyle("dummy text", style).height;
    for (var entry in currentSnippets.entries) {
      LyricSnippet snippet = entry.value;
      String timingPointString = TextPaneProvider.timingPointChar * (snippet.timingPoints.length - 2);
      double sentenceWidth = getSizeFromTextStyle(snippet.sentence + timingPointString, style).width + 10.0;
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
              height: 2 * rowHeight,
              color: vocalistColor,
            ),
            Container(
              width: maxWidth,
              color: id == textPaneProvider.cursor.linePosition ? Colors.yellowAccent : null,
              child: snippetEditLine(id, snippet),
            ),
            Container(
              width: sideBandWidth,
              height: 2 * rowHeight,
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

  Widget snippetEditLine(SnippetID id, LyricSnippet snippet) {
    MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    TimingService timingService = ref.read(timingMasterProvider);
    TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    PositionTypeInfo cursorPositionInfo = snippet.getCharPositionIndex(textPaneProvider.cursor.charPosition);

    int cursorPositionSentence = textPaneProvider.cursor.charPosition;
    int cursorPositionWordStart = snippet.timingPoints[incursorIndex].charPosition;
    int cursorPositionWord = cursorPositionSentence - cursorPositionWordStart;

    TextStyle textStyle = TextStyle(
      color: Colors.black,
    );
    TextStyle textStyleIncursor = TextStyle(
      color: textPaneProvider.cursorBlinker.isCursorVisible ? Colors.white : Colors.black,
      background: textPaneProvider.cursorBlinker.isCursorVisible ? (Paint()..color = Colors.black) : null,
    );
    TextStyle annotationTextStyle = TextStyle(
      color: Colors.black,
    );
    TextStyle annotationDummyTextStyle = TextStyle(
      color: Colors.transparent,
    );
    TextStyle annotationTextStyleIncursor = TextStyle(
      color: Colors.white,
      background: Paint()..color = Colors.black,
    );
    List<Widget> sentenceRowWidgets = [];
    List<Widget> annotationRowWidgets = [];
    List<Tuple2<SegmentRange, Annotation?>> rangeList = getRangeListForAnnotations(snippet.annotations, snippet.sentenceSegments.length);
    for (int index = 0; index < rangeList.length; index++) {
      Tuple2<SegmentRange, Annotation?> element = rangeList[index];
      SegmentRange segmentRange = element.item1;
      Annotation? annotation = element.item2;

      if (annotation == null) {
        sentenceRowWidgets += sentenceLineWidgets(
          snippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1),
          incursorIndex,
          cursorPositionWord,
          textPaneProvider.cursor,
          cursorPositionInfo,
          textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
          textStyle,
          textStyleIncursor,
          textStyle,
          textStyleIncursor,
        );

        annotationRowWidgets += sentenceLineWidgets(
          snippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1),
          -1,
          -1,
          textPaneProvider.cursor,
          cursorPositionInfo,
          textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
          annotationDummyTextStyle,
          annotationDummyTextStyle,
          annotationDummyTextStyle,
          annotationDummyTextStyle,
        );
      } else {
        String sentenceString = snippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1).map((SentenceSegment segment) => segment.word).join('');
        String sentenceTimingPointString = "\xa0${TextPaneProvider.timingPointChar}\xa0" * (segmentRange.endIndex - segmentRange.startIndex);

        double sentenceRowWidth = getSizeFromTextStyle(sentenceString, textStyle).width + getSizeFromTextStyle(sentenceTimingPointString, textStyle).width + 1;

        List<Widget> sentenceRow = sentenceLineWidgets(
          snippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1),
          incursorIndex,
          cursorPositionWord,
          textPaneProvider.cursor,
          cursorPositionInfo,
          textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
          textStyle,
          textStyleIncursor,
          textStyle,
          textStyleIncursor,
        );

        List<Widget> annotationRow = sentenceLineWidgets(
          annotation.sentenceSegments,
          incursorIndex,
          cursorPositionWord,
          textPaneProvider.cursor,
          cursorPositionInfo,
          textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
          textStyle,
          textStyleIncursor,
          textStyle,
          textStyleIncursor,
        );

        sentenceRowWidgets += [
          SizedBox(
            width: sentenceRowWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: sentenceRow,
            ),
          ),
        ];
        annotationRowWidgets += [
          SizedBox(
            width: sentenceRowWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: annotationRow,
            ),
          ),
        ];
      }

      if (index < rangeList.length - 1) {
        sentenceRowWidgets.add(
          Text(
            "\xa0${TextPaneProvider.annotationEdgeChar}\xa0",
            style: textStyle,
          ),
        );
        annotationRowWidgets.add(
          Text(
            "\xa0${TextPaneProvider.annotationEdgeChar}\xa0",
            style: textStyle,
          ),
        );
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: annotationRowWidgets,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: sentenceRowWidgets,
        ),
      ],
    );
  }

  List<Widget> sentenceLineWidgets(
    List<SentenceSegment> segments,
    SegmentRange range,
    int incursorIndex,
    int incursorCharPosition,
    TextPaneCursor cursor,
    PositionTypeInfo cursorPositionInfo,
    Color wordCursorColor,
    TextStyle wordTextStyle,
    TextStyle wordIncursorTextStyle,
    TextStyle timingPointTextStyle,
    TextStyle timingPointIncursorTextStyle,
  ) {
    List<Widget> widgets = [];

    for (int index = range.startIndex; index < range.endIndex; index++) {
      String segmentWord = segments[index].word;
      if (cursor.isSegmentSelectionMode) {
        widgets.add(
          Text(
            segmentWord,
            style: cursor.isInRange(index) ? wordIncursorTextStyle : wordTextStyle,
          ),
        );
      } else {
        const double cursorWidth = 1.0;
        const double cursorHeight = 15.0;
        double cursorCoordinate = calculateCursorPosition(segmentWord, incursorCharPosition, wordTextStyle);

        widgets.add(
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                segmentWord,
                style: index == incursorIndex
                    ? wordTextStyle.copyWith(
                        decoration: TextDecoration.underline,
                      )
                    : wordTextStyle,
              ),
              index == incursorIndex && 0 < incursorCharPosition && incursorCharPosition < segmentWord.length
                  ? Positioned(
                      left: cursorCoordinate - cursorWidth / 2,
                      child: Container(
                        width: cursorWidth,
                        height: cursorHeight,
                        color: wordCursorColor,
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        );
      }

      if (index < segments.length - 1) {
        widgets.add(
          Text(
            "\xa0${TextPaneProvider.timingPointChar}\xa0",
            style: cursorPositionInfo.type == PositionType.timingPoint && index == cursorPositionInfo.index - 1 ? timingPointIncursorTextStyle : timingPointTextStyle,
          ),
        );
      }
    }

    return widgets;
  }

  List<Tuple2<SegmentRange, Annotation?>> getRangeListForAnnotations(Map<SegmentRange, Annotation> annotations, int numberOfSegments) {
    if (annotations.isEmpty) {
      return [
        Tuple2(
          SegmentRange(0, numberOfSegments - 1),
          null,
        ),
      ];
    }

    List<Tuple2<SegmentRange, Annotation?>> rangeList = [];
    int previousEnd = -1;

    for (MapEntry<SegmentRange, Annotation> entry in annotations.entries) {
      SegmentRange segmentRange = entry.key;
      Annotation annotation = entry.value;

      if (previousEnd + 1 <= segmentRange.startIndex - 1) {
        rangeList.add(
          Tuple2(
            SegmentRange(previousEnd + 1, segmentRange.startIndex - 1),
            null,
          ),
        );
      }
      rangeList.add(
        Tuple2(
          segmentRange,
          annotation,
        ),
      );

      previousEnd = segmentRange.endIndex;
    }

    if (previousEnd + 1 <= numberOfSegments - 1) {
      rangeList.add(
        Tuple2(
          SegmentRange(previousEnd + 1, numberOfSegments - 1),
          null,
        ),
      );
    }

    return rangeList;
  }

  List<Widget> getSegmentRangeTextWidgets(List<SentenceSegment> segments, SegmentRange range, TextStyle style) {
    List<Widget> widgets = [];
    for (int index = range.startIndex; index <= range.endIndex; index++) {
      widgets.add(
        Text(
          segments[index].word,
          style: style,
        ),
      );
      if (index < segments.length - 1) {
        widgets.add(
          Text.rich(TextSpan(
            text: "\xa0${TextPaneProvider.timingPointChar}\xa0",
            style: style,
          )),
        );
      }
    }
    return widgets;
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
  bool isAnnotationSelection;
  bool isSegmentSelectionMode;
  bool isRangeSelection;
  int charPosition;
  Option option;
  int startSegmentIndex;
  int endSegmentIndex;

  bool isInRange(int index) {
    if (startSegmentIndex <= endSegmentIndex) {
      return startSegmentIndex <= index && index <= endSegmentIndex;
    } else {
      return endSegmentIndex <= index && index <= startSegmentIndex;
    }
  }

  TextPaneCursor(
    this.linePosition,
    this.isAnnotationSelection,
    this.isSegmentSelectionMode,
    this.isRangeSelection,
    this.charPosition,
    this.option,
    this.startSegmentIndex,
    this.endSegmentIndex,
  );

  String toString() {
    if (!isSegmentSelectionMode) {
      return "charPosition: ${charPosition}, option: ${option}";
    } else {
      return "segment range: ${startSegmentIndex} - ${endSegmentIndex}";
    }
  }
}
