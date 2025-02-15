import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/pane/text_pane/text_pane_cursor.dart';
import 'package:lyric_editor/position/position_type_info.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/lyric_snippet/timing.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:lyric_editor/utility/sorted_list.dart';
import 'package:lyric_editor/utility/utility_functions.dart';
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

  static const String timingPointChar = '🕛';
  static const String annotationEdgeChar = '🔷';

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
    Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;
    if (currentSnippets.isEmpty) {
      return;
    }

    if (!currentSnippets.keys.toList().contains(cursor.snippetID)) {
      cursor.snippetID = currentSnippets.keys.first;
    }

    LyricSnippet snippet = currentSnippets.values.first;
    int currentSnippetPosition = snippet.timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    PositionTypeInfo nextSnippetPosition = snippet.timing.getPositionTypeInfo(cursor.charPosition.position);
    if (currentSnippetPosition != nextSnippetPosition.index) {
      cursor = getDefaultCursor(cursor.snippetID);
      cursorBlinker.restartCursorTimer();
    }
  }

  void updateCursorIfNeedByItemDeletion() {
    Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;
    if (currentSnippets.isEmpty) {
      return;
    }

    LyricSnippet? snippet = timingService.lyricSnippetMap[cursor.snippetID];
    if (snippet == null) {
      cursor = getDefaultCursor(LyricSnippetID(1));
      return;
    }

    if (!cursor.isAnnotationSelection) {
      return;
    }

    Annotation? annotation = snippet.annotationMap.map[cursor.annotationSegmentRange];
    if (annotation == null) {
      cursor = getDefaultCursor(cursor.snippetID);
      return;
    }
  }

  TextPaneCursor getDefaultCursor(LyricSnippetID id) {
    TextPaneCursor defaultCursor = TextPaneCursor.emptyValue;
    defaultCursor.isAnnotationSelection = false;

    LyricSnippet snippet = timingService.getLyricSnippetByID(id);
    int currentSnippetPosition = snippet.timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    defaultCursor.snippetID = id;
    defaultCursor.charPosition = snippet.timingPoints[currentSnippetPosition].charPosition + 1;
    defaultCursor.option = Option.former;

    return defaultCursor;
  }

  TextPaneCursor getDefaultCursorOfAnnotation(LyricSnippetID id) {
    TextPaneCursor defaultCursor = TextPaneCursor.emptyValue;

    defaultCursor.isAnnotationSelection = true;

    LyricSnippet snippet = timingService.getLyricSnippetByID(id);
    int? annotationIndex = snippet.getAnnotationIndexFromSeekPosition(musicPlayerProvider.seekPosition);
    MapEntry<SegmentRange, Annotation>? cursorAnnotationEntry = snippet.getAnnotationWords(annotationIndex!);
    SegmentRange range = cursorAnnotationEntry.key;
    Annotation annotation = cursorAnnotationEntry.value;

    int index = annotation.timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);

    defaultCursor.snippetID = id;
    defaultCursor.annotationSegmentRange = range;
    defaultCursor.charPosition = annotation.timingPoints[index].charPosition + 1;
    defaultCursor.option = Option.former;

    return defaultCursor;
  }

  int countOccurrences(List<int> list, int number) {
    return list.where((element) => element == number).length;
  }

  void moveUpCursor() {
    if (!cursor.isSegmentSelectionMode) {
      Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;
      LyricSnippet cursorSnippet = timingService.lyricSnippetMap[cursor.snippetID]!;

      int? annotationIndex = cursorSnippet.getAnnotationIndexFromSeekPosition(musicPlayerProvider.seekPosition);

      if (cursor.isAnnotationSelection || annotationIndex == null) {
        int index = currentSnippets.keys.toList().indexWhere((id) => id == cursor.snippetID);
        if (index > 0) {
          LyricSnippetID nextSnippetID = currentSnippets.keys.toList()[index - 1];
          cursor = getDefaultCursor(nextSnippetID);
        }
      } else {
        cursor = getDefaultCursorOfAnnotation(cursor.snippetID);
      }
    }

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveDownCursor() {
    if (!cursor.isSegmentSelectionMode) {
      if (cursor.isAnnotationSelection) {
        cursor = getDefaultCursor(cursor.snippetID);
      } else {
        Map<LyricSnippetID, LyricSnippet> currentSnippets = timingService.getSnippetsAtSeekPosition().map;

        int index = currentSnippets.keys.toList().indexWhere((id) => id == cursor.snippetID);
        if (index != -1 && index + 1 < currentSnippets.length) {
          LyricSnippetID nextSnippetID = currentSnippets.keys.toList()[index + 1];
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

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveLeftCursor() {
    if (!timingService.lyricSnippetMap.containsKey(cursor.snippetID)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetMap[cursor.snippetID]!;

    if (!cursor.isSegmentSelectionMode) {
      Timing object = !cursor.isAnnotationSelection ? snippet.timing : snippet.annotationMap.map[cursor.annotationSegmentRange]!.timing;
      PositionTypeInfo snippetPositionInfo = object.getPositionTypeInfo(cursor.charPosition.position);
      int seekPositionInfo = object.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
      int charPositionIndex = snippetPositionInfo.index;
      if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
        charPositionIndex++;
      }

      if (snippetPositionInfo.duplicate && cursor.option == Option.latter) {
        cursor.option = Option.former;
      } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo + 1) {
        if (cursor.charPosition.position - 1 > 0) {
          cursor.charPosition--;

          if (object.getPositionTypeInfo(cursor.charPosition.position).duplicate) {
            cursor.option = Option.latter;
          } else {
            cursor.option = Option.former;
          }
        }
      } else {
        if (object.timingPoints[charPositionIndex - 1].charPosition.position > 0) {
          cursor.charPosition = object.timingPoints[charPositionIndex - 1].charPosition;

          if (object.getPositionTypeInfo(cursor.charPosition.position).duplicate) {
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
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex--;
          }
          cursor.annotationSegmentRange.startIndex = nextSegmentIndex;
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.annotationSegmentRange.endIndex - 1;
        if (nextSegmentIndex >= cursor.annotationSegmentRange.startIndex) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex--;
          }
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      }
    }

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }

  void moveRightCursor() {
    if (!timingService.lyricSnippetMap.containsKey(cursor.snippetID)) {
      return;
    }
    LyricSnippet snippet = timingService.lyricSnippetMap[cursor.snippetID]!;

    if (!cursor.isSegmentSelectionMode) {
      Timing timing = !cursor.isAnnotationSelection ? snippet.timing : snippet.annotationMap.map[cursor.annotationSegmentRange]!.timing;
      PositionTypeInfo snippetPositionInfo = timing.getPositionTypeInfo(cursor.charPosition.position);
      int seekPositionInfo = timing.getSegmentIndexFromSeekPosition(musicPlayerProvider.seekPosition);
      int charPositionIndex = snippetPositionInfo.index;
      if (cursor.option == Option.latter && snippetPositionInfo.duplicate) {
        charPositionIndex++;
      }

      if (snippetPositionInfo.duplicate && cursor.option == Option.former) {
        cursor.option = Option.latter;
      } else if (snippetPositionInfo.type == PositionType.sentenceSegment || charPositionIndex == seekPositionInfo) {
        if (cursor.charPosition.position + 1 < timing.sentence.length) {
          cursor.charPosition++;
          cursor.option = Option.former;
        }
      } else {
        if (timing.timingPoints[charPositionIndex + 1].charPosition.position < timing.sentence.length) {
          cursor.charPosition = timing.timingPoints[charPositionIndex + 1].charPosition;
          cursor.option = Option.former;
        }
      }
    } else {
      if (!cursor.isRangeSelection) {
        int nextSegmentIndex = cursor.annotationSegmentRange.startIndex + 1;
        if (nextSegmentIndex <= snippet.sentenceSegments.length) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex++;
          }
          cursor.annotationSegmentRange.startIndex = nextSegmentIndex;
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      } else {
        int nextSegmentIndex = cursor.annotationSegmentRange.endIndex + 1;
        if (nextSegmentIndex < snippet.sentenceSegments.length) {
          if (snippet.sentenceSegments[nextSegmentIndex].word.isEmpty) {
            nextSegmentIndex++;
          }
          cursor.annotationSegmentRange.endIndex = nextSegmentIndex;
        }
      }
    }

    debugPrint("$cursor");
    cursorBlinker.restartCursorTimer();
    notifyListeners();
  }
}

class TextPane extends ConsumerStatefulWidget {
  final FocusNode focusNode;

  const TextPane({required this.focusNode}) : super(key: const Key('TextPane'));

  @override
  _TextPaneState createState() => _TextPaneState(focusNode);
}

class _TextPaneState extends ConsumerState<TextPane> {
  final FocusNode focusNode;

  static const String cursorChar = '\xa0';
  //static const String sectionChar = '\n\n';

  double lineHeight = 20;

  List<LyricSnippetID> selectingSnippets = [];

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
    TextStyle style = const TextStyle(letterSpacing: 2.0);

    double singleRowHeight = getSizeFromTextStyle("dummy text", style).height;

    for (MapEntry<LyricSnippetID, LyricSnippet> entry in currentSnippets.entries) {
      LyricSnippet snippet = entry.value;
      String timingPointString = TextPaneProvider.timingPointChar * (snippet.timingPoints.length - 2);
      double sentenceWidth = getSizeFromTextStyle(snippet.sentence + timingPointString, style).width + 10.0;
      if (sentenceWidth > maxWidth) {
        maxWidth = sentenceWidth;
      }
    }
    double sideBandWidth = 30.0;
    for (MapEntry<LyricSnippetID, LyricSnippet> entry in currentSnippets.entries) {
      LyricSnippetID id = entry.key;
      LyricSnippet snippet = entry.value;
      Color vocalistColor = Color(timingService.vocalistColorMap[snippet.vocalistID]!.color);

      double rowHeight = snippet.annotationMap.isEmpty ? singleRowHeight : 2 * singleRowHeight;
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

  Widget snippetEditLine(LyricSnippetID id, LyricSnippet snippet) {
    MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    TimingService timingService = ref.read(timingMasterProvider);
    TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
    PositionTypeInfo cursorPositionInfo = snippet.timing.getPositionTypeInfo(textPaneProvider.cursor.charPosition.position);

    TextStyle textStyle = const TextStyle(
      color: Colors.black,
    );
    TextStyle textStyleIncursor = TextStyle(
      color: textPaneProvider.cursorBlinker.isCursorVisible ? Colors.white : Colors.black,
      background: textPaneProvider.cursorBlinker.isCursorVisible ? (Paint()..color = Colors.black) : null,
    );
    TextStyle annotationTextStyle = const TextStyle(
      color: Colors.black,
    );
    TextStyle annotationDummyTextStyle = const TextStyle(
      color: Colors.transparent,
    );
    TextStyle annotationTextStyleIncursor = TextStyle(
      color: Colors.white,
      background: Paint()..color = Colors.black,
    );
    List<Widget> sentenceRowWidgets = [];
    List<Widget> annotationRowWidgets = [];
    List<Tuple2<SegmentRange, Annotation?>> rangeList = getRangeListForAnnotations(snippet.annotationMap.map, snippet.sentenceSegments.length);
    int highlightSegmentIndex = snippet.timing.getSegmentIndexFromSeekPosition(musicPlayerService.seekPosition);

    TextPaneCursor cursor = textPaneProvider.cursor.copyWith();

    for (int index = 0; index < rangeList.length; index++) {
      Tuple2<SegmentRange, Annotation?> element = rangeList[index];
      SegmentRange segmentRange = element.item1;
      Annotation? annotation = element.item2;

      if (segmentRange.isEmpty) {
        continue;
      }

      List<SentenceSegment> currentSegmentPartSentence = snippet.sentenceSegments.sublist(segmentRange.startIndex, segmentRange.endIndex + 1);
      String sentenceString = currentSegmentPartSentence.map((SentenceSegment segment) => segment.word).join('');
      String sentenceTimingPointString = "\xa0${TextPaneProvider.timingPointChar}\xa0" * (segmentRange.endIndex - segmentRange.startIndex);
      double sentenceRowWidth = getSizeFromTextStyle(sentenceString, textStyle).width + getSizeFromTextStyle(sentenceTimingPointString, textStyle).width + 10;
      int segmentCharLength = 0;

      if (annotation == null) {
        sentenceRowWidgets += sentenceLineWidgets(
          currentSegmentPartSentence,
          false,
          !cursor.isAnnotationSelection ? cursor : TextPaneCursor.emptyValue,
          highlightSegmentIndex,
          textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
          textStyle,
          textStyleIncursor,
          textStyle,
          textStyleIncursor,
        );

        if (!snippet.annotationMap.isEmpty) {
          annotationRowWidgets += sentenceLineWidgets(
            currentSegmentPartSentence,
            true,
            cursor.isAnnotationSelection ? cursor : TextPaneCursor.emptyValue,
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
        String annotationString = currentSegmentPartAnnotation.map((SentenceSegment segment) => segment.word).join('');
        String annotationTimingPointString = "\xa0${TextPaneProvider.timingPointChar}\xa0" * (annotation.sentenceSegments.length - 1);
        double annotationRowWidth = getSizeFromTextStyle(annotationString, annotationTextStyle).width + getSizeFromTextStyle(annotationTimingPointString, annotationTextStyle).width + 10;

        double rowWidth = sentenceRowWidth > annotationRowWidth ? sentenceRowWidth : annotationRowWidth;

        List<Widget> sentenceRow = sentenceLineWidgets(
          currentSegmentPartSentence,
          false,
          !cursor.isAnnotationSelection ? cursor : TextPaneCursor.emptyValue,
          highlightSegmentIndex,
          textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
          textStyle,
          textStyleIncursor,
          textStyle,
          textStyleIncursor,
        );

        sentenceRowWidgets += [
          SizedBox(
            width: rowWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: sentenceRow,
            ),
          ),
        ];

        if (!snippet.annotationMap.isEmpty) {
          int annotationHighlightSegmentIndex = textPaneProvider.cursor.annotationSegmentRange == segmentRange ? annotation.timing.getSegmentIndexFromSeekPosition(musicPlayerService.seekPosition) : -1;
          List<Widget> annotationRow = sentenceLineWidgets(
            currentSegmentPartAnnotation,
            true,
            cursor.isAnnotationSelection ? cursor : TextPaneCursor.emptyValue,
            annotationHighlightSegmentIndex,
            textPaneProvider.cursorBlinker.isCursorVisible ? Colors.black : Colors.transparent,
            annotationTextStyle,
            annotationTextStyleIncursor,
            annotationTextStyle,
            annotationTextStyleIncursor,
          );

          if (!snippet.annotationMap.isEmpty) {
            annotationRowWidgets += [
              SizedBox(
                width: rowWidth,
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
            style: textStyle,
          ),
        );
      }

      highlightSegmentIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
      if (!cursor.isAnnotationSelection) {
        cursorPositionInfo.index -= segmentCharLength;
        cursor.charPosition -= segmentCharLength;
        cursor.annotationSegmentRange.startIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
        cursor.annotationSegmentRange.endIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
      } else {
        cursor.annotationSegmentRange.startIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
        cursor.annotationSegmentRange.endIndex -= segmentRange.endIndex - segmentRange.startIndex + 1;
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
    int incursorSegmentCharPosition = cursor.charPosition.position;
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
            style: cursor.isSegmentSelectionMode == false && cursor.isAnnotationSelection == isAnnotationLine && index == incursorSegmentIndex - 1 && incursorSegmentCharPosition == 0 ? timingPointIncursorTextStyle : timingPointTextStyle,
          ),
        );
      }
    }

    return widgets;
  }

  int getIncursorSegmentIndex(List<SentenceSegment> sentneceSegments, TextPaneCursor cursor) {
    int index = 0;
    int charPosition = cursor.charPosition.position;
    while (charPosition - sentneceSegments[index].word.length > 0) {
      charPosition -= sentneceSegments[index].word.length;
      index++;
    }
    return index;
  }

  int getIncursorCharPosition(List<SentenceSegment> sentneceSegments, TextPaneCursor cursor) {
    int index = 0;
    int charPosition = cursor.charPosition.position;
    while (charPosition - sentneceSegments[index].word.length > 0) {
      charPosition -= sentneceSegments[index].word.length;
      index++;
    }
    return charPosition;
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
