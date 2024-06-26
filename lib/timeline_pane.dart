import 'dart:ui';

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
  final Rect rect;
  final String sentence;
  final Color indexColor;
  final bool isSelected;

  RectanglePainter({
    required this.rect,
    required this.sentence,
    required this.indexColor,
    required this.isSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mainPaint = Paint()..color = indexColor;
    canvas.drawRect(rect, mainPaint);

    final textSpan = TextSpan(
      text: sentence,
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
      rect.left + (rect.width - textPainter.width) / 2 - 1,
      rect.top + (rect.height - textPainter.height) / 2 - 1,
    );

    textPainter.paint(canvas, offset);

    final double edgeWidth = 1.5;
    final lighterColor = _adjustColorBrightness(indexColor, 0.1);
    final darkerColor = _adjustColorBrightness(indexColor, -0.3);
    final borderRadius = 1.0;
    final leftInner = rect.left + borderRadius;
    final topInner = rect.top + borderRadius;
    final rightInner = rect.right - borderRadius;
    final bottomInner = rect.bottom - borderRadius;

    final lighterPath = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(leftInner, bottomInner)
      ..lineTo(leftInner, topInner)
      ..lineTo(rightInner, topInner)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.left, rect.top);

    final lighterPaint = Paint()
      ..color = lighterColor
      ..strokeWidth = edgeWidth
      ..style = PaintingStyle.stroke;

    final darkerPath = Path()
      ..moveTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rightInner, topInner)
      ..lineTo(rightInner, bottomInner)
      ..lineTo(leftInner, bottomInner)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.right, rect.bottom);

    final darkerPaint = Paint()
      ..color = darkerColor
      ..strokeWidth = edgeWidth
      ..style = PaintingStyle.stroke;

    if (isSelected) {
      canvas.drawPath(lighterPath, darkerPaint);
      canvas.drawPath(darkerPath, lighterPaint);
    } else {
      canvas.drawPath(lighterPath, lighterPaint);
      canvas.drawPath(darkerPath, darkerPaint);
    }
  }

  Color _adjustColorBrightness(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final adjustedLightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    final hslAdjusted = hsl.withLightness(adjustedLightness);
    return hslAdjusted.toColor();
  }

  @override
  bool shouldRepaint(covariant RectanglePainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.sentence != sentence ||
        oldDelegate.indexColor != indexColor ||
        oldDelegate.isSelected != isSelected;
  }
}

class TrianglePainter extends CustomPainter {
  final double x;
  final double y;
  final double width;
  final double height;

  TrianglePainter({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    Path path = Path()
      ..moveTo(x, y)
      ..lineTo(x - width / 2, y - height)
      ..lineTo(x + width / 2, y - height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    return oldDelegate.x != x ||
        oldDelegate.y != y ||
        oldDelegate.width != width ||
        oldDelegate.height != height;
  }
}

class TimelinePainter extends CustomPainter {
  final List<LyricSnippet> snippets;
  final List<LyricSnippetID> selectingId;
  final double intervalLength;
  final int intervalDuration;
  final double topMargin;
  final double bottomMargin;
  final Color indexColor;

  TimelinePainter({
    required this.snippets,
    required this.selectingId,
    required this.intervalLength,
    required this.intervalDuration,
    required this.topMargin,
    required this.bottomMargin,
    required this.indexColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final top = topMargin;
    final bottom = size.height - bottomMargin;

    snippets.forEach((LyricSnippet snippet) {
      final endtime = snippet.startTimestamp +
          snippet.timingPoints
              .map((point) => point.wordDuration)
              .reduce((a, b) => a + b);
      final left = snippet.startTimestamp * intervalLength / intervalDuration;
      final right = endtime * intervalLength / intervalDuration;
      final rect = Rect.fromLTRB(left, top, right, bottom);

      final isSelected = selectingId.contains(snippet.id);
      final rectanglePainter = RectanglePainter(
        rect: rect,
        sentence: snippet.sentence,
        indexColor: indexColor,
        isSelected: isSelected,
      );
      rectanglePainter.paint(canvas, size);

      double x = snippet.startTimestamp * intervalLength / intervalDuration;
      snippet.timingPoints.forEach((TimingPoint timingPoint) {
        final trianglePainter = TrianglePainter(
          x: x,
          y: top,
          width: 5.0,
          height: 5.0,
        );
        trianglePainter.paint(canvas, size);
        x += timingPoint.wordDuration * intervalLength / intervalDuration;
      });
      final trianglePainter = TrianglePainter(
        x: x,
        y: top,
        width: 5.0,
        height: 5.0,
      );
      trianglePainter.paint(canvas, size);
    });
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.snippets != snippets ||
        oldDelegate.selectingId != selectingId ||
        oldDelegate.intervalLength != intervalLength ||
        oldDelegate.intervalDuration != intervalDuration ||
        oldDelegate.topMargin != topMargin ||
        oldDelegate.bottomMargin != bottomMargin ||
        oldDelegate.indexColor != indexColor;
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
        masterSubject
            .add(NotifyCurrentSnippets(getSnippetsAtCurrentSeekPosition()));
        setState(() {
          currentPosition = signal.seekPosition;
        });
      }
      if (signal is NotifyLyricParsed || signal is NotifySnippetMade) {
        setState(() {
          snippetsForeachVocalist = groupBy(signal.lyricSnippetList,
              (LyricSnippet snippet) => snippet.vocalist);
        });
      }
      if (signal is NotifySnippetMove) {
        setState(() {
          snippetsForeachVocalist = groupBy(signal.lyricSnippetList,
              (LyricSnippet snippet) => snippet.vocalist);
        });
      }
      if (signal is RequestTimelineZoomIn) {
        zoomIn();
      }
      if (signal is RequestTimelineZoomOut) {
        zoomOut();
      }
    });
    horizontalDetails.controller!.addListener(_onHorizontalScroll);
    currentPositionScroller.addListener(_onHorizontalScroll);
  }

  void zoomIn() {
    debugPrint("timeline pane: zoom In");
    setState(() {
      intervalDuration = intervalDuration * 2;
    });
  }

  void zoomOut() {
    debugPrint("timeline pane: zoom Out");
    setState(() {
      intervalDuration = intervalDuration ~/ 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
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

  List<LyricSnippet> getSnippetsAtCurrentSeekPosition() {
    List<LyricSnippet> currentSnippet = [];
    snippetsForeachVocalist.forEach((vocalist, snippets) {
      for (var snippet in snippets) {
        final endtime = snippet.startTimestamp +
            snippet.timingPoints
                .map((point) => point.wordDuration)
                .reduce((a, b) => a + b);
        if (snippet.startTimestamp <= currentPosition &&
            currentPosition <= endtime) {
          currentSnippet.add(snippet);
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
      int row = vicinity.row - 1;
      final vocalistName = snippetsForeachVocalist.entries.toList()[row].key;
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
                  masterSubject.add(NotifyDeselectingSnippet(snippet.id));
                } else {
                  selectingSnippet.add(snippet.id);
                  masterSubject.add(NotifySelectingSnippet(snippet.id));
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
  bool shouldRepaint(covariant CurrentPositionIndicatorPainter oldDelegate) {
    return oldDelegate.x != x;
  }
}
