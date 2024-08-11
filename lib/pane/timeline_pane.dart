import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lyric_editor/painter/current_position_indicator_painter.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
import 'package:lyric_editor/painter/scale_mark.dart';
import 'package:lyric_editor/painter/timeline_painter.dart';
import 'package:lyric_editor/pane/text_pane.dart';
import 'package:lyric_editor/pane/video_pane.dart';
import 'package:lyric_editor/service/music_player_service.dart';
import 'package:lyric_editor/service/timing_service.dart';
import 'package:lyric_editor/utility/keyboard_shortcuts.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

final timelinePaneMasterProvider = ChangeNotifierProvider((ref) {
  final musicPlayer = ref.watch(musicPlayerMasterProvider);
  final timing = ref.watch(timingMasterProvider);
  return TimelinePaneNotifier(musicPlayer, timing);
});

class TimelinePaneNotifier with ChangeNotifier {
  final MusicPlayerService musicPlayerProvider;
  final TimingService timingProvider;

  TimelinePaneNotifier(this.musicPlayerProvider, this.timingProvider) {
    cursorTimer = Timer.periodic(Duration(seconds: cursorBlinkInterval), (timer) {
      isCursorVisible = !isCursorVisible;
    });

    musicPlayerProvider.addListener(() {
      if (autoCurrentSelectMode) {
        selectingSnippet = getSnippetsAtCurrentSeekPosition();
      }
    });
    timingProvider.addListener(() {
      snippetsForeachVocalist = groupBy(timingProvider.lyricSnippetList, (LyricSnippet snippet) => snippet.vocalist.name);
    });
  }

  Map<String, List<LyricSnippet>> snippetsForeachVocalist = {};
  LyricSnippetID cursorPosition = LyricSnippetID(Vocalist("", 0), 0);

  bool isCursorVisible = true;
  late Timer cursorTimer;
  int cursorBlinkInterval = 1;

  List<LyricSnippetID> selectingSnippet = [];
  List<String> selectingVocalist = [];
  double intervalLength = 10.0;
  double majorMarkLength = 15.0;
  double midiumMarkLength = 11.0;
  double minorMarkLength = 8.0;
  int intervalDuration = 1000;
  bool autoCurrentSelectMode = true;

  /*
      if (signal is NotifySnippetMove || signal is NotifySnippetDivided || signal is NotifySnippetConcatenated || signal is NotifyUndo) {
        snippetsForeachVocalist = groupBy(signal.lyricSnippetList, (LyricSnippet snippet) => snippet.vocalist.name);
      }
      if (signal is NotifyLyricParsed || signal is NotifyVocalistAdded || signal is NotifyVocalistDeleted || signal is NotifyVocalistNameChanged) {
        snippetsForeachVocalist = groupBy(signal.lyricSnippetList, (LyricSnippet snippet) => snippet.vocalist.name);
        cursorPosition = snippetsForeachVocalist[snippetsForeachVocalist.keys.first]![0].id;
        vocalistColorList = signal.vocalistColorList;
        vocalistCombinationCorrespondence = signal.vocalistCombinationCorrespondence;
      }
      */
  void requestTimelineZoomIn() {
    zoomIn();
  }

  void requestTimelineZoomOut() {
    zoomOut();
  }

  void requestTimelineCursorMoveLeft() {
    moveLeftCursor();
  }

  void requestTimelineCursorMoveRight() {
    moveRightCursor();
  }

  void requestTimelineCursorMoveUp() {
    moveUpCursor();
  }

  void requestTimelineCursorMoveDown() {
    moveDownCursor();
  }

  void zoomIn() {
    intervalDuration = intervalDuration * 2;
  }

  void zoomOut() {
    intervalDuration = intervalDuration ~/ 2;
  }

  void pauseCursorTimer() {
    cursorTimer.cancel();
  }

  void restartCursorTimer() {
    cursorTimer.cancel();
    isCursorVisible = true;
    cursorTimer = Timer.periodic(Duration(seconds: cursorBlinkInterval), (timer) {
      isCursorVisible = !isCursorVisible;
    });
  }

  void moveLeftCursor() {
    LyricSnippetID nextCursorPosition = cursorPosition;
    nextCursorPosition.index--;
    if (nextCursorPosition.index >= 0) {
      nextCursorPosition = getSnippetWithID(nextCursorPosition).id;
      cursorPosition = nextCursorPosition;
      restartCursorTimer();
    }
  }

  void moveRightCursor() {
    LyricSnippetID nextCursorPosition = cursorPosition;
    nextCursorPosition.index++;
    if (nextCursorPosition.index < snippetsForeachVocalist[cursorPosition.vocalist.name]!.length) {
      nextCursorPosition = getSnippetWithID(nextCursorPosition).id;
      cursorPosition = nextCursorPosition;
      restartCursorTimer();
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

  List<LyricSnippetID> getSnippetsAtCurrentSeekPosition() {
    List<LyricSnippetID> currentSnippet = [];
    int currentPosition = musicPlayerProvider.seekPosition;
    snippetsForeachVocalist.forEach((vocalist, snippets) {
      for (var snippet in snippets) {
        final endtime = snippet.startTimestamp + snippet.timingPoints.map((point) => point.wordDuration).reduce((a, b) => a + b);
        if (snippet.startTimestamp <= currentPosition && currentPosition <= endtime) {
          currentSnippet.add(snippet.id);
        }
      }
    });
    return currentSnippet;
  }

  void dispose() {
    cursorTimer.cancel();
    super.dispose();
  }
}

class TimelinePane extends ConsumerStatefulWidget {
  final FocusNode focusNode;

  TimelinePane(this.focusNode);
  @override
  _TimelinePaneState createState() => _TimelinePaneState(focusNode);
}

class _TimelinePaneState extends ConsumerState<TimelinePane> {
  final FocusNode focusNode;
  late final KeyboardShortcutsNotifier keyboardShortcutsProvider = ref.watch(keyboardShortcutsMasterProvider);
  late final MusicPlayerService musicPlayerProvider = ref.watch(musicPlayerMasterProvider);
  late final TimingService timingProvider = ref.watch(timingMasterProvider);
  late final TextPaneNotifier textPaneProvider = ref.watch(textPaneMasterProvider);
  late final TimelinePaneNotifier timelinePaneProvider = ref.watch(timelinePaneMasterProvider);

  _TimelinePaneState(this.focusNode);

  final ScrollController currentPositionScroller = ScrollController();
  final ScrollableDetails verticalDetails = ScrollableDetails(direction: AxisDirection.down, controller: ScrollController());
  final ScrollableDetails horizontalDetails = ScrollableDetails(direction: AxisDirection.right, controller: ScrollController());
  FocusNode textFieldFocusNode = FocusNode();
  String isAddVocalistInput = "";
  bool isAddVocalistButtonSelected = false;
  int edittingVocalistIndex = -1;
  String oldVocalistValue = "";

  @override
  void initState() {
    super.initState();
    textFieldFocusNode.addListener(_onFocusChange);
    horizontalDetails.controller!.addListener(_onHorizontalScroll);
    currentPositionScroller.addListener(_onHorizontalScroll);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<KeyboardShortcutsNotifier>(keyboardShortcutsMasterProvider, (previous, current) {
      setState(() {});
    });
    ref.listen<MusicPlayerService>(musicPlayerMasterProvider, (previous, current) {
      setState(() {});
    });
    ref.listen<TimingService>(timingMasterProvider, (previous, current) {
      setState(() {});
    });
    ref.listen<TextPaneNotifier>(textPaneMasterProvider, (previous, current) {
      setState(() {});
    });
    ref.listen<TimelinePaneNotifier>(timelinePaneMasterProvider, (previous, current) {
      setState(() {});
    });
    ref.listen<VideoPaneNotifier>(videoPaneMasterProvider, (previous, current) {
      setState(() {});
    });

    Map<String, List<LyricSnippet>> snippetsForeachVocalist = timelinePaneProvider.snippetsForeachVocalist;
    int audioDuration = musicPlayerProvider.audioDuration;
    int intervalDuration = timelinePaneProvider.intervalDuration;
    double intervalLength = timelinePaneProvider.intervalLength;
    int currentPosition = musicPlayerProvider.seekPosition;

    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          if (!textFieldFocusNode.hasFocus) {
            focusNode.requestFocus();
            debugPrint("The timeline pane is focused");
          }
        },
        child: Stack(children: [
          TableView.builder(
            verticalDetails: verticalDetails,
            horizontalDetails: horizontalDetails,
            diagonalDragBehavior: DiagonalDragBehavior.free,
            cellBuilder: _buildCell,
            columnCount: 2,
            pinnedColumnCount: 1,
            columnBuilder: _buildColumnSpan,
            rowCount: snippetsForeachVocalist.length + 2,
            pinnedRowCount: 1,
            rowBuilder: _buildRowSpan,
          ),
          IgnorePointer(
            ignoring: true,
            child: Padding(
              padding: const EdgeInsets.only(left: 160.0),
              child: SingleChildScrollView(
                controller: currentPositionScroller,
                scrollDirection: Axis.horizontal,
                child: CustomPaint(
                  size: Size(audioDuration * intervalLength / intervalDuration, 800),
                  painter: CurrentPositionIndicatorPainter(x: currentPosition * intervalLength / intervalDuration),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    horizontalDetails.controller!.removeListener(_onHorizontalScroll);
    currentPositionScroller.removeListener(_onHorizontalScroll);
    horizontalDetails.controller!.dispose();
    currentPositionScroller.dispose();
    super.dispose();
  }

  List<LyricSnippetID> getSnippetsAtCurrentSeekPosition() {
    List<LyricSnippetID> currentSnippet = [];
    Map<String, List<LyricSnippet>> snippetsForeachVocalist = timelinePaneProvider.snippetsForeachVocalist;
    int currentPosition = musicPlayerProvider.seekPosition;
    snippetsForeachVocalist.forEach((vocalist, snippets) {
      for (var snippet in snippets) {
        final endtime = snippet.startTimestamp + snippet.timingPoints.map((point) => point.wordDuration).reduce((a, b) => a + b);
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

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    Map<String, List<LyricSnippet>> snippetsForeachVocalist = timelinePaneProvider.snippetsForeachVocalist;
    if (vicinity.row == 0 && vicinity.column == 0) {
      bool autoCurrentSelectMode = timelinePaneProvider.autoCurrentSelectMode;
      return TableViewCell(
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            timelinePaneProvider.autoCurrentSelectMode = !autoCurrentSelectMode;
            setState(() {});
          },
          child: CustomPaint(
            painter: RectanglePainter(
              rect: Rect.fromLTRB(1.0, -9.0, 154, 19),
              sentence: "Auto Select Mode",
              color: Colors.purpleAccent,
              isSelected: autoCurrentSelectMode,
            ),
          ),
        ),
      );
    }
    if (vicinity.row == 0) {
      int intervalDuration = timelinePaneProvider.intervalDuration;
      double intervalLength = timelinePaneProvider.intervalLength;
      double majorMarkLength = timelinePaneProvider.majorMarkLength;
      double midiumMarkLength = timelinePaneProvider.midiumMarkLength;
      double minorMarkLength = timelinePaneProvider.minorMarkLength;
      return TableViewCell(
        child: CustomPaint(
          painter: ScaleMark(intervalLength: intervalLength, majorMarkLength: majorMarkLength, midiumMarkLength: midiumMarkLength, minorMarkLength: minorMarkLength, intervalDuration: intervalDuration),
        ),
      );
    }
    if (vicinity.row == snippetsForeachVocalist.length + 1) {
      if (vicinity.column == 0) {
        if (isAddVocalistInput != "") {
          final TextEditingController controller = TextEditingController(text: "");
          return TableViewCell(
            child: TextField(
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
                  timingProvider.requestAddVocalist(value);
                  debugPrint("RequestAddVocalist ${value}");
                }
                isAddVocalistInput = "";
                setState(() {});
              },
            ),
          );
        } else {
          return TableViewCell(
            child: GestureDetector(
              onTapDown: (TapDownDetails details) {
                isAddVocalistButtonSelected = true;
                textFieldFocusNode.requestFocus();
                timelinePaneProvider.restartCursorTimer();
                keyboardShortcutsProvider.setEnable(false);
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
                ),
              ),
            ),
          );
        }
      } else {
        return const TableViewCell(
            child: ColoredBox(
          color: Colors.blueGrey,
        ));
      }
    }
    int row = vicinity.row - 1;
    final String vocalistName = snippetsForeachVocalist.entries.toList()[row].key;
    if (vicinity.column == 0) {
      if (edittingVocalistIndex == row) {
        final TextEditingController controller = TextEditingController(text: vocalistName);
        oldVocalistValue = vocalistName;
        return TableViewCell(
          child: TextField(
            controller: controller,
            focusNode: textFieldFocusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              edittingVocalistIndex = -1;
              if (value == "") {
                timingProvider.requestDeleteVocalist(oldVocalistValue);
              } else if (oldVocalistValue != value) {
                timelinePaneProvider.restartCursorTimer();
                timingProvider.requestChangeVocalistName(oldVocalistValue, value);
              }
              setState(() {});
            },
          ),
        );
      } else {
        List<String> selectingVocalist = timelinePaneProvider.selectingVocalist;
        Map<String, int> vocalistColorList = timingProvider.vocalistColorList;
        return TableViewCell(
          child: GestureDetector(
            onTapDown: (TapDownDetails details) {
              if (selectingVocalist.contains(vocalistName)) {
                selectingVocalist.remove(vocalistName);
                //masterSubject.add(NotifyDeselectingVocalist(vocalistName));
              } else {
                selectingVocalist.add(vocalistName);
                //masterSubject.add(NotifySelectingVocalist(vocalistName));
              }
              setState(() {});
            },
            onDoubleTap: () {
              edittingVocalistIndex = row;
              debugPrint("${row}");
              textFieldFocusNode.requestFocus();
              timelinePaneProvider.pauseCursorTimer();
              keyboardShortcutsProvider.setEnable(false);
              setState(() {});
            },
            child: CustomPaint(
              painter: RectanglePainter(
                rect: Rect.fromLTRB(0.0, 0.0, 155, 60),
                sentence: snippetsForeachVocalist.entries.toList()[row].value[0].vocalist.name,
                color: Color(vocalistColorList[vocalistName]!),
                isSelected: selectingVocalist.contains(vocalistName),
              ),
            ),
          ),
        );
      }
    }
    if (row < snippetsForeachVocalist.length) {
      double topMargin = 10;
      double bottomMargin = 5;

      List<LyricSnippetID> selectingSnippet = timelinePaneProvider.selectingSnippet;
      Map<String, int> vocalistColorList = timingProvider.vocalistColorList;
      int intervalDuration = timelinePaneProvider.intervalDuration;
      double intervalLength = timelinePaneProvider.intervalLength;
      bool isCursorVisible = timelinePaneProvider.isCursorVisible;
      LyricSnippetID cursorPosition = timelinePaneProvider.cursorPosition;
      return TableViewCell(
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            Offset localPosition = details.localPosition;
            final snippets = snippetsForeachVocalist.entries.toList()[row].value;
            for (var snippet in snippets) {
              final endtime = snippet.startTimestamp + snippet.timingPoints.map((point) => point.wordDuration).reduce((a, b) => a + b);
              final touchedSeekPosition = localPosition.dx * intervalDuration / intervalLength;
              if (snippet.startTimestamp <= touchedSeekPosition && touchedSeekPosition <= endtime) {
                if (selectingSnippet.contains(snippet.id)) {
                  selectingSnippet.remove(snippet.id);
                } else {
                  selectingSnippet.add(snippet.id);
                }
              }
            }
            setState(() {});
          },
          child: CustomPaint(
            painter: TimelinePainter(
              snippets: snippetsForeachVocalist.entries.toList()[row].value,
              selectingId: selectingSnippet,
              intervalLength: intervalLength,
              intervalDuration: intervalDuration,
              topMargin: topMargin,
              bottomMargin: bottomMargin,
              color: Color(vocalistColorList[vocalistName]!),
              cursorPosition: isCursorVisible ? cursorPosition : null,
            ),
          ),
        ),
      );
    } else {
      return TableViewCell(
        child: ColoredBox(color: Colors.white),
      );
    }
  }

  TableSpan _buildColumnSpan(int index) {
    int audioDuration = musicPlayerProvider.audioDuration;
    int intervalDuration = timelinePaneProvider.intervalDuration;
    double intervalLength = timelinePaneProvider.intervalLength;

    double extent = 0;
    if (index == 0) {
      extent = 160;
    } else {
      extent = audioDuration * intervalLength / intervalDuration;
    }
    return TableSpan(
        extent: FixedTableSpanExtent(extent),
        foregroundDecoration: TableSpanDecoration(
          border: TableSpanBorder(
            trailing: BorderSide(
              width: (index == 0) ? 5 : 1,
              color: Colors.black,
            ),
          ),
        ));
  }

  TableSpan _buildRowSpan(int index) {
    Map<String, List<LyricSnippet>> snippetsForeachVocalist = timelinePaneProvider.snippetsForeachVocalist;

    late final extent;
    if (index == 0) {
      extent = 20.0;
    } else if (index == snippetsForeachVocalist.length + 1) {
      extent = 40.0;
    } else {
      extent = 60.0;
    }
    return TableSpan(
      extent: FixedTableSpanExtent(extent),
      padding: index == 0 ? TableSpanPadding(leading: 10.0) : null,
      foregroundDecoration: const TableSpanDecoration(
        border: TableSpanBorder(
          trailing: BorderSide(
            width: 1,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  void _onFocusChange() {
    if (!textFieldFocusNode.hasFocus) {
      edittingVocalistIndex = -1;
      isAddVocalistInput = "";
      timelinePaneProvider.restartCursorTimer();
      keyboardShortcutsProvider.setEnable(true);
      debugPrint("release the text field focus.");
      setState(() {});
    } else {
      debugPrint("enable the text field focus.");
    }
  }

  void _onHorizontalScroll() {
    if (horizontalDetails.controller!.hasClients && currentPositionScroller.hasClients) {
      if (horizontalDetails.controller!.offset != currentPositionScroller.offset) {
        currentPositionScroller.jumpTo(horizontalDetails.controller!.offset);
      }
    }
  }
}
