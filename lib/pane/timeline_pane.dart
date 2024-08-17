import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:lyric_editor/painter/current_position_indicator_painter.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
import 'package:lyric_editor/painter/scale_mark.dart';
import 'package:lyric_editor/painter/timeline_painter.dart';
import 'package:lyric_editor/utility/color_utilities.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:lyric_editor/utility/svg_icon.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:rxdart/rxdart.dart';

class TimelinePane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  TimelinePane({required this.masterSubject, required this.focusNode}) : super(key: Key('TimelinePane'));

  @override
  _TimelinePaneState createState() => _TimelinePaneState(masterSubject, focusNode);
}

class _TimelinePaneState extends State<TimelinePane> {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;
  _TimelinePaneState(this.masterSubject, this.focusNode);

  ScrollController verticalScrollController = ScrollController();
  LinkedScrollControllerGroup horizontalScrollController = LinkedScrollControllerGroup();
  late ScrollController scaleMarkScrollController;
  late List<ScrollController> snippetTimelineScrollController = [];
  late ScrollController seekPositionScrollController;
  List<Offset> panDeltas = [];
  List<DateTime> panTimestamps = [];

  Map<String, List<LyricSnippet>> snippetsForeachVocalist = {};
  Map<String, int> vocalistColorList = {};
  Map<String, List<String>> vocalistCombinationCorrespondence = {};
  List<int> sections = [];
  LyricSnippetID cursorPosition = LyricSnippetID(Vocalist("", 0), 0);
  List<LyricSnippetID> selectingSnippet = [];
  List<String> selectingVocalist = [];
  int audioDuration = 60000;
  int currentPosition = 0;
  double intervalLength = 10.0;
  double majorMarkLength = 15.0;
  double midiumMarkLength = 11.0;
  double minorMarkLength = 8.0;
  int intervalDuration = 1000;
  bool autoCurrentSelectMode = true;
  int edittingVocalistIndex = -1;
  String oldVocalistValue = "";
  late FocusNode textFieldFocusNode;
  bool isAddVocalistButtonSelected = false;
  String isAddVocalistInput = "";

  late CursorBlinker cursorBlinker;

  @override
  void initState() {
    super.initState();
    textFieldFocusNode = FocusNode();
    textFieldFocusNode.addListener(_onFocusChange);

    scaleMarkScrollController = horizontalScrollController.addAndGet();
    seekPositionScrollController = horizontalScrollController.addAndGet();

    masterSubject.stream.listen((signal) {
      if (signal is NotifyAudioFileLoaded) {
        setState(() {
          audioDuration = signal.millisec;
        });
      }
      if (signal is NotifySeekPosition) {
        List<LyricSnippetID> currentSelectingSnippet = getSnippetsAtCurrentSeekPosition();
        masterSubject.add(NotifyCurrentSnippets(currentSelectingSnippet));

        if (autoCurrentSelectMode) {
          selectingSnippet = currentSelectingSnippet;
          masterSubject.add(NotifySelectingSnippets(selectingSnippet));
        }
        setState(() {
          currentPosition = signal.seekPosition;
        });
      }
      if (signal is NotifySnippetMove || signal is NotifySnippetDivided || signal is NotifySnippetConcatenated || signal is NotifyUndo) {
        snippetsForeachVocalist = groupBy(signal.lyricSnippetList, (LyricSnippet snippet) => snippet.vocalist.name);
        setState(() {});
      }
      if (signal is NotifyLyricParsed || signal is NotifyVocalistAdded || signal is NotifyVocalistDeleted || signal is NotifyVocalistNameChanged) {
        snippetsForeachVocalist = groupBy(signal.lyricSnippetList, (LyricSnippet snippet) => snippet.vocalist.name);
        cursorPosition = snippetsForeachVocalist[snippetsForeachVocalist.keys.first]![0].id;
        vocalistColorList = signal.vocalistColorList;
        vocalistCombinationCorrespondence = signal.vocalistCombinationCorrespondence;

        snippetTimelineScrollController.forEach((ScrollController controller) {
          controller.dispose();
        });
        snippetTimelineScrollController.clear();
        for (int i = 0; i < vocalistColorList.length; i++) {
          snippetTimelineScrollController.add(horizontalScrollController.addAndGet());
        }

        setState(() {});
      }
      if (signal is NotifySectionAdded || signal is NotifySectionDeleted) {
        sections = List.from(signal.sections);
        setState(() {});
      }
      if (signal is RequestTimelineZoomIn) {
        zoomIn();
        setState(() {});
      }
      if (signal is RequestTimelineZoomOut) {
        zoomOut();
        setState(() {});
      }
      if (signal is RequestTimelineCursorMoveLeft) {
        moveLeftCursor();
        setState(() {});
      }
      if (signal is RequestTimelineCursorMoveRight) {
        moveRightCursor();
        setState(() {});
      }
      if (signal is RequestTimelineCursorMoveUp) {
        moveUpCursor();
        setState(() {});
      }
      if (signal is RequestTimelineCursorMoveDown) {
        moveDownCursor();
        setState(() {});
      }
    });
    //horizontalDetails.controller!.addListener(_onHorizontalScroll);

    cursorBlinker = CursorBlinker(
        blinkIntervalInMillisec: 1000,
        onTick: () {
          setState(() {});
        });
  }

  void zoomIn() {
    intervalDuration = intervalDuration * 2;
  }

  void zoomOut() {
    intervalDuration = intervalDuration ~/ 2;
  }

  LyricSnippet getSnippetWithID(LyricSnippetID id) {
    return snippetsForeachVocalist[id.vocalist.name]!.firstWhere((snippet) => snippet.id == id);
  }

  int getSnippetIndexWithID(LyricSnippetID id) {
    return snippetsForeachVocalist[id.vocalist.name]!.indexWhere((snippet) => snippet.id == id);
  }

  LyricSnippet getNearSnippetFromSeekPosition(String vocalistName, int targetSeekPosition) {
    List<LyricSnippet> snippets = snippetsForeachVocalist[vocalistName]!;
    for (int index = 0; index < snippets.length; index++) {
      int snippetStart = snippets[index].startTimestamp;
      int snippetEnd = snippets[index].endTimestamp;
      if (targetSeekPosition < snippetStart) {
        if (index == 0) {
          return snippets[0];
        }
        int leftDistance = targetSeekPosition - snippetEnd;
        int rightDistance = snippetStart - targetSeekPosition;
        if (leftDistance < rightDistance) {
          return snippets[index - 1];
        } else {
          return snippets[index];
        }
      }
      if (snippetStart < targetSeekPosition && targetSeekPosition < snippetEnd) {
        return snippets[index];
      }
    }
    return snippets.last;
  }

  String? getNextVocalist(String currentVocalist) {
    List<String> vocalists = snippetsForeachVocalist.keys.toList();
    int currentIndex = vocalists.indexOf(currentVocalist);
    if (currentIndex != -1 && currentIndex < vocalists.length - 1) {
      return vocalists[currentIndex + 1];
    }
    return null;
  }

  String? getPreviousVocalist(String currentVocalist) {
    List<String> vocalists = snippetsForeachVocalist.keys.toList();
    int currentIndex = vocalists.indexOf(currentVocalist);
    if (currentIndex > 0) {
      return vocalists[currentIndex - 1];
    }
    return null;
  }

  void moveLeftCursor() {
    LyricSnippetID nextCursorPosition = cursorPosition;
    nextCursorPosition.index--;
    if (nextCursorPosition.index >= 0) {
      nextCursorPosition = getSnippetWithID(nextCursorPosition).id;
      cursorPosition = nextCursorPosition;
      cursorBlinker.restartCursorTimer();
    }
  }

  void moveRightCursor() {
    LyricSnippetID nextCursorPosition = cursorPosition;
    nextCursorPosition.index++;
    if (nextCursorPosition.index < snippetsForeachVocalist[cursorPosition.vocalist.name]!.length) {
      nextCursorPosition = getSnippetWithID(nextCursorPosition).id;
      cursorPosition = nextCursorPosition;
      cursorBlinker.restartCursorTimer();
    }
  }

  void moveUpCursor() {
    String upperVocalist = getPreviousVocalist(cursorPosition.vocalist.name)!;
    LyricSnippet snippet = getSnippetWithID(cursorPosition);
    int targetSeekPosition = (snippet.startTimestamp + snippet.endTimestamp) ~/ 2;
    cursorPosition = getNearSnippetFromSeekPosition(upperVocalist, targetSeekPosition).id;
  }

  void moveDownCursor() {
    String upperVocalist = getNextVocalist(cursorPosition.vocalist.name)!;
    LyricSnippet snippet = getSnippetWithID(cursorPosition);
    int targetSeekPosition = (snippet.startTimestamp + snippet.endTimestamp) ~/ 2;
    cursorPosition = getNearSnippetFromSeekPosition(upperVocalist, targetSeekPosition).id;
  }

  @override
  Widget build(BuildContext context) {
    final Widget borderLine = Container(
      width: 5,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.black,
            width: 5,
          ),
        ),
      ),
    );
    return Focus(
      focusNode: focusNode,
      child: Listener(
        onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
          debugPrint('trackpad scrolled ${event.panDelta}');

          double horizontalOffsetLimit = scaleMarkScrollController.position.maxScrollExtent;
          double verticalOffsetLimit = verticalScrollController.position.maxScrollExtent;

          panDeltas.add(event.panDelta);
          panTimestamps.add(DateTime.now());
          if (panDeltas.length > 5) {
            panDeltas.removeAt(0);
            panTimestamps.removeAt(0);
          }
          double nextHorizontalOffset = horizontalScrollController.offset - event.panDelta.dx;
          if (nextHorizontalOffset < 0) {
            nextHorizontalOffset = 0;
          } else if (nextHorizontalOffset > horizontalOffsetLimit) {
            nextHorizontalOffset = horizontalOffsetLimit;
          }
          horizontalScrollController.jumpTo(nextHorizontalOffset);

          double nextVerticalOffset = verticalScrollController.offset - event.panDelta.dy;
          if (nextVerticalOffset < 0) {
            nextVerticalOffset = 0;
          } else if (nextVerticalOffset > verticalOffsetLimit) {
            nextVerticalOffset = verticalOffsetLimit;
          }
          verticalScrollController.jumpTo(nextVerticalOffset);
        },
        onPointerPanZoomEnd: (PointerPanZoomEndEvent event) {
          double horizontalOffsetLimit = scaleMarkScrollController.position.maxScrollExtent;
          double verticalOffsetLimit = verticalScrollController.position.maxScrollExtent;
          debugPrint('trackpad pan ended');

          if (panDeltas.isNotEmpty && panTimestamps.isNotEmpty) {
            final int count = panDeltas.length;
            final Duration duration = panTimestamps.last.difference(panTimestamps.first);
            final Offset totalDelta = panDeltas.reduce((a, b) => a + b);

            final double velocityX = totalDelta.dx / duration.inMilliseconds * 1000;
            final double velocityY = totalDelta.dy / duration.inMilliseconds * 1000;

            double nextHorizontalOffset = horizontalScrollController.offset - velocityX * 0.1;
            if (nextHorizontalOffset < 0) {
              nextHorizontalOffset = 0;
            } else if (nextHorizontalOffset > horizontalOffsetLimit) {
              nextHorizontalOffset = horizontalOffsetLimit;
            }
            horizontalScrollController.animateTo(
              nextHorizontalOffset,
              duration: Duration(milliseconds: 500),
              curve: Curves.decelerate,
            );

            double nextVerticalOffset = verticalScrollController.offset - velocityY * 0.1;
            if (nextVerticalOffset < 0) {
              nextVerticalOffset = 0;
            } else if (nextVerticalOffset > verticalOffsetLimit) {
              nextVerticalOffset = verticalOffsetLimit;
            }
            verticalScrollController.animateTo(
              nextVerticalOffset,
              duration: Duration(milliseconds: 500),
              curve: Curves.decelerate,
            );
          }

          panDeltas.clear();
          panTimestamps.clear();
        },
        child: Stack(
          children: [
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 155,
                      height: 30,
                      child: cellFunctionButton(),
                    ),
                    borderLine,
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scaleMarkScrollController,
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width: audioDuration * intervalLength / intervalDuration,
                          height: 30,
                          child: cellScaleMark(),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ReorderableListView(
                    buildDefaultDragHandles: false,
                    scrollController: verticalScrollController,
                    onReorder: onReorder,
                    children: List.generate(vocalistColorList.length + 1, (index) {
                      return itemBuilder(context, index);
                    }),
                  ),
                ),
              ],
            ),
            IgnorePointer(
              ignoring: true,
              child: Padding(
                padding: const EdgeInsets.only(left: 160.0),
                child: SingleChildScrollView(
                  controller: seekPositionScrollController,
                  scrollDirection: Axis.horizontal,
                  child: CustomPaint(
                    size: Size(audioDuration * intervalLength / intervalDuration, 800),
                    painter: CurrentPositionIndicatorPainter(intervalLength, intervalDuration, currentPosition, sections),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget itemBuilder(BuildContext context, int index) {
    if (index < vocalistColorList.length) {
      final int lanes = getLanes(snippetsForeachVocalist.values.toList()[index]);
      final double rowHeight = 60.0 * lanes;
      final Widget borderLine = Container(
        width: 5,
        height: rowHeight,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.black,
              width: 5,
            ),
          ),
        ),
      );

      final String vocalistName = snippetsForeachVocalist.keys.toList()[index];
      final Color vocalistColor = Color(vocalistColorList[vocalistName]!);
      final Color backgroundColor = adjustColorBrightness(vocalistColor, 0.3);

      return Container(
        key: ValueKey('VocalistPanel_${index}'),
        height: rowHeight,
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: SvgIcon(
                assetName: 'assets/drag_handle.svg',
                iconColor: determineBlackOrWhite(backgroundColor),
                backgroundColor: vocalistColor,
                width: 20,
                height: rowHeight,
              ),
            ),
            Container(
              width: 135,
              height: rowHeight,
              child: Container(alignment: Alignment.topLeft, child: cellVocalistPanel(index)),
            ),
            borderLine,
            Expanded(
              child: SingleChildScrollView(
                controller: snippetTimelineScrollController[index],
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: audioDuration * intervalLength / intervalDuration,
                  height: rowHeight,
                  child: cellSnippetTimeline(index),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final Widget borderLine = Container(
        width: 5,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.black,
              width: 5,
            ),
          ),
        ),
      );
      return Row(
        key: ValueKey('AddVocalistButton'),
        children: [
          Container(
            width: 155,
            height: 40,
            child: cellAddVocalistButton(),
          ),
          borderLine,
          Expanded(child: cellAddVocalistButtonNeighbor()),
        ],
      );
    }
  }

  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > vocalistColorList.length) newIndex = vocalistColorList.length;
      if (oldIndex < vocalistColorList.length && newIndex <= vocalistColorList.length) {
        final item = vocalistColorList.remove("abc");
        //vocalistColorList.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
      }
    });
  }

  @override
  void dispose() {
    scaleMarkScrollController.dispose();
    snippetTimelineScrollController.forEach((ScrollController controller) {
      controller.dispose();
    });
    seekPositionScrollController.dispose();
    super.dispose();
  }

  List<LyricSnippetID> getSnippetsAtCurrentSeekPosition() {
    List<LyricSnippetID> currentSnippet = [];
    snippetsForeachVocalist.forEach((vocalist, snippets) {
      for (var snippet in snippets) {
        final endtime = snippet.startTimestamp + snippet.sentenceSegments.map((point) => point.wordDuration).reduce((a, b) => a + b);
        if (snippet.startTimestamp <= currentPosition && currentPosition <= endtime) {
          currentSnippet.add(snippet.id);
        }
      }
    });
    return currentSnippet;
  }

  Color blendColors(Color color1, Color color2) {
    int alpha = ((color1.alpha + color2.alpha) / 2).round();
    int red = ((color1.red + color2.red) / 2).round();
    int green = ((color1.green + color2.green) / 2).round();
    int blue = ((color1.blue + color2.blue) / 2).round();

    return Color.fromARGB(alpha, red, green, blue);
  }

  int getLanes(List<LyricSnippet> lyricSnippetList) {
    if (lyricSnippetList.isEmpty) return 1;
    lyricSnippetList.sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));

    int maxOverlap = 1;
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
    }

    return maxOverlap;
  }

  Widget cellFunctionButton() {
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        autoCurrentSelectMode = !autoCurrentSelectMode;
        setState(() {});
      },
      child: CustomPaint(
        painter: RectanglePainter(
          rect: Rect.fromLTRB(0.0, 0.0, 155, 30),
          sentence: "Auto Select Mode",
          color: Colors.purpleAccent,
          isSelected: autoCurrentSelectMode,
          borderLineWidth: 1.0,
        ),
      ),
    );
  }

  Widget cellScaleMark() {
    return CustomPaint(
      painter: ScaleMark(intervalLength: intervalLength, majorMarkLength: majorMarkLength, midiumMarkLength: midiumMarkLength, minorMarkLength: minorMarkLength, intervalDuration: intervalDuration),
    );
  }

  Widget cellVocalistPanel(int index) {
    final String vocalistName = snippetsForeachVocalist.entries.toList()[index].key;
    if (edittingVocalistIndex == index) {
      final TextEditingController controller = TextEditingController(text: vocalistName);
      oldVocalistValue = vocalistName;
      return TextField(
        controller: controller,
        focusNode: textFieldFocusNode,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          edittingVocalistIndex = -1;
          if (value == "") {
            masterSubject.add(RequestDeleteVocalist(oldVocalistValue));
          } else if (oldVocalistValue != value) {
            cursorBlinker.restartCursorTimer();
            masterSubject.add(RequestChangeVocalistName(oldVocalistValue, value));
          }
          setState(() {});
        },
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (TapDownDetails details) {
              if (selectingVocalist.contains(vocalistName)) {
                selectingVocalist.remove(vocalistName);
                masterSubject.add(NotifyDeselectingVocalist(vocalistName));
              } else {
                selectingVocalist.add(vocalistName);
                masterSubject.add(NotifySelectingVocalist(vocalistName));
              }
              setState(() {});
            },
            onDoubleTap: () {
              edittingVocalistIndex = index;
              debugPrint("${index}");
              textFieldFocusNode.requestFocus();
              cursorBlinker.pauseCursorTimer();
              masterSubject.add(RequestKeyboardShortcutEnable(false));
              setState(() {});
            },
            child: CustomPaint(
              size: Size(135, constraints.maxHeight),
              painter: RectanglePainter(
                rect: Rect.fromLTRB(0.0, 0.0, 135, constraints.maxHeight),
                sentence: snippetsForeachVocalist.entries.toList()[index].value[0].vocalist.name,
                color: Color(vocalistColorList[vocalistName]!),
                isSelected: selectingVocalist.contains(vocalistName),
                borderLineWidth: 1.0,
              ),
            ),
          );
        },
      );
    }
  }

  Widget cellSnippetTimeline(int index) {
    final String vocalistName = snippetsForeachVocalist.entries.toList()[index].key;
    double topMargin = 10;
    double bottomMargin = 5;
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        Offset localPosition = details.localPosition;
        final snippets = snippetsForeachVocalist.entries.toList()[index].value;
        for (var snippet in snippets) {
          final endtime = snippet.startTimestamp + snippet.sentenceSegments.map((point) => point.wordDuration).reduce((a, b) => a + b);
          final touchedSeekPosition = localPosition.dx * intervalDuration / intervalLength;
          if (snippet.startTimestamp <= touchedSeekPosition && touchedSeekPosition <= endtime) {
            if (selectingSnippet.contains(snippet.id)) {
              selectingSnippet.remove(snippet.id);
            } else {
              selectingSnippet.add(snippet.id);
            }
            masterSubject.add(NotifySelectingSnippets(selectingSnippet));
          }
        }
        setState(() {});
      },
      child: CustomPaint(
        painter: TimelinePainter(
          snippets: snippetsForeachVocalist.entries.toList()[index].value,
          selectingId: selectingSnippet,
          intervalLength: intervalLength,
          intervalDuration: intervalDuration,
          color: Color(vocalistColorList[vocalistName]!),
          frameThickness: 3.0,
          topMargin: topMargin,
          bottomMargin: bottomMargin,
          cursorPosition: cursorBlinker.isCursorVisible ? cursorPosition : null,
        ),
      ),
    );
  }

  Widget cellAddVocalistButton() {
    if (isAddVocalistInput != "") {
      final TextEditingController controller = TextEditingController(text: "");
      return TextField(
        controller: controller,
        focusNode: textFieldFocusNode,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          isAddVocalistInput = value;
        },
        onSubmitted: (value) {
          if (value != "") {
            masterSubject.add(RequestAddVocalist(value));
            debugPrint("RequestAddVocalist ${value}");
          }
          isAddVocalistInput = "";
          setState(() {});
        },
      );
    } else {
      return GestureDetector(
        onTapDown: (TapDownDetails details) {
          isAddVocalistButtonSelected = true;
          textFieldFocusNode.requestFocus();
          cursorBlinker.restartCursorTimer();
          masterSubject.add(RequestKeyboardShortcutEnable(false));
          setState(() {});
        },
        onTapUp: (TapUpDetails details) {
          isAddVocalistButtonSelected = false;
          isAddVocalistInput = "input";
          setState(() {});
        },
        child: CustomPaint(
          painter: RectanglePainter(
            rect: Rect.fromLTRB(0.0, 0.0, 155, 40),
            sentence: "+",
            color: Colors.grey,
            isSelected: isAddVocalistButtonSelected,
            borderLineWidth: 1.0,
          ),
        ),
      );
    }
  }

  Widget cellAddVocalistButtonNeighbor() {
    return const ColoredBox(
      color: Colors.blueGrey,
    );
  }

  void _onFocusChange() {
    if (!textFieldFocusNode.hasFocus) {
      edittingVocalistIndex = -1;
      isAddVocalistInput = "";
      cursorBlinker.restartCursorTimer();
      masterSubject.add(RequestKeyboardShortcutEnable(true));
      debugPrint("release the text field focus.");
      setState(() {});
    } else {
      debugPrint("enable the text field focus.");
    }
  }

  void _onHorizontalScroll() {
    /*
    if (horizontalDetails.controller!.hasClients) {
      currentPositionScroller.jumpTo(horizontalDetails.controller!.offset);
    }
*/
  }
}
