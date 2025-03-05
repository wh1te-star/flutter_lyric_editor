import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/lyric_snippet/annotation/annotation.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';
import 'package:lyric_editor/pane/text_pane/cursor/sentence_selection_cursor.dart';
import 'package:lyric_editor/pane/text_pane/cursor/text_pane_cursor.dart';
import 'package:lyric_editor/pane/text_pane/edit_column.dart';
import 'package:lyric_editor/pane/text_pane/text_pane_provider.dart';
import 'package:lyric_editor/position/position_type_info.dart';
import 'package:lyric_editor/position/segment_range.dart';
import 'package:lyric_editor/lyric_snippet/sentence_segment/sentence_segment.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/sorted_list.dart';
import 'package:lyric_editor/utility/utility_functions.dart';
import 'package:tuple/tuple.dart';

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
    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);
    final TextPaneProvider textPaneProvider = ref.read(textPaneMasterProvider);
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
          child: EditColumn(timingService.getSnippetsAtSeekPosition(), musicPlayerService.seekPosition, textPaneProvider.textPaneCursorMover),
        ),
      ),
    );
  }

  /*
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
              color: id == textPaneProvider.cursor.lyricSnippetID ? Colors.yellowAccent : null,
              child: LyricSnippetEdit(id, snippet),
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
  */
}
