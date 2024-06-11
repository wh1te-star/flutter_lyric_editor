import 'dart:ffi';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';
import 'scale_mark.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class Sentence {
  int startTiming;
  int endTiming;
  Sentence(this.startTiming, this.endTiming);
}

class TimingPoints {
  final List<int> _points;

  TimingPoints(this._points);

  int operator [](int index) {
    if (index < 0 || index > _points.length + 2) {
      throw RangeError.index(index, _points, 'Index out of range');
    }
    if (index == 0) {
      return 0;
    }
    if (index == _points.length + 1) {
      return 10000;
    }
    return _points[index - 1];
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

  TimingPoints timingPoints = TimingPoints([1000, 2000, 3000]);
  List<Sentence> sentences = [
    Sentence(0, 2),
    Sentence(1, 3),
    Sentence(2, 4),
    Sentence(0, 3),
  ];

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {});
  }

  String defaultText = "Timeline Pane";

  @override
  Widget build(BuildContext context) {
    final ScrollController _verticalController = ScrollController();
    final ScrollController _horizontalController = ScrollController();

    return TableView.builder(
      diagonalDragBehavior: DiagonalDragBehavior.free,
      cellBuilder: _buildCell,
      columnCount: timingPoints._points.length + 2,
      pinnedColumnCount: 1,
      columnBuilder: _buildColumnSpan,
      rowCount: 6,
      pinnedRowCount: 1,
      rowBuilder: _buildRowSpan,
    );
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
        columnMergeStart: 1,
        columnMergeSpan: timingPoints._points.length + 1,
        child: CustomPaint(
          painter: ScaleMark(
              interval: 10.0,
              majorMarkLength: 15.0,
              midiumMarkLength: 11.0,
              minorMarkLength: 8.0),
        ),
      );
    }
    if (vicinity.column == 0) {
      return TableViewCell(
        child: ColoredBox(
          color: cell.color,
          child: Center(
            child: Text(cell.name, style: style),
          ),
        ),
      );
    }
    /*
    for (int i = 0; i < merged.length; i++) {
      if (merged[i].top <= vicinity.row &&
          vicinity.row <= merged[i].bottom &&
          merged[i].left <= vicinity.column &&
          vicinity.column <= merged[i].right) {
      return TableViewCell(
          rowMergeStart: merged[i].top,
          rowMergeSpan: merged[i].bottom - merged[i].top + 1,
          columnMergeStart: merged[i].left,
          columnMergeSpan: merged[i].right - merged[i].left + 1,
          child: ColoredBox(
            color: Colors.white,
            child: Center(
              child: Text("merged"),
            ),
          ),
        );
      }
    }
    */
    return TableViewCell(
      child: ColoredBox(
        color: cell.color,
        child: Center(
          child: Text(cell.name, style: style),
        ),
      ),
    );
  }

  TableSpan _buildColumnSpan(int index) {
    double extent = 0;
    if (index == 0) {
      extent = 160;
    } else {
      extent = (timingPoints[index] - timingPoints[index - 1]).toDouble();
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
      padding: const TableSpanPadding(leading: 10.0),
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
}
