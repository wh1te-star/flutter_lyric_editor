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
  List<LyricSnippetID> selectingSnippet = [];
  List<String> vocalistList = [];
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
  String oldVocalistName = "";
  late FocusNode textFieldFocusNode;

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
      if (signal is NotifyLyricParsed ||
          signal is NotifyVocalistNameChanged ||
          signal is NotifySnippetMove ||
          signal is NotifySnippetDivided ||
          signal is NotifySnippetConcatenated) {
        setState(() {
          snippetsForeachVocalist = groupBy(signal.lyricSnippetList,
              (LyricSnippet snippet) => snippet.vocalist);
        });
      }
      if (signal is RequestTimelineZoomIn) {
        zoomIn();
        setState(() {});
      }
      if (signal is RequestTimelineZoomOut) {
        zoomOut();
        setState(() {});
      }
    });
    horizontalDetails.controller!.addListener(_onHorizontalScroll);
    currentPositionScroller.addListener(_onHorizontalScroll);
  }

  void zoomIn() {
    debugPrint("timeline pane: zoom In");
    intervalDuration = intervalDuration * 2;
  }

  void zoomOut() {
    debugPrint("timeline pane: zoom Out");
    intervalDuration = intervalDuration ~/ 2;
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
            rowCount: snippetsForeachVocalist.length + 1,
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

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final ({String name, Color color}) cell =
        (name: "empty", color: indexColor(vicinity.row - 1));
    final Color textColor =
        ThemeData.estimateBrightnessForColor(cell.color) == Brightness.light
            ? Colors.black
            : Colors.white;
    final TextStyle style = TextStyle(
      color: textColor,
      fontSize: 18.0,
      fontWeight: vicinity.column == 0 ? FontWeight.bold : null,
    );
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
              indexColor: Colors.purpleAccent,
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
    if (vicinity.column == 0) {
      int row = vicinity.row - 1;
      final vocalistName = snippetsForeachVocalist.entries.toList()[row].key;
      if (edittingVocalistIndex == row) {
        final TextEditingController controller =
            TextEditingController(text: vocalistName);
        oldVocalistName = vocalistName;
        return TableViewCell(
          child: TextField(
            controller: controller,
            focusNode: textFieldFocusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Editable Text',
            ),
            onSubmitted: (value) {
              edittingVocalistIndex = -1;
              if (oldVocalistName != value) {
                masterSubject
                    .add(RequestChangeVocalistName(oldVocalistName, value));
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
              setState(() {});
            },
            child: CustomPaint(
              painter: RectanglePainter(
                rect: Rect.fromLTRB(0.0, 0.0, 155, 60),
                sentence: snippetsForeachVocalist.entries
                    .toList()[row]
                    .value[row]
                    .vocalist,
                indexColor: indexColor(row),
                isSelected: selectingVocalist.contains(vocalistName),
              ),
            ),
          ),
        );
      }
    }

    int row = vicinity.row - 1;
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
              indexColor: indexColor(row),
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
    return TableSpan(
      extent: FixedTableSpanExtent(index == 0 ? 20 : 60),
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

  Color indexColor(int index) {
    switch (index) {
      case 0:
        return Colors.greenAccent;
      case 1:
        return Colors.blueAccent;
      case 2:
        return Colors.cyanAccent;
      case 3:
        return Colors.purpleAccent;
      case 4:
        return Colors.yellowAccent;
      case 5:
        return Colors.redAccent;
    }
    return Colors.black;
  }

  void _onFocusChange() {
    if (!textFieldFocusNode.hasFocus) {
      edittingVocalistIndex = -1;
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
