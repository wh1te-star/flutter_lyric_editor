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
  int audioDuration;

  TimingPoints(this._points, this.audioDuration);

  int operator [](int index) {
    if (index < 0 || index > _points.length + 2) {
      throw RangeError.index(index, _points, 'Index out of range');
    }
    if (index == 0) {
      return 0;
    }
    if (index == _points.length + 1) {
      return audioDuration;
    }
    return _points[index - 1];
  }

  void updateAudioDuration(int newDuration) {
    audioDuration = newDuration;
  }

  List<int> get points => _points;
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

  late TimingPoints timingPoints;
  List<Sentence> sentences = [
    Sentence(0, 2),
    Sentence(1, 3),
    Sentence(2, 4),
    Sentence(0, 3),
    Sentence(1, 4),
  ];
  int audioDuration = 60000;

  @override
  void initState() {
    super.initState();
    timingPoints = TimingPoints([1000, 2000, 3000], audioDuration);
    masterSubject.stream.listen((signal) {
      if (signal is NotifyAudioFileLoaded) {
        setState(() {
          audioDuration = signal.millisec;
          timingPoints.updateAudioDuration(audioDuration);
        });
      }
    });
  }

  String defaultText = "Timeline Pane";

  @override
  Widget build(BuildContext context) {
    final ScrollController _verticalController = ScrollController();
    final ScrollController _horizontalController = ScrollController();

    return TableView.builder(
      diagonalDragBehavior: DiagonalDragBehavior.free,
      cellBuilder: _buildCell,
      columnCount: timingPoints.points.length + 2,
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
        columnMergeSpan: timingPoints.points.length + 1,
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

    int row = vicinity.row - 1;
    int column = vicinity.column - 1;
    if (sentences[row].startTiming <= column &&
        column < sentences[row].endTiming) {
      return TableViewCell(
        columnMergeStart: sentences[row].startTiming + 1,
        columnMergeSpan: sentences[row].endTiming - sentences[row].startTiming,
        child: ColoredBox(
          color: indexColor(row),
          child: Center(
            child: Text("merged"),
          ),
        ),
      );
    }
    return const TableViewCell(
      child: ColoredBox(
        color: Colors.white,
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
}
