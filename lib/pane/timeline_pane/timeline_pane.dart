import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:lyric_editor/lyric_data/id/sentence_id.dart';
import 'package:lyric_editor/lyric_data/id/vocalist_id.dart';
import 'package:lyric_editor/lyric_data/vocalist/vocalist.dart';
import 'package:lyric_editor/pane/timeline_pane/seek_position/current_position_indicator_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/reorderable_list.dart/rectangle_painter.dart';
import 'package:lyric_editor/pane/timeline_pane/top_title/function_cell.dart';
import 'package:lyric_editor/pane/timeline_pane/top_title/scale_mark.dart';
import 'package:lyric_editor/pane/timeline_pane/reorderable_list.dart/sentence_timeline.dart';
import 'package:lyric_editor/pane/timeline_pane/top_title/top_title.dart';
import 'package:lyric_editor/pane/video_pane/show_hide_mode/sentence_track_map.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';
import 'package:lyric_editor/position/seek_position/seek_position.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/utility_functions.dart';
import 'package:lyric_editor/utility/cursor_blinker.dart';
import 'package:lyric_editor/dialog/text_field_dialog.dart';
import 'package:lyric_editor/utility/svg_icon.dart';
import 'package:lyric_editor/lyric_data/sentence/sentence.dart';

final timelinePaneMasterProvider = ChangeNotifierProvider((ref) {
  final MusicPlayerService musicPlayerService = ref.read(musicPlayerMasterProvider);
  final TimingService timingService = ref.read(timingMasterProvider);
  return TimelinePaneProvider(musicPlayerProvider: musicPlayerService, timingService: timingService);
});

class TimelinePaneProvider with ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;
  final TimingService timingService;

  Map<VocalistID, Map<SentenceID, Sentence>> sentencesForeachVocalist = {};
  SentenceID cursorPosition = SentenceID(0);
  List<SentenceID> selectingSentence = [];
  List<VocalistID> selectingVocalist = [];
  double intervalLength = 10.0;
  int intervalDuration = 1000;
  bool autoCurrentSelectMode = true;

  TimelinePaneProvider({
    required this.musicPlayerProvider,
    required this.timingService,
  }) {
    musicPlayerProvider.addListener(() {
      List<SentenceID> currentSelectingSentence = timingService.getSentencesAtSeekPosition().keys.toList();

      if (autoCurrentSelectMode) {
        selectingSentence = currentSelectingSentence;
        notifyListeners();
      }
    });
    timingService.addListener(() {
      final Map<SentenceID, Sentence> sentenceList = timingService.sentenceMap.map;
      sentencesForeachVocalist = groupBy(
        sentenceList.entries,
        (MapEntry<SentenceID, Sentence> entry) {
          return entry.value.vocalistID;
        },
      ).map(
        (VocalistID vocalistID, List<MapEntry<SentenceID, Sentence>> sentences) => MapEntry(
          vocalistID,
          {for (var entry in sentences) entry.key: entry.value},
        ),
      );

      cursorPosition = timingService.sentenceMap.keys.first;
      List<SentenceID> currentSelectingSentence = timingService.getSentencesAtSeekPosition().keys.toList();
      selectingSentence = currentSelectingSentence;
      notifyListeners();
    });
  }

  void moveLeftCursor() {}

  void moveRightCursor() {}

  void moveUpCursor() {}

  void moveDownCursor() {}

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
  late Map<VocalistID, ScrollController> sentenceTimelineScrollController;

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
    sentenceTimelineScrollController = {};

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
    sentenceTimelineScrollController.removeWhere((vocalistName, scrollController) {
      if (!vocalistColorMap.containsKey(vocalistName)) {
        scrollController.dispose();
        return true;
      }
      return false;
    });

    for (var entry in vocalistColorMap.entries) {
      var vocalistName = entry.key;
      if (!sentenceTimelineScrollController.containsKey(vocalistName)) {
        sentenceTimelineScrollController[vocalistName] = horizontalScrollController.addAndGet();
      }
    }
  }

  Sentence getSentenceWithID(SentenceID id) {
    final Map<SentenceID, Sentence> sentenceList = ref.read(timingMasterProvider).sentenceMap.map;
    return sentenceList[id]!;
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
    final AbsoluteSeekPosition seekPosition = musicPlayerService.seekPosition;
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
                TopTitle(
                  seekPosition: seekPosition,
                  audioDuration: audioDuration,
                  intervalLength: intervalLength,
                  intervalDuration: intervalDuration,
                  scrollController: scaleMarkScrollController,
                ),
                Expanded(
                  child: ,
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

    final Map<VocalistID, Map<SentenceID, Sentence>> sentencesForeachVocalist = timelinePaneProvider.sentencesForeachVocalist;
    final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];
    if (isDragging || sentencesForeachVocalist[vocalistID] == null) {
      return 20;
    } else {
      ShowHideTrackMap showHideTrackMap = ShowHideTrackMap(sentenceMap: timingService.sentenceMap, vocalistID: vocalistID);
      final int lanes = showHideTrackMap.getMaxTrackNumber();
      return 60.0 * lanes;
    }
  }

  @override
  void dispose() {
    scaleMarkScrollController.dispose();
    sentenceTimelineScrollController.forEach((vocalistName, controller) {
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

  int getLanes(List<Sentence> sentenceList) {
    if (sentenceList.isEmpty) return 1;
    sentenceList.sort((a, b) => a.startTimestamp.compareTo(b.startTimestamp));

    int maxOverlap = 1;
    int currentOverlap = 1;
    int currentEndTime = sentenceList[0].endTimestamp.position;

    for (int i = 1; i < sentenceList.length; ++i) {
      int start = sentenceList[i].startTimestamp.position;
      int end = sentenceList[i].endTimestamp.position;
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

  Widget cellSentenceTimeline(int index) {
    final TimingService timingService = ref.read(timingMasterProvider);
    final Map<VocalistID, Vocalist> vocalistColorMap = timingService.vocalistColorMap.map;
    final VocalistID vocalistID = vocalistColorMap.keys.toList()[index];

    return SentenceTimeline(
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
