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

  TextPaneCursor cursor = TextPaneCursor.emptyValue;

  static const String timingPointChar = '|';
  static const String annotationEdgeChar = '▲';

  TextPaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    musicPlayerProvider.addListener(() {
      updateCursorIfNeedBySeekPosition();
    });

    timingService.addListener(() {
      updateCursorIfNeedByItemDeletion();
    });

    cursorBlinker = CursorBlinker(
      blinkIntervalInMillisec: 1000,
      onTick: () {
        notifyListeners();
      },
    );
  }

  void updateCursorIfNeedBySeekPosition() {
    Map<SnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition();
    if (currentSnippets.isEmpty) {
      return;
    }

    if (!currentSnippets.keys.toList().contains(cursor.snippetID)) {
      cursor.snippetID = currentSnippets.keys.first;
    }

    LyricSnippet snippet = currentSnippets.values.first;
    int currentSnippetPosition = snippet.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    PositionTypeInfo nextSnippetPosition = snippet.getCharPositionIndex(cursor.charPosition);
    if (currentSnippetPosition != nextSnippetPosition.index) {
      cursor = getDefaultCursor(cursor.snippetID);
      cursorBlinker.restartCursorTimer();
    }
  }

  void updateCursorIfNeedByItemDeletion() {
    Map<SnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition();
    if (currentSnippets.isEmpty) {
      return;
    }

    LyricSnippet? snippet = timingService.lyricSnippetList[cursor.snippetID];
    if (snippet == null) {
      cursor = getDefaultCursor(SnippetID(1));
      return;
    }

    if (!cursor.isAnnotationSelection) {
      return;
    }

    Annotation? annotation = snippet.annotations[cursor.annotationSegmentRange];
    if (annotation == null) {
      cursor = getDefaultCursor(cursor.snippetID);
      return;
    }
  }

  TextPaneCursor getDefaultCursor(SnippetID id) {
    TextPaneCursor defaultCursor = TextPaneCursor.emptyValue;
    defaultCursor.isAnnotationSelection = false;

    LyricSnippet snippet = getSnippetWithID(id);
    int currentSnippetPosition = snippet.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    defaultCursor.snippetID = id;
    defaultCursor.charPosition = snippet.timingPoints[currentSnippetPosition].charPosition + 1;
    defaultCursor.option = Option.former;

    return defaultCursor;
  }

  TextPaneCursor getDefaultCursorOfAnnotation(SnippetID id) {
    TextPaneCursor defaultCursor = TextPaneCursor.emptyValue;

    defaultCursor.isAnnotationSelection = true;

    LyricSnippet snippet = getSnippetWithID(id);
    int? annotationIndex = snippet.getAnnotationIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    MapEntry<SegmentRange, Annotation>? cursorAnnotationEntry = snippet.getAnnotationWords(annotationIndex!);
    SegmentRange range = cursorAnnotationEntry.key;
    Annotation annotation = cursorAnnotationEntry.value;

    int index = annotation.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);

    defaultCursor.snippetID = id;
    defaultCursor.annotationSegmentRange = range;
    defaultCursor.charPosition = annotation.timingPoints[index].charPosition + 1;
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
      LyricSnippet cursorSnippet = timingService.lyricSnippetList[cursor.snippetID]!;

      int? annotationIndex = cursorSnippet.getAnnotationIndexFromSeekPosition(musicPlayerProvider.seekPosition);

      if (cursor.isAnnotationSelection || annotationIndex == null) {
        int index = currentSnippets.keys.toList().indexWhere((id) => id == cursor.snippetID);
        if (index > 0) {
          SnippetID nextSnippetID = currentSnippets.keys.toList()[index - 1];
          cursor = getDefaultCursor(nextSnippetID);
        }
      } else {
        cursor = getDefaultCursorOfAnnotation(cursor.snippetID);
      }
    }

    debugPrint("${cursor}");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveDownCursor() {
    if (!cursor.isSegmentSelectionMode) {
      if (cursor.isAnnotationSelection) {
        cursor = getDefaultCursor(cursor.snippetID);
      } else {
        Map<SnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition();

        int index = currentSnippets.keys.toList().indexWhere((id) => id == cursor.snippetID);
        if (index != -1 && index + 1 < currentSnippets.length) {
          SnippetID nextSnippetID = currentSnippets.keys.toList()[index + 1];
          LyricSnippet nextSnippet = currentSnippets.values.toList()[index + 1];

          int? annotationIndex = nextSnippet.getAnnotationIndexFromSeekPosition(musicPlayerProvider.seekPosition);
          if (annotationIndex == null) {
            cursor = getDefaultCursor(nextSnippetID);
          } else {
            cursor = getDefaultCursorOfAnnotation(nextSnippetID);
          }
        }
      }
    }

    debugPrint("${cursor}");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveLeftCursor() {
    if (!timingService.lyricSnippetList.containsKey(cursor.snippetID)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetList[cursor.snippetID]!;

    if (!cursor.isSegmentSelectionMode) {
      TimingObject object = !cursor.isAnnotationSelection ? snippet : snippet.annotations[cursor.annotationSegmentRange]!;
      PositionTypeInfo snippetPositionInfo = object.getCharPositionIndex(cursor.charPosition);
      int seekPositionInfo = object.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
      int charPositionIndex = snippetPositionInfo.index;
      if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
        charPositionIndex++;
      }

      if (snippetPositionInfo.duplicate && cursor.option == Option.latter) {
        cursor.option = Option.former;
      } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo + 1) {
        if (cursor.charPosition - 1 > 0) {
          cursor.charPosition--;

          if (object.getCharPositionIndex(cursor.charPosition).duplicate) {
            cursor.option = Option.latter;
          } else {
            cursor.option = Option.former;
          }
        }
      } else {
        if (object.timingPoints[charPositionIndex - 1].charPosition > 0) {
          cursor.charPosition = object.timingPoints[charPositionIndex - 1].charPosition;

          if (object.getCharPositionIndex(cursor.charPosition).duplicate) {
            cursor.option = Option.latter;
          } else {
            cursor.option = Option.former;
          }
        }
      }
    } else {
      if (!cursor.isRangeSelection) {
        int nextSegmentIndex = cursor.annotationSegmentRange.startIndex - 1;
        if (nextSegmentIndex >= 0) {
          cursor.annotationSegmentRange.startIndex = nextSegmentIndex;
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.annotationSegmentRange.endIndex - 1;
        if (nextSegmentIndex >= 0) {
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      }
    }

    debugPrint("${cursor}");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveRightCursor() {
    if (!timingService.lyricSnippetList.containsKey(cursor.snippetID)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetList[cursor.snippetID]!;

    if (!cursor.isSegmentSelectionMode) {
      TimingObject object = !cursor.isAnnotationSelection ? snippet : snippet.annotations[cursor.annotationSegmentRange]!;
      PositionTypeInfo snippetPositionInfo = object.getCharPositionIndex(cursor.charPosition);
      int seekPositionInfo = object.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
      int charPositionIndex = snippetPositionInfo.index;
      if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
        charPositionIndex++;
      }

      if (snippetPositionInfo.duplicate && cursor.option == Option.former) {
        cursor.option = Option.latter;
      } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo) {
        if (cursor.charPosition + 1 < object.sentence.length) {
          cursor.charPosition++;
          cursor.option = Option.former;
        }
      } else {
        if (object.timingPoints[charPositionIndex + 1].charPosition < object.sentence.length) {
          cursor.charPosition = object.timingPoints[charPositionIndex + 1].charPosition;
          cursor.option = Option.former;
        }
      }
    } else {
      if (!cursor.isRangeSelection) {
        int nextSegmentIndex = cursor.annotationSegmentRange.startIndex + 1;
        if (nextSegmentIndex < snippet.sentenceSegments.length) {
          cursor.annotationSegmentRange.startIndex = nextSegmentIndex;
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.annotationSegmentRange.endIndex + 1;
        if (nextSegmentIndex < snippet.sentenceSegments.length) {
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
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

    double singleRowHeight = getSizeFromTextStyle("dummy text", style).height;

    for (MapEntry<SnippetID, LyricSnippet> entry in currentSnippets.entries) {
      LyricSnippet snippet = entry.value;
      String timingPointString = TextPaneProvider.timingPointChar * (snippet.timingPoints.length - 2);
      double sentenceWidth = getSizeFromTextStyle(snippet.sentence + timingPointString, style).width + 10.0;
      if (sentenceWidth > maxWidth) {
        maxWidth = sentenceWidth;
      }
    }
    double sideBandWidth = 30.0;
    for (MapEntry<SnippetID, LyricSnippet> entry in currentSnippets.entries) {
      SnippetID id = entry.key;
      LyricSnippet snippet = entry.value;
      Color vocalistColor = Color(timingService.vocalistColorMap[snippet.vocalistID]!.color);

      double rowHeight = snippet.annotations.isEmpty ? singleRowHeight : 2 * singleRowHeight;
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
              //width: maxWidth,
              color: id == textPaneProvider.cursor.snippetID ? Colors.yellowAccent : null,
              child: snippetEditLine(id, snippet),
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

  Widget snippetEditLine(SnippetID id, LyricSnippet snippet) {
    MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    TimingService timingService = ref.read(timingMasterProvider);
    TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    PositionTypeInfo cursorPositionInfo = snippet.getCharPositionIndex(textPaneProvider.cursor.charPosition);

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
    int highlightSegmentIndex = snippet.getSegmentIndexFromSeekPosition(musicPlayerService.seekPosition);
    TextPaneCursor cursor = textPaneProvider.cursor.copyWith();

    for (int index = 0; index < rangeList.length; index++) {
      Tuple2<SegmentRange, Annotation?> element = rangeList[index];
      SegmentRange segmentRange = element.item1;
      Annotation? annotation = element.item2;

      List<SentenceSegment> currentSegmentPartSentence = snippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1);
      String sentenceString = currentSegmentPartSentence.map((SentenceSegment segment) => segment.word).join('');
      String sentenceTimingPointString = "\xa0${TextPaneProvider.timingPointChar}\xa0" * (segmentRange.endIndex - segmentRange.startIndex);
      double sentenceRowWidth = getSizeFromTextStyle(sentenceString, textStyle).width + getSizeFromTextStyle(sentenceTimingPointString, textStyle).width + 10;

      int segmentCharLength = 0;

      if (annotation == null) {
        sentenceRowWidgets += sentenceLineWidgets(
          currentSegmentPartSentence,
          false,
          cursor,
          highlightSegmentIndex,
          textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
          textStyle,
          textStyleIncursor,
          textStyle,
          textStyleIncursor,
        );

        if (snippet.annotations.isNotEmpty) {
          annotationRowWidgets += sentenceLineWidgets(
            currentSegmentPartSentence,
            true,
            cursor,
            -1,
            textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
            annotationDummyTextStyle,
            annotationDummyTextStyle,
            annotationDummyTextStyle,
            annotationDummyTextStyle,
          );
        }

        segmentCharLength = currentSegmentPartSentence.map((segment) => segment.word.length).reduce((a, b) => a + b);
      } else {
        List<SentenceSegment> currentSegmentPartAnnotation = annotation.sentenceSegments;

        List<Widget> sentenceRow = sentenceLineWidgets(
          currentSegmentPartSentence,
          false,
          cursor,
          highlightSegmentIndex,
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

        if (snippet.annotations.isNotEmpty) {
          int annotationHighlightSegmentIndex = annotation.getSegmentIndexFromSeekPosition(musicPlayerService.seekPosition);
          List<Widget> annotationRow = sentenceLineWidgets(
            currentSegmentPartAnnotation,
            true,
            cursor,
            annotationHighlightSegmentIndex,
            textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
            annotationTextStyle,
            annotationTextStyleIncursor,
            annotationTextStyle,
            annotationTextStyleIncursor,
          );

          if (snippet.annotations.isNotEmpty) {
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
        }

        if (!cursor.isAnnotationSelection) {
          segmentCharLength = currentSegmentPartSentence.map((segment) => segment.word.length).reduce((a, b) => a + b);
        } else {
          segmentCharLength = currentSegmentPartAnnotation.map((segment) => segment.word.length).reduce((a, b) => a + b);
        }
      }

      if (index < rangeList.length - 1) {
        sentenceRowWidgets.add(
          Text(
            "\xa0${TextPaneProvider.annotationEdgeChar}\xa0",
            style: cursor.isSegmentSelectionMode == false && cursor.isAnnotationSelection == false && sentenceString.length == cursor.charPosition ? textStyleIncursor : textStyle,
          ),
        );
        annotationRowWidgets.add(
          Text(
            "\xa0${TextPaneProvider.annotationEdgeChar}\xa0",
            style: cursor.isSegmentSelectionMode == false && cursor.isAnnotationSelection == true && annotation != null && sentenceString.length == cursor.charPosition ? textStyleIncursor : textStyle,
          ),
        );
      }

      highlightSegmentIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
      if (!cursor.isAnnotationSelection) {
        cursor.annotationSegmentRange.startIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
        cursor.annotationSegmentRange.endIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
        cursorPositionInfo.index -= segmentCharLength;
        cursor.charPosition -= segmentCharLength;
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
    bool isAnnotationLine,
    TextPaneCursor cursor,
    int highlightSegmentIndex,
    Color wordCursorColor,
    TextStyle wordTextStyle,
    TextStyle wordIncursorTextStyle,
    TextStyle timingPointTextStyle,
    TextStyle timingPointIncursorTextStyle,
  ) {
    List<Widget> widgets = [];
    int incursorSegmentIndex = 0;
    int incursorSegmentCharPosition = cursor.charPosition;
    for (int index = 0; index < segments.length; index++) {
      if (incursorSegmentCharPosition - segments[index].word.length >= 0) {
        incursorSegmentIndex++;
        incursorSegmentCharPosition -= segments[index].word.length;
      } else {
        break;
      }
    }

    for (int index = 0; index < segments.length; index++) {
      SentenceSegment currentSegment = segments[index];
      String segmentWord = currentSegment.word;
      if (cursor.isSegmentSelectionMode) {
        widgets.add(
          Text(
            segmentWord,
            style: cursor.isInRange(index) && cursor.isAnnotationSelection == isAnnotationLine ? wordIncursorTextStyle : wordTextStyle,
          ),
        );
      } else {
        const double cursorWidth = 1.0;
        const double cursorHeight = 15.0;
        double cursorCoordinate = calculateCursorPosition(segmentWord, incursorSegmentCharPosition, wordTextStyle);

        widgets.add(
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                segmentWord,
                style: index == highlightSegmentIndex && cursor.isAnnotationSelection == isAnnotationLine
                    ? wordTextStyle.copyWith(
                        decoration: TextDecoration.underline,
                      )
                    : wordTextStyle,
              ),
              index == highlightSegmentIndex && 0 < incursorSegmentCharPosition && incursorSegmentCharPosition < segmentWord.length && cursor.isAnnotationSelection == isAnnotationLine
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
            style:cursor.isSegmentSelectionMode == false && cursor.isAnnotationSelection == isAnnotationLine && index == incursorSegmentIndex - 1 && incursorSegmentCharPosition == 0 ? timingPointIncursorTextStyle : timingPointTextStyle,
          ),
        );
      }
    }

    return widgets;
  }

  int getIncursorSegmentIndex(List<SentenceSegment> sentneceSegments, TextPaneCursor cursor) {
    int index = 0;
    int charPosition = cursor.charPosition;
    while (charPosition - sentneceSegments[index].word.length > 0) {
      charPosition -= sentneceSegments[index].word.length;
      index++;
    }
    return index;
  }

  int getIncursorCharPosition(List<SentenceSegment> sentneceSegments, TextPaneCursor cursor) {
    int index = 0;
    int charPosition = cursor.charPosition;
    while (charPosition - sentneceSegments[index].word.length > 0) {
      charPosition -= sentneceSegments[index].word.length;
      index++;
    }
    return charPosition;
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
  SnippetID snippetID;
  int charPosition;
  Option option;

  bool isSegmentSelectionMode;
  bool isRangeSelection;

  bool isAnnotationSelection;
  SegmentRange annotationSegmentRange;

  void enterSegmentSelectionMode() {
    isSegmentSelectionMode = true;
    annotationSegmentRange.startIndex = 0;
    annotationSegmentRange.endIndex = 0;
  }

  void exitSegmentSelectionMode() {
    isSegmentSelectionMode = false;
    annotationSegmentRange.startIndex = 0;
    annotationSegmentRange.endIndex = 0;
  }

  bool isInRange(int index) {
    if (annotationSegmentRange.startIndex <= annotationSegmentRange.endIndex) {
      return annotationSegmentRange.startIndex <= index && index <= annotationSegmentRange.endIndex;
    } else {
      return annotationSegmentRange.endIndex <= index && index <= annotationSegmentRange.startIndex;
    }
  }

  TextPaneCursor(
    this.snippetID,
    this.charPosition,
    this.option,
    this.isSegmentSelectionMode,
    this.isRangeSelection,
    this.isAnnotationSelection,
    this.annotationSegmentRange,
  );

  TextPaneCursor copyWith({
    SnippetID? snippetID,
    int? charPosition,
    Option? option,
    bool? isSegmentSelectionMode,
    bool? isRangeSelection,
    bool? isAnnotationSelection,
    SegmentRange? annotationSegmentRange,
  }) {
    return TextPaneCursor(
      snippetID ?? this.snippetID,
      charPosition ?? this.charPosition,
      option ?? this.option,
      isSegmentSelectionMode ?? this.isSegmentSelectionMode,
      isRangeSelection ?? this.isRangeSelection,
      isAnnotationSelection ?? this.isAnnotationSelection,
      annotationSegmentRange ?? this.annotationSegmentRange.copyWith(),
    );
  }

  @override
  String toString() {
    if (!isAnnotationSelection) {
      if (!isSegmentSelectionMode) {
        return "SnippetSelection-> snippetID: ${snippetID}, charPosition: ${charPosition}, option: ${option}";
      } else {
        return "SegmentSelection-> snippetID: ${snippetID}, segment range: ${annotationSegmentRange}";
      }
    } else {
      return "AnnotationSelection-> snippetID: ${snippetID}, annotationRange: ${annotationSegmentRange}, charPosition: ${charPosition}, option: ${option}";
    }
  }

  static TextPaneCursor get emptyValue {
    return TextPaneCursor(
      SnippetID(0),
      0,
      Option.former,
      false,
      false,
      false,
      SegmentRange(-1, -1),
    );
  }
}
