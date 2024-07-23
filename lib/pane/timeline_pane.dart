import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lyric_editor/painter/current_position_indicator_painter.dart';
import 'package:lyric_editor/painter/rectangle_painter.dart';
import 'package:lyric_editor/painter/scale_mark.dart';
import 'package:lyric_editor/painter/timeline_painter.dart';
import 'package:lyric_editor/utility/lyric_snippet.dart';
import 'package:lyric_editor/utility/signal_structure.dart';
import 'package:rxdart/rxdart.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class TimelinePane extends StatefulWidget {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;

  TimelinePane({required this.masterSubject, required this.focusNode})
      : super(key: Key('TimelinePane'));

  @override
  _TimelinePaneState createState() =>
      _TimelinePaneState(masterSubject, focusNode);
}

class _TimelinePaneState extends State<TimelinePane> {
  final PublishSubject<dynamic> masterSubject;
  final FocusNode focusNode;
  _TimelinePaneState(this.masterSubject, this.focusNode);

  final ScrollableDetails verticalDetails = ScrollableDetails(
      direction: AxisDirection.down, controller: ScrollController());
  final ScrollableDetails horizontalDetails = ScrollableDetails(
      direction: AxisDirection.right, controller: ScrollController());

  Map<String, List<LyricSnippet>> snippetsForeachVocalist = {};
  Map<String, int> vocalistColorList = {};
  Map<String, List<String>> vocalistCombinationCorrespondence = {};
  LyricSnippetID cursorPosition = LyricSnippetID(Vocalist("", 0), 0);
  bool isCursorVisible = true;
  late Timer cursorTimer;
  List<LyricSnippetID> selectingSnippet = [];
  List<String> selectingVocalist = [];
  int audioDuration = 60000;
  int currentPosition = 0;
  final ScrollController currentPositionScroller = ScrollController();
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

  @override
  void initState() {
    super.initState();
    textFieldFocusNode = FocusNode();
    textFieldFocusNode.addListener(_onFocusChange);
    masterSubject.stream.listen((signal) {
      if (signal is NotifyAudioFileLoaded) {
        setState(() {
          audioDuration = signal.millisec;
        });
      }
      if (signal is NotifySeekPosition) {
        List<LyricSnippetID> currentSelectingSnippet =
            getSnippetsAtCurrentSeekPosition();
        masterSubject.add(NotifyCurrentSnippets(currentSelectingSnippet));

        if (autoCurrentSelectMode) {
          selectingSnippet = currentSelectingSnippet;
          masterSubject.add(NotifySelectingSnippets(selectingSnippet));
        }
        setState(() {
          currentPosition = signal.seekPosition;
        });
      }
      if (signal is NotifySnippetMove ||
          signal is NotifySnippetDivided ||
          signal is NotifySnippetConcatenated ||
          signal is NotifyUndo) {
        snippetsForeachVocalist = groupBy(signal.lyricSnippetList,
            (LyricSnippet snippet) => snippet.vocalist.name);
        setState(() {});
      }
      if (signal is NotifyLyricParsed ||
          signal is NotifyVocalistAdded ||
          signal is NotifyVocalistDeleted ||
          signal is NotifyVocalistNameChanged) {
        snippetsForeachVocalist = groupBy(signal.lyricSnippetList,
            (LyricSnippet snippet) => snippet.vocalist.name);
        cursorPosition =
            snippetsForeachVocalist[snippetsForeachVocalist.keys.first]![0].id;
        vocalistColorList = signal.vocalistColorList;
        vocalistCombinationCorrespondence =
            signal.vocalistCombinationCorrespondence;
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
    horizontalDetails.controller!.addListener(_onHorizontalScroll);
    currentPositionScroller.addListener(_onHorizontalScroll);

    cursorTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      isCursorVisible = !isCursorVisible;
      setState(() {});
    });
  }

  void zoomIn() {
    debugPrint("timeline pane: zoom In");
    intervalDuration = intervalDuration * 2;
  }

  void zoomOut() {
    debugPrint("timeline pane: zoom Out");
    intervalDuration = intervalDuration ~/ 2;
  }

  LyricSnippet getSnippetWithID(LyricSnippetID id) {
    return snippetsForeachVocalist[id.vocalist.name]!
        .firstWhere((snippet) => snippet.id == id);
  }

  int getSnippetIndexWithID(LyricSnippetID id) {
    return snippetsForeachVocalist[id.vocalist.name]!
        .indexWhere((snippet) => snippet.id == id);
  }

  LyricSnippet getNearSnippetFromSeekPosition(
      String vocalistName, int targetSeekPosition) {
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
      if (snippetStart < targetSeekPosition &&
          targetSeekPosition < snippetEnd) {
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

  void resetCursorTimer() {
    cursorTimer.cancel();
    isCursorVisible = true;
    setState(() {});

    cursorTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      isCursorVisible = !isCursorVisible;
      setState(() {});
    });
  }

  void moveLeftCursor() {
    LyricSnippetID nextCursorPosition = cursorPosition;
    nextCursorPosition.index--;
    if (nextCursorPosition.index >= 0) {
      nextCursorPosition = getSnippetWithID(nextCursorPosition).id;
      cursorPosition = nextCursorPosition;
      resetCursorTimer();
    }
  }

  void moveRightCursor() {
    LyricSnippetID nextCursorPosition = cursorPosition;
    nextCursorPosition.index++;
    if (nextCursorPosition.index <
        snippetsForeachVocalist[cursorPosition.vocalist.name]!.length) {
      nextCursorPosition = getSnippetWithID(nextCursorPosition).id;
      cursorPosition = nextCursorPosition;
      resetCursorTimer();
    }
  }

  void moveUpCursor() {
    String upperVocalist = getPreviousVocalist(cursorPosition.vocalist.name)!;
    LyricSnippet snippet = getSnippetWithID(cursorPosition);
    int targetSeekPosition =
        (snippet.startTimestamp + snippet.endTimestamp) ~/ 2;
    cursorPosition =
        getNearSnippetFromSeekPosition(upperVocalist, targetSeekPosition).id;
  }

  void moveDownCursor() {
    String upperVocalist = getNextVocalist(cursorPosition.vocalist.name)!;
    LyricSnippet snippet = getSnippetWithID(cursorPosition);
    int targetSeekPosition =
        (snippet.startTimestamp + snippet.endTimestamp) ~/ 2;
    cursorPosition =
        getNearSnippetFromSeekPosition(upperVocalist, targetSeekPosition).id;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          focusNode.requestFocus();
          debugPrint("The timeline pane is focused");
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
                  size: Size(
                      audioDuration * intervalLength / intervalDuration, 800),
                  painter: CurrentPositionIndicatorPainter(
                      x: currentPosition * intervalLength / intervalDuration),
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
    cursorTimer.cancel();
    super.dispose();
  }

  List<LyricSnippetID> getSnippetsAtCurrentSeekPosition() {
    List<LyricSnippetID> currentSnippet = [];
    snippetsForeachVocalist.forEach((vocalist, snippets) {
      for (var snippet in snippets) {
        final endtime = snippet.startTimestamp +
            snippet.timingPoints
                .map((point) => point.wordDuration)
                .reduce((a, b) => a + b);
        if (snippet.startTimestamp <= currentPosition &&
            currentPosition <= endtime) {
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
    if (vicinity.row == 0 && vicinity.column == 0) {
      return TableViewCell(
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            autoCurrentSelectMode = !autoCurrentSelectMode;
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
      return TableViewCell(
        child: CustomPaint(
          painter: ScaleMark(
              intervalLength: intervalLength,
              majorMarkLength: majorMarkLength,
              midiumMarkLength: midiumMarkLength,
              minorMarkLength: minorMarkLength,
              intervalDuration: intervalDuration),
        ),
      );
    }
    if (vicinity.row == snippetsForeachVocalist.length + 1) {
      if (vicinity.column == 0) {
        if (isAddVocalistInput != "") {
          final TextEditingController controller =
              TextEditingController(text: "");
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
                  masterSubject.add(RequestAddVocalist(value));
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
    final String vocalistName =
        snippetsForeachVocalist.entries.toList()[row].key;
    if (vicinity.column == 0) {
      if (edittingVocalistIndex == row) {
        final TextEditingController controller =
            TextEditingController(text: vocalistName);
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
                masterSubject.add(RequestDeleteVocalist(oldVocalistValue));
              } else if (oldVocalistValue != value) {
                masterSubject
                    .add(RequestChangeVocalistName(oldVocalistValue, value));
              }
              setState(() {});
            },
          ),
        );
      } else {
        return TableViewCell(
          child: GestureDetector(
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
              edittingVocalistIndex = row;
              debugPrint("${row}");
              textFieldFocusNode.requestFocus();
              masterSubject.add(RequestKeyboardShortcutEnable(false));
              setState(() {});
            },
            child: CustomPaint(
              painter: RectanglePainter(
                rect: Rect.fromLTRB(0.0, 0.0, 155, 60),
                sentence: snippetsForeachVocalist.entries
                    .toList()[row]
                    .value[0]
                    .vocalist
                    .name,
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
      return TableViewCell(
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            Offset localPosition = details.localPosition;
            final snippets =
                snippetsForeachVocalist.entries.toList()[row].value;
            for (var snippet in snippets) {
              final endtime = snippet.startTimestamp +
                  snippet.timingPoints
                      .map((point) => point.wordDuration)
                      .reduce((a, b) => a + b);
              final touchedSeekPosition =
                  localPosition.dx * intervalDuration / intervalLength;
              if (snippet.startTimestamp <= touchedSeekPosition &&
                  touchedSeekPosition <= endtime) {
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
      masterSubject.add(RequestKeyboardShortcutEnable(true));
      debugPrint("release the text field focus.");
      setState(() {});
    } else {
      debugPrint("enable the text field focus.");
    }
  }

  void _onHorizontalScroll() {
    if (horizontalDetails.controller!.hasClients &&
        currentPositionScroller.hasClients) {
      if (horizontalDetails.controller!.offset !=
          currentPositionScroller.offset) {
        currentPositionScroller.jumpTo(horizontalDetails.controller!.offset);
      }
    }
  }
}

class CurrentPositionIndicator extends TwoDimensionalScrollView {
  final double x;
  final double height;

  CurrentPositionIndicator({
    super.key,
    required this.x,
    required this.height,
    required TwoDimensionalChildDelegate delegate,
    required verticalDetails,
    required horizontalDetails,
  }) : super(
          delegate: delegate,
          verticalDetails: verticalDetails,
          horizontalDetails: horizontalDetails,
        );

  @override
  Widget buildViewport(BuildContext context, ViewportOffset verticalOffset,
      ViewportOffset horizontalOffset) {
    return Container(
      color: Colors.transparent,
    );
    /*
    return CustomPaint(
      painter: CurrentPositionIndicatorPainter(x: x, height: height),
      child: Container(),
    );
    */
  }
}
