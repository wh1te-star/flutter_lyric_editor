import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:lyric_editor/lyric_snippet/id/lyric_snippet_id.dart';
import 'package:lyric_editor/lyric_snippet/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_snippet/vocalist/vocalist.dart';
import 'package:lyric_editor/pane/timeline_pane/current_position_indicator_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/rectangle_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/scale_mark.dart';
import 'package:lyric_editor/pane/snippet_timeline.dart';
import 'package:lyric_editor/pane/video_pane/show_hide_mode/lyric_snippet_track_map.dart';
import 'package:lyric_editor/position/seek_position.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/utility_functions.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:lyric_editor/dialog/text_field_dialog.dart';
import 'package:lyric_editor/utility/svg_icon.dart';
import 'package:lyric_editor/lyric_snippet/lyric_snippet/lyric_snippet.dart';

final timelinePaneMasterProvider = ChangeNotifierProvider((ref) {
  final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
  final TimingService timingService = ref.read(timingMasterProvider);
  return TimelinePaneProvider(musicPlayerProvider: musicPlayerService, timingService: timingService);
});

class TimelinePaneProvider with ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;
  final TimingService timingService;

  Map<VocalistID, Map<LyricSnippetID, LyricSnippet>> snippetsForeachVocalist = {};
  LyricSnippetID cursorPosition = LyricSnippetID(0);
  List<LyricSnippetID> selectingSnippets = [];
  List<VocalistID> selectingVocalist = [];
  double intervalLength = 10.0;
  double majorMarkLength = 15.0;
  double midiumMarkLength = 11.0;
  double minorMarkLength = 8.0;
  int intervalDuration = 1000;
  bool autoCurrentSelectMode = true;

  TimelinePaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    musicPlayerProvider.addListener(() {
      List<LyricSnippetID> currentSelectingSnippet = timingService.getSnippetsAtSeekPosition().keys.toList();

      if (autoCurrentSelectMode) {
        selectingSnippets = currentSelectingSnippet;
        notifyListeners();
      }
    });
    timingService.addListener(() {
      final Map<LyricSnippetID, LyricSnippet> lyricSnippetList = timingService.lyricSnippetMap.map;
      snippetsForeachVocalist = groupBy(
        lyricSnippetList.entries,
        (MapEntry<LyricSnippetID, LyricSnippet> entry) {
          return entry.value.vocalistID;
        },
      ).map(
        (VocalistID vocalistID, List<MapEntry<LyricSnippetID, LyricSnippet>> snippets) => MapEntry(
          vocalistID,
          {for (var entry in snippets) entry.key: entry.value},
        ),
      );

      cursorPosition = timingService.lyricSnippetMap.keys.first;
      List<LyricSnippetID> currentSelectingSnippet = timingService.getSnippetsAtSeekPosition().keys.toList();
      selectingSnippets = currentSelectingSnippet;
      notifyListeners();
    });
  }

  void moveLeftCursor() {
    /*
    SnippetID nextCursorPosition = cursorPosition;
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

  void zoomIn() {
    intervalDuration = intervalDuration * 2;
    notifyListeners();
  }

  void zoomOut() {
    intervalDuration = intervalDuration ~/ 2;
    notifyListeners();
  }
}

class TimelinePane extends ConsumerStatefulWidget {
  final FocusNode focusNode;

  const TimelinePane({required this.focusNode}) : super(key: const Key('TimelinePane'));

  @override
  _TimelinePaneState createState() => _TimelinePaneState(focusNode);
}

class _TimelinePaneState extends ConsumerState<TimelinePane> {
  final FocusNode focusNode;
  _TimelinePaneState(this.focusNode);

  ScrollController verticalScrollController = ScrollController();
  LinkedScrollControllerGroup horizontalScrollController = LinkedScrollControllerGroup();
  late ScrollController scaleMarkScrollController;
  late ScrollController seekPositionScrollController;
  late Map<VocalistID, ScrollController> snippetTimelineScrollController;

  List<Offset> panDeltas = [];
  List<DateTime> panTimestamps = [];
  bool isDragging = false;

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
      setState(() {});
    });

    timingService.addListener(() {
      updateScrollControllers();
      setState(() {});
    });
    //horizontalDetails.controller!.addListener(_onHorizontalScroll);

    cursorBlinker = CursorBlinker(
        blinkIntervalInMillisec: 1000,
        onTick: () {
          setState(() {});
        });
  }

  void updateScrollControllers() {
    final Map<VocalistID, Vocalist> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap.map;
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

  LyricSnippet getSnippetWithID(LyricSnippetID id) {
    final Map<LyricSnippetID, LyricSnippet> lyricSnippetList = ref.read(timingMasterProvider).lyricSnippetMap.map;
    return lyricSnippetList[id]!;
  }

  /*
  LyricSnippet getNearSnippetFromSeekPosition(String vocalistName, int targetSeekPosition) {
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
    List<LyricSnippet> snippets = timelinePaneProvider.snippetsForeachVocalist[vocalistName]!.values.toList();
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
    */

  String? getNextVocalist(String currentVocalist) {
    /*
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
    List<VocalistID> vocalists = timelinePaneProvider.snippetsForeachVocalist.keys.toList();
    int currentIndex = vocalists.indexOf(currentVocalist);
    if (currentIndex != -1 && currentIndex < vocalists.length - 1) {
      return vocalists[currentIndex + 1];
    }
    */
    return null;
  }

  String? getPreviousVocalist(String currentVocalist) {
    /*
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
    List<String> vocalists = timelinePaneProvider.snippetsForeachVocalist.keys.toList();
    int currentIndex = vocalists.indexOf(currentVocalist);
    if (currentIndex > 0) {
      return vocalists[currentIndex - 1];
    }
    */
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final Widget borderLine = Container(
      width: 5,
      height: 30,
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Colors.black,
            width: 5,
          ),
        ),
      ),
    );

    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Duration audioDuration = musicPlayerService.audioDuration;
    final SeekPosition seekPosition = musicPlayerService.seekPosition;
    final Map<VocalistID, Vocalist> vocalistColorMap = timingService.vocalistColorMap.map;
    final double intervalLength = timelinePaneProvider.intervalLength;
    final int intervalDuration = timelinePaneProvider.intervalDuration;

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
              duration: const Duration(milliseconds: 500),
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
              duration: const Duration(milliseconds: 500),
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
                    SizedBox(
                      width: 155,
                      height: 30,
                      child: cellFunctionButton(),
                    ),
                    borderLine,
                    Expanded(
                      child: SingleChildScrollView(
                        key: const ValueKey("Scale Mark"),
                        controller: scaleMarkScrollController,
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: audioDuration.inMilliseconds * intervalLength / intervalDuration,
                          height: 30,
                          child: cellScaleMark(),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: ReorderableListView(
                    key: const ValueKey("Reorderable List Vertical"),
                    buildDefaultDragHandles: false,
                    scrollController: verticalScrollController,
                    onReorder: onReorder,
                    onReorderEnd: (index) {
                      isDragging = false;
                    },
                    children: List.generate(vocalistColorMap.length + 1, (index) {
                      return AnimatedContainer(
                        key: ValueKey('VocalistPanel_$index'),
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        height: getReorderableListHeight(index),
                        child: itemBuilder(context, index),
                      );
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
                  key: const ValueKey("Seek Position"),
                  controller: seekPositionScrollController,
                  scrollDirection: Axis.horizontal,
                  child: CustomPaint(
                    size: Size(audioDuration.inMilliseconds * intervalLength / intervalDuration, 800),
                    painter: CurrentPositionIndicatorPainter(intervalLength, intervalDuration, seekPosition.position, timingService.sectionList.list),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getReorderableListHeight(int index) {
    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Map<VocalistID, Vocalist> vocalistColorMap = timingService.vocalistColorMap.map;

    if (index >= vocalistColorMap.length) {
      if (isDragging) {
        return 0;
      } else {
        return 40;
      }
    }

    final Map<VocalistID, Map<LyricSnippetID, LyricSnippet>> snippetsForeachVocalist = timelinePaneProvider.snippetsForeachVocalist;
    final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];
    if (isDragging || snippetsForeachVocalist[vocalistID] == null) {
      return 20;
    } else {
      ShowHideTrackMap showHideTrackMap = ShowHideTrackMap(lyricSnippetMap: timingService.lyricSnippetMap, vocalistID: vocalistID);
      final int lanes = showHideTrackMap.getMaxTrackNumber();
      return 60.0 * lanes;
    }
  }

  Widget itemBuilder(BuildContext context, int index) {
    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimingService timingService = ref.read(timingMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    final Duration audioDuration = musicPlayerService.audioDuration;
    final Map<VocalistID, Vocalist> vocalistColorMap = timingService.vocalistColorMap.map;
    final double intervalLength = timelinePaneProvider.intervalLength;
    final int intervalDuration = timelinePaneProvider.intervalDuration;

    if (index < vocalistColorMap.length) {
      final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];

      final Color vocalistColor = Color(vocalistColorMap[vocalistID]!.color);
      final Color backgroundColor = adjustColorBrightness(vocalistColor, 0.3);

      final Widget borderLine = Container(
        width: 5,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.black,
              width: 5,
            ),
          ),
        ),
      );

      return Row(
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
              ),
            ),
          ),
          SizedBox(
            width: 135,
            child: Container(alignment: Alignment.topLeft, child: cellVocalistPanel(index)),
          ),
          borderLine,
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey("Reorderable List Item ${vocalistID.id}"),
              controller: snippetTimelineScrollController[vocalistID],
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: audioDuration.inMilliseconds * intervalLength / intervalDuration,
                child: cellSnippetTimeline(index),
              ),
            ),
          ),
        ],
      );
    } else {
      final Widget borderLine = Container(
        width: 5,
        height: 40,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Colors.black,
              width: 5,
            ),
          ),
        ),
      );
      return Row(
        key: const ValueKey('AddVocalistButton'),
        children: [
          SizedBox(
            width: 155,
            height: getReorderableListHeight(index),
            child: cellAddVocalistButton(),
          ),
          borderLine,
          Expanded(child: cellAddVocalistButtonNeighbor()),
        ],
      );
    }
  }

  void onReorder(int oldIndex, int newIndex) {
    final Map<VocalistID, Vocalist> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap.map;
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
    int currentEndTime = lyricSnippetList[0].endTimestamp.position;

    for (int i = 1; i < lyricSnippetList.length; ++i) {
      int start = lyricSnippetList[i].startTimestamp.position;
      int end = lyricSnippetList[i].endTimestamp.position;
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
    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        timelinePaneProvider.autoCurrentSelectMode = !timelinePaneProvider.autoCurrentSelectMode;
        setState(() {});
      },
      child: CustomPaint(
        painter: RectanglePainter(
          rect: const Rect.fromLTRB(0.0, 0.0, 155, 30),
          sentence: musicPlayerService.seekPosition.toString(),
          color: Colors.purpleAccent,
          isSelected: timelinePaneProvider.autoCurrentSelectMode,
          borderLineWidth: 3.0,
        ),
      ),
    );
  }

  Widget cellScaleMark() {
    final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
    final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
    final double intervalLength = timelinePaneProvider.intervalLength;
    final int intervalDuration = timelinePaneProvider.intervalDuration;
    final double majorMarkLength = timelinePaneProvider.majorMarkLength;
    final double midiumMarkLength = timelinePaneProvider.midiumMarkLength;
    final double minorMarkLength = timelinePaneProvider.minorMarkLength;

    return GestureDetector(
      onTapDown: (TapDownDetails details) async {
        Offset localPosition = details.localPosition;
        final touchedSeekPosition = localPosition.dx * intervalDuration / intervalLength;
        musicPlayerService.seek(touchedSeekPosition.toInt());
        setState(() {});
      },
      child: CustomPaint(
        painter: ScaleMark(
          intervalLength: intervalLength,
          majorMarkLength: majorMarkLength,
          midiumMarkLength: midiumMarkLength,
          minorMarkLength: minorMarkLength,
          intervalDuration: intervalDuration,
        ),
      ),
    );
  }

  Widget cellVocalistPanel(int index) {
    final Map<VocalistID, Vocalist> vocalistColorMap = ref.read(timingMasterProvider).vocalistColorMap.map;
    final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];
    final String vocalistName = vocalistColorMap.values.toList()[index].name;
    if (edittingVocalistIndex == index) {
      final TextEditingController controller = TextEditingController(text: vocalistName);
      oldVocalistValue = vocalistName;
      return TextField(
        controller: controller,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          edittingVocalistIndex = -1;
          final TimingService timingService = ref.read(timingMasterProvider);
          if (value == "") {
            timingService.removeVocalistByName(oldVocalistValue);
          } else if (oldVocalistValue != value) {
            cursorBlinker.restartCursorTimer();
            timingService.changeVocalistName(oldVocalistValue, value);
          }
          setState(() {});
        },
      );
    } else {
      final TimelinePaneProvider timelinePaneProvider = ref.read(timelinePaneMasterProvider);
      final List<VocalistID> selectingVocalist = timelinePaneProvider.selectingVocalist;

      return LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (TapDownDetails details) {
              if (selectingVocalist.contains(vocalistID)) {
                selectingVocalist.remove(vocalistID);
              } else {
                selectingVocalist.add(vocalistID);
              }
              setState(() {});
            },
            onDoubleTap: () async {
              List<String> oldVocalistNames = vocalistName.split(", ");
              List<String> newVocalistNames = await displayTextFieldDialog(context, oldVocalistNames);
              for (int i = 0; i < oldVocalistNames.length; i++) {
                String oldName = oldVocalistNames[i];
                String newName = newVocalistNames[i];
                final TimingService timingService = ref.read(timingMasterProvider);
                if (newName == "") {
                  timingService.removeVocalistByName(oldName);
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
                color: Color(vocalistColorMap[vocalistID]!.color),
                isSelected: selectingVocalist.contains(vocalistID),
                borderLineWidth: 1.0,
              ),
            ),
          );
        },
      );
    }
  }

  Widget cellSnippetTimeline(int index) {
    final TimingService timingService = ref.read(timingMasterProvider);
    final Map<VocalistID, Vocalist> vocalistColorMap = timingService.vocalistColorMap.map;
    final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];

    return SnippetTimeline(
      vocalistID,
    );
  }

  Widget cellAddVocalistButton() {
    if (isDragging) {
      return Container(
        color: Colors.grey,
        child: const Text("+"),
      );
    } else {
      return GestureDetector(
        onTapDown: (TapDownDetails details) {
          isAddVocalistButtonSelected = true;
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
          String newVocalistName = (await displayTextFieldDialog(context, [""]))[0];
          final TimingService timingService = ref.read(timingMasterProvider);
          timingService.addVocalist(Vocalist(name: newVocalistName, color: 0xFF222222));
        },
        child: CustomPaint(
          size: const Size(double.infinity, double.infinity),
          painter: RectanglePainter(
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
}
