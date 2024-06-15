import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';
import 'scale_mark.dart';
import 'lyric_snippet.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:collection/collection.dart';

class RectanglePainter extends CustomPainter {
  final List<LyricSnippet> snippets;
  final double intervalLength;
  final int intervalDuration;
  final double topMargin;
  final double bottomMargin;
  final Color indexColor;

  RectanglePainter({
    required this.snippets,
    required this.intervalLength,
    required this.intervalDuration,
    required this.topMargin,
    required this.bottomMargin,
    required this.indexColor,
  });

  void paint(Canvas canvas, Size size) {
    final top = topMargin;
    final bottom = size.height - bottomMargin;

    snippets.forEach((LyricSnippet snippet) {
      final endtime = snippet.startTimestamp +
          snippet.timingPoints
              .map((point) => point.seekPosition)
              .reduce((a, b) => a + b);
      final left = snippet.startTimestamp * intervalLength / intervalDuration;
      final right = endtime * intervalLength / intervalDuration;
      final rect = Rect.fromLTRB(left, top, right, bottom);

      final mainPaint = Paint()..color = indexColor;
      canvas.drawRect(rect, mainPaint);

      final textSpan = TextSpan(
        text: snippet.sentence,
        style: TextStyle(
            color: ThemeData.estimateBrightnessForColor(indexColor) ==
                    Brightness.light
                ? Colors.black
                : Colors.white,
            fontSize: 16),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      );
      textPainter.layout(
        minWidth: 0,
        maxWidth: rect.width,
      );

      final offset = Offset(
        rect.left + (rect.width - textPainter.width) / 2,
        rect.top + (rect.height - textPainter.height) / 2,
      );

      textPainter.paint(canvas, offset);

      final double edgeWidth = 0.5;
      final lighterColor = _adjustColorBrightness(indexColor, 0.1);
      final darkerColor = _adjustColorBrightness(indexColor, -0.3);
      final borderRadius = 1.0;
      final leftInner = left + borderRadius;
      final topInner = top + borderRadius;
      final rightInner = right - borderRadius;
      final bottomInner = bottom - borderRadius;

      final lighterPath = Path()
        ..moveTo(left, top)
        ..lineTo(left, bottom)
        ..lineTo(leftInner, bottomInner)
        ..lineTo(leftInner, topInner)
        ..lineTo(rightInner, topInner)
        ..lineTo(right, top)
        ..lineTo(left, top);

      final lighterPaint = Paint()
        ..color = lighterColor
        ..strokeWidth = edgeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(lighterPath, lighterPaint);

      final darkerPath = Path()
        ..moveTo(right, bottom)
        ..lineTo(right, top)
        ..lineTo(rightInner, topInner)
        ..lineTo(rightInner, bottomInner)
        ..lineTo(leftInner, bottomInner)
        ..lineTo(left, bottom)
        ..lineTo(right, bottom);

      final darkerPaint = Paint()
        ..color = darkerColor
        ..strokeWidth = edgeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawPath(darkerPath, darkerPaint);
    });
  }

  Color _adjustColorBrightness(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final adjustedLightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    final hslAdjusted = hsl.withLightness(adjustedLightness);
    return hslAdjusted.toColor();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

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
  final CurrentPositionIndicatorDelegate delegate =
      CurrentPositionIndicatorDelegate();

  Map<String, List<LyricSnippet>> snippetsForeachVocalist = {};
  int audioDuration = 60000;
  int currentPosition = 0;
  final ScrollController currentPositionScroller = ScrollController();
  double intervalLength = 10.0;
  double majorMarkLength = 15.0;
  double midiumMarkLength = 11.0;
  double minorMarkLength = 8.0;
  int intervalDuration = 1000;

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {
      if (signal is NotifyAudioFileLoaded) {
        setState(() {
          audioDuration = signal.millisec;
        });
      }
      if (signal is NotifySeekPosition) {
        setState(() {
          currentPosition = signal.seekPosition;
        });
      }
      if (signal is NotifyLyricParsed) {
        setState(() {
          snippetsForeachVocalist = groupBy(signal.lyricSnippetList,
              (LyricSnippet snippet) => snippet.vocalist);
        });
      }
    });
    horizontalDetails.controller!.addListener(_onHorizontalScroll);
    currentPositionScroller.addListener(_onHorizontalScroll);
  }

  String defaultText = "Timeline Pane";

  @override
  Widget build(BuildContext context) {
    return Focus(
        focusNode: focusNode,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyK &&
              HardwareKeyboard.instance.logicalKeysPressed
                  .contains(LogicalKeyboardKey.controlLeft)) {
            debugPrint("timeline pane: zoom out");
            setState(() {
              intervalDuration = intervalDuration * 2;
            });
            return KeyEventResult.handled;
          }
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyJ &&
              HardwareKeyboard.instance.logicalKeysPressed
                  .contains(LogicalKeyboardKey.controlLeft)) {
            debugPrint("timeline pane: zoom in");
            setState(() {
              intervalDuration = intervalDuration ~/ 2;
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
            onTap: () {
              widget.masterSubject.add(RequestPlayPause());
              focusNode.requestFocus();
              debugPrint("The timeline pane is focused");
              setState(() {});
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
                          audioDuration * intervalLength / intervalDuration,
                          800),
                      painter: CurrentPositionIndicatorPainter(
                          x: currentPosition *
                              intervalLength /
                              intervalDuration),
                    ),
                  ),
                ),
              ),
            ])));
  }

  @override
  void dispose() {
    horizontalDetails.controller!.removeListener(_onHorizontalScroll);
    currentPositionScroller.removeListener(_onHorizontalScroll);
    horizontalDetails.controller!.dispose();
    currentPositionScroller.dispose();
    super.dispose();
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
        child: Container(
          child: Center(
            child: Text("function buttons"),
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
      return TableViewCell(
        child: ColoredBox(
          color: cell.color,
          child: Center(
            child: Text(
                snippetsForeachVocalist.entries.toList()[vicinity.row - 1].key,
                style: style),
          ),
        ),
      );
    }

    int row = vicinity.row - 1;
    if (row < snippetsForeachVocalist.length) {
      double topMargin = 0;
      double bottomMargin = 0;
      return TableViewCell(
        child: CustomPaint(
          painter: RectanglePainter(
            snippets: snippetsForeachVocalist.entries
                .toList()[vicinity.row - 1]
                .value,
            intervalLength: intervalLength,
            intervalDuration: intervalDuration,
            topMargin: topMargin,
            bottomMargin: bottomMargin,
            indexColor: indexColor(row),
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
      padding: const TableSpanPadding(leading: 10.0, trailing: 5.0),
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

class CurrentPositionIndicatorPainter extends CustomPainter {
  final double x;

  CurrentPositionIndicatorPainter({required this.x});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;

    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class CurrentPositionIndicatorDelegate extends TwoDimensionalChildDelegate {
  @override
  Widget? build(BuildContext context, ChildVicinity vicinity) {
    return Container(
      color: Colors.blue,
      child: Center(child: Text('Cell $vicinity.row, $vicinity.column')),
    );
  }

  @override
  int get rowCount => 6;

  @override
  int get columnCount => 2;

  @override
  bool shouldRebuild(covariant TwoDimensionalChildDelegate oldDelegate) {
    // TODO: implement shouldRebuild
    return false;
  }
}
