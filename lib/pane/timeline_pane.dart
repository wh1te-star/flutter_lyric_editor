import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:lyric_editor/painter/current_position_indicator_painter.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
import 'package:lyric_editor/painter/scale_mark.dart';
import 'package:lyric_editor/painter/timeline_painter.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/color_utilities.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:lyric_editor/utility/dialogbox_utility.dart';
import 'package:lyric_editor/utility/id_generator.dart';
import 'package:lyric_editor/utility/svg_icon.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

class TimelinePane extends ConsumerStatefulWidget {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  TimelinePane({required this.masterSubject, required this.focusNode}) : super(key: Key('TimelinePane'));

  @override
  _TimelinePaneState createState() => _TimelinePaneState(masterSubject, focusNode);
}

class _TimelinePaneState extends ConsumerState<TimelinePane> {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;
  _TimelinePaneState(this.masterSubject, this.focusNode);

  ScrollController verticalScrollController = ScrollController();
  LinkedScrollControllerGroup horizontalScrollController = LinkedScrollControllerGroup();
  late ScrollController scaleMarkScrollController;
  late ScrollController seekPositionScrollController;
  late Map<String, ScrollController> snippetTimelineScrollController;

  List<Offset> panDeltas = [];
  List<DateTime> panTimestamps = [];
  bool isDragging = false;

  Map<String, List<LyricSnippet>> snippetsForeachVocalist = {};
  SnippetID cursorPosition = SnippetID(0);
  List<SnippetID> selectingSnippet = [];
  List<String> selectingVocalist = [];
  double intervalLength = 10.0;
  double majorMarkLength = 15.0;
  double midiumMarkLength = 11.0;
  double minorMarkLength = 8.0;
  int intervalDuration = 1000;
  bool autoCurrentSelectMode = true;

  TextEditingController textFieldController = TextEditingController();
  FocusNode textFieldFocusNode = FocusNode();
  int edittingVocalistIndex = -1;
  String oldVocalistValue = "";
  bool isAddVocalistButtonSelected = false;
  String isAddVocalistInput = "";

  late CursorBlinker cursorBlinker;

  @override
  void initState() {
    super.initState();

    scaleMarkScrollController = horizontalScrollController.addAndGet();
    seekPositionScrollController = horizontalScrollController.addAndGet();
    snippetTimelineScrollController = {};

    final musicPlayerService = ref.read(musicPlayerMasterProvider);
    final timingService = ref.read(timingMasterProvider);

    musicPlayerService.addListener(() {
      List<SnippetID> currentSelectingSnippet = getSnippetsAtCurrentSeekPosition();
      masterSubject.add(NotifyCurrentSnippets(currentSelectingSnippet));

      if (autoCurrentSelectMode) {
        selectingSnippet = currentSelectingSnippet;
        masterSubject.add(NotifySelectingSnippets(selectingSnippet));
      }
      setState(() {});
    });

    timingService.addListener(() {
      final List<LyricSnippet> lyricSnippetList = timingService.lyricSnippetList;
      snippetsForeachVocalist = groupBy(lyricSnippetList, (LyricSnippet snippet) => snippet.vocalist.name);
      cursorPosition = snippetsForeachVocalist[snippetsForeachVocalist.keys.first]![0].id;

      List<SnippetID> currentSelectingSnippet = getSnippetsAtCurrentSeekPosition();
      selectingSnippet = currentSelectingSnippet;
      masterSubject.add(NotifySelectingSnippets(selectingSnippet));

      updateScrollControllers();

      setState(() {});
    });
    masterSubject.stream.listen((signal) {
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

  void updateScrollControllers() {
    final Map<String, int> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap;
    snippetTimelineScrollController.removeWhere((vocalistName, scrollController) {
      if (!vocalistColorMap.containsKey(vocalistName)) {
        scrollController.dispose();
        return true;
      }
      return false;
    });

    for (var entry in vocalistColorMap.entries) {
      var vocalistName = entry.key;
      if (!snippetTimelineScrollController.containsKey(vocalistName)) {
        snippetTimelineScrollController[vocalistName] = horizontalScrollController.addAndGet();
      }
    }
  }

  void zoomIn() {
    intervalDuration = intervalDuration * 2;
  }

  void zoomOut() {
    intervalDuration = intervalDuration ~/ 2;
  }

  LyricSnippet getSnippetWithID(SnippetID id) {
    for (var entry in snippetsForeachVocalist.entries) {
      List<LyricSnippet> snippets = entry.value;

      for (var snippet in snippets) {
        if (snippet.id == id) {
          return snippet;
        }
      }
    }

    return LyricSnippet.emptySnippet;
  }

  int getSnippetIndexWithID(SnippetID id) {
    for (var entry in snippetsForeachVocalist.entries) {
      List<LyricSnippet> snippets = entry.value;

      for (int i = 0; i < snippets.length; i++) {
        if (snippets[i].id == id) {
          return i;
        }
      }
    }

    return -1;
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
    /*
    LyricSnippetID nextCursorPosition = cursorPosition;
    nextCursorPosition.index--;
    if (nextCursorPosition.index >= 0) {
      nextCursorPosition = getSnippetWithID(nextCursorPosition).id;
      cursorPosition = nextCursorPosition;
      cursorBlinker.restartCursorTimer();
    }
    */
  }

  void moveRightCursor() {
    /*
    LyricSnippetID nextCursorPosition = cursorPosition;
    nextCursorPosition.index++;
    if (nextCursorPosition.index < snippetsForeachVocalist[cursorPosition.vocalist.name]!.length) {
      nextCursorPosition = getSnippetWithID(nextCursorPosition).id;
      cursorPosition = nextCursorPosition;
      cursorBlinker.restartCursorTimer();
    }
    */
  }

  void moveUpCursor() {
    /*
    String upperVocalist = getPreviousVocalist(cursorPosition.vocalist.name)!;
    LyricSnippet snippet = getSnippetWithID(cursorPosition);
    int targetSeekPosition = (snippet.startTimestamp + snippet.endTimestamp) ~/ 2;
    cursorPosition = getNearSnippetFromSeekPosition(upperVocalist, targetSeekPosition).id;
    */
  }

  void moveDownCursor() {
    /*
    String upperVocalist = getNextVocalist(cursorPosition.vocalist.name)!;
    LyricSnippet snippet = getSnippetWithID(cursorPosition);
    int targetSeekPosition = (snippet.startTimestamp + snippet.endTimestamp) ~/ 2;
    cursorPosition = getNearSnippetFromSeekPosition(upperVocalist, targetSeekPosition).id;
    */
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

    final int audioDuration = ref.read(musicPlayerMasterProvider).audioDuration;
    final int seekPosition = ref.read(musicPlayerMasterProvider).seekPosition;

    final Map<String, int> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap;
    final TimingService timingService = ref.read(timingMasterProvider);
    return Focus(
      focusNode: focusNode,
      child: Listener(
        onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
          double horizontalOffsetLimit = scaleMarkScrollController.position.maxScrollExtent;
          double verticalOffsetLimit = verticalScrollController.position.maxScrollExtent;

          panDeltas.add(event.panDelta);
          panTimestamps.add(DateTime.now());
          if (panDeltas.length > 5) {
            panDeltas.removeAt(0);
            panTimestamps.removeAt(0);
          }
          double nextHorizontalOffset = scaleMarkScrollController.offset - event.panDelta.dx;
          if (nextHorizontalOffset < 0) {
            nextHorizontalOffset = 0;
          } else if (nextHorizontalOffset > horizontalOffsetLimit) {
            nextHorizontalOffset = horizontalOffsetLimit;
          }
          scaleMarkScrollController.jumpTo(nextHorizontalOffset);

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

          if (panDeltas.isNotEmpty && panTimestamps.isNotEmpty) {
            final int count = panDeltas.length;
            final Duration duration = panTimestamps.last.difference(panTimestamps.first);
            final Offset totalDelta = panDeltas.reduce((a, b) => a + b);

            final double velocityX = totalDelta.dx / duration.inMilliseconds * 1000;
            final double velocityY = totalDelta.dy / duration.inMilliseconds * 1000;

            double nextHorizontalOffset = scaleMarkScrollController.offset - velocityX * 0.1;
            if (nextHorizontalOffset < 0) {
              nextHorizontalOffset = 0;
            } else if (nextHorizontalOffset > horizontalOffsetLimit) {
              nextHorizontalOffset = horizontalOffsetLimit;
            }
            scaleMarkScrollController.animateTo(
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
                        key: ValueKey("Scale Mark"),
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
                    key: ValueKey("Reorderable List Vertical"),
                    buildDefaultDragHandles: false,
                    scrollController: verticalScrollController,
                    onReorder: onReorder,
                    onReorderStart: (index) {
                      isDragging = true;
                      setState(() {});
                    },
                    onReorderEnd: (index) {
                      isDragging = false;
                      setState(() {});
                    },
                    children: List.generate(vocalistColorMap.length + 1, (index) {
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
                  key: ValueKey("Seek Position"),
                  controller: seekPositionScrollController,
                  scrollDirection: Axis.horizontal,
                  child: CustomPaint(
                    size: Size(audioDuration * intervalLength / intervalDuration, 800),
                    painter: CurrentPositionIndicatorPainter(intervalLength, intervalDuration, seekPosition, timingService.sections),
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
    final Map<String, int> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap;
    if (index < vocalistColorMap.length) {
      final String vocalistName = vocalistColorMap.keys.toList()[index];
      late final double rowHeight;
      if (isDragging || snippetsForeachVocalist[vocalistName] == null) {
        rowHeight = 20;
      } else {
        final int lanes = getLanes(snippetsForeachVocalist[vocalistName]!);
        rowHeight = 60.0 * lanes;
      }
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

      final Color vocalistColor = Color(vocalistColorMap[vocalistName]!);
      final Color backgroundColor = adjustColorBrightness(vocalistColor, 0.3);

      int audioDuration = ref.read(musicPlayerMasterProvider).audioDuration;
      return Container(
        key: ValueKey('VocalistPanel_${index}'),
        height: rowHeight,
        child: Row(
          children: [
            GestureDetector(
              onTapDown: (details) {
                isDragging = true;
                setState(() {});
              },
              onTapUp: (details) {
                isDragging = false;
                setState(() {});
              },
              child: ReorderableDragStartListener(
                index: index,
                child: SvgIcon(
                  assetName: 'assets/drag_handle.svg',
                  iconColor: determineBlackOrWhite(backgroundColor),
                  backgroundColor: vocalistColor,
                  width: 20,
                  height: rowHeight,
                ),
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
                key: ValueKey("Reorderable List Item ${vocalistName}"),
                controller: snippetTimelineScrollController[vocalistName],
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
    final Map<String, int> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap;
    if (newIndex > vocalistColorMap.length) {
      newIndex = vocalistColorMap.length;
    }

    if (oldIndex < vocalistColorMap.length && newIndex <= vocalistColorMap.length) {
      final key = vocalistColorMap.keys.elementAt(oldIndex);
      final value = vocalistColorMap.remove(key)!;

      final entries = vocalistColorMap.entries.toList();
      entries.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, MapEntry(key, value));

      vocalistColorMap
        ..clear()
        ..addEntries(entries);
    }
    setState(() {});
  }

  @override
  void dispose() {
    scaleMarkScrollController.dispose();
    snippetTimelineScrollController.forEach((vocalistName, controller) {
      controller.dispose();
    });
    seekPositionScrollController.dispose();

    textFieldController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  List<SnippetID> getSnippetsAtCurrentSeekPosition() {
    int seekPosition = ref.read(musicPlayerMasterProvider).seekPosition;
    List<SnippetID> currentSnippet = [];
    snippetsForeachVocalist.forEach((vocalist, snippets) {
      for (var snippet in snippets) {
        final endtime = snippet.startTimestamp + snippet.sentenceSegments.map((point) => point.wordDuration).reduce((a, b) => a + b);
        if (snippet.startTimestamp <= seekPosition && seekPosition <= endtime) {
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
    final Map<String, int> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap;
    final String vocalistName = vocalistColorMap.keys.toList()[index];
    if (edittingVocalistIndex == index) {
      final TextEditingController controller = TextEditingController(text: vocalistName);
      oldVocalistValue = vocalistName;
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          edittingVocalistIndex = -1;
          final TimingService timingService = ref.read(timingMasterProvider);
          if (value == "") {
            timingService.deleteVocalist(oldVocalistValue);
          } else if (oldVocalistValue != value) {
            cursorBlinker.restartCursorTimer();
            timingService.changeVocalistName(oldVocalistValue, value);
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
            onDoubleTap: () async {
              List<String> oldVocalistNames = vocalistName.split(", ");
              List<String> newVocalistNames = await displayDialog(context, oldVocalistNames);
              for (int i = 0; i < oldVocalistNames.length; i++) {
                String oldName = oldVocalistNames[i];
                String newName = newVocalistNames[i];
                final TimingService timingService = ref.read(timingMasterProvider);
                if (newName == "") {
                  timingService.deleteVocalist(oldName);
                } else if (oldName != newName) {
                  timingService.changeVocalistName(oldName, newName);
                }
              }
            },
            child: CustomPaint(
              size: Size(135, constraints.maxHeight),
              painter: RectanglePainter(
                rect: Rect.fromLTRB(0.0, 0.0, 135, constraints.maxHeight),
                sentence: vocalistName,
                color: Color(vocalistColorMap[vocalistName]!),
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
    final Map<String, int> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap;
    final String vocalistName = vocalistColorMap.keys.toList()[index];
    final snippets = snippetsForeachVocalist.containsKey(vocalistName)
        ? snippetsForeachVocalist[vocalistName]!
        : [
            LyricSnippet(
                id: SnippetID(0),
                vocalist: Vocalist(
                  id: VocalistID(0),
                  name: "",
                  color: 0,
                ),
                sentence: "",
                startTimestamp: 0,
                sentenceSegments: [SentenceSegment(1, 1)]),
          ];
    double topMargin = 10;
    double bottomMargin = 5;
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        Offset localPosition = details.localPosition;
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
      onDoubleTapDown: (TapDownDetails details) async {
        Offset localPosition = details.localPosition;
        for (var snippet in snippets) {
          final endtime = snippet.startTimestamp + snippet.sentenceSegments.map((point) => point.wordDuration).reduce((a, b) => a + b);
          final touchedSeekPosition = localPosition.dx * intervalDuration / intervalLength;
          if (snippet.startTimestamp <= touchedSeekPosition && touchedSeekPosition <= endtime) {
            List<String> sentence = await displayDialog(context, [snippet.sentence]);
            final TimingService timingService = ref.read(timingMasterProvider);
            timingService.editSentence(snippet.id, sentence[0]);
          }
        }
        setState(() {});
      },
      child: CustomPaint(
        painter: TimelinePainter(
          snippets: snippets,
          selectingId: selectingSnippet,
          intervalLength: intervalLength,
          intervalDuration: intervalDuration,
          color: Color(vocalistColorMap[vocalistName]!),
          frameThickness: 3.0,
          topMargin: topMargin,
          bottomMargin: bottomMargin,
          cursorPosition: cursorBlinker.isCursorVisible ? cursorPosition : null,
        ),
      ),
    );
  }

  Widget cellAddVocalistButton() {
    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        isAddVocalistButtonSelected = true;
        /*
        cursorBlinker.restartCursorTimer();
        masterSubject.add(RequestKeyboardShortcutEnable(false));
      */
        setState(() {});
      },
      onTapUp: (TapUpDetails details) {
        isAddVocalistButtonSelected = false;
        /*
        isAddVocalistInput = "input";
      */
        setState(() {});
      },
      onTap: () async {
        String newVocalistName = (await displayDialog(context, [""]))[0];
        final TimingService timingService = ref.read(timingMasterProvider);
        timingService.addVocalist(newVocalistName);
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

  Widget cellAddVocalistButtonNeighbor() {
    return const ColoredBox(
      color: Colors.blueGrey,
    );
  }
}
