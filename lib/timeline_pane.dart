import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class MergeArea {
  int left;
  int top;
  int right;
  int bottom;

  MergeArea(this.left, this.top, this.right, this.bottom);
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

  List<MergeArea> merged = [
    MergeArea(1, 1, 2, 3),
    MergeArea(4, 4, 10, 4),
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
      columnCount: 40,
      pinnedColumnCount: 1,
      columnBuilder: _buildColumnSpan,
      rowCount: 52,
      pinnedRowCount: 1,
      rowBuilder: _buildRowSpan,
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
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
        columnMergeSpan: 39,
        child: Container(
          child: Center(
            child: Text("seek position mark"),
          ),
        ),
      );
    }
    if (vicinity.column == 0) {
      return TableViewCell(
        child: Container(
          child: Center(
            child: Text("artist name ${vicinity.row}"),
          ),
        ),
      );
    }
    final int colorIndex = ((vicinity.row - 1) / 3).floor();
    final ({String name, Color color}) cell = _getColorForVicinity(vicinity);
    final Color textColor =
        ThemeData.estimateBrightnessForColor(cell.color) == Brightness.light
            ? Colors.black
            : Colors.white;
    final TextStyle style = TextStyle(
      color: textColor,
      fontSize: 18.0,
      fontWeight: vicinity.column == 0 ? FontWeight.bold : null,
    );
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
    return TableViewCell(
      //rowMergeStart: vicinity.column == 0 ? (colorIndex * 3) + 1 : null,
      //rowMergeSpan: vicinity.column == 0 ? 3 : null,
      child: ColoredBox(
        color: cell.color,
        child: Center(
          child: Text(cell.name, style: style),
        ),
      ),
    );
  }

  TableSpan _buildColumnSpan(int index) {
    return TableSpan(
      extent: FixedTableSpanExtent(index == 0 ? 160 : 180),
      foregroundDecoration: index == 0
          ? const TableSpanDecoration(
              border: TableSpanBorder(
                trailing: BorderSide(
                  width: 5,
                  color: Colors.black,
                ),
              ),
            )
          : null,
    );
  }

  TableSpan _buildRowSpan(int index) {
    if (index == 0) {
      return const TableSpan(
        extent: FixedTableSpanExtent(20),
        foregroundDecoration: TableSpanDecoration(
          border: TableSpanBorder(
            trailing: BorderSide(
              width: 3,
              color: Colors.black,
            ),
          ),
        ),
      );
    }
    return TableSpan(
      extent: const FixedTableSpanExtent(60),
      padding:
          (index - 1) % 3 == 0 ? const TableSpanPadding(leading: 5.0) : null,
    );
  }

  ({String name, Color color}) _getColorForVicinity(TableVicinity vicinity) {
    final int colorIndex = ((vicinity.row - 1) / 3).floor();
    final MaterialColor primary = Colors.primaries[colorIndex];
    if (vicinity.column == 0) {
      // Leading primary color
      return (
        color: primary[500]!,
        name: '${_getPrimaryNameFor(colorIndex)}, 500',
      );
    }
    final int leadingRow = (colorIndex * 3) + 1;
    final int middleRow = leadingRow + 1;
    int? colorValue;
    if (vicinity.row == leadingRow) {
      colorValue = switch ((vicinity.column - 1) % 3) {
        0 => 50,
        1 => 100,
        2 => 200,
        _ => throw AssertionError('This should be unreachable.'),
      };
    } else if (vicinity.row == middleRow) {
      colorValue = switch ((vicinity.column - 1) % 3) {
        0 => 300,
        1 => 400,
        2 => 600,
        _ => throw AssertionError('This should be unreachable.'),
      };
    } else {
      // last row
      colorValue = switch ((vicinity.column - 1) % 3) {
        0 => 700,
        1 => 800,
        2 => 900,
        _ => throw AssertionError('This should be unreachable.'),
      };
    }
    return (color: primary[colorValue]!, name: colorValue.toString());
  }

  String _getPrimaryNameFor(int index) {
    return switch (index) {
      0 => 'Red',
      1 => 'Pink',
      2 => 'Purple',
      3 => 'DeepPurple',
      4 => 'Indigo',
      5 => 'Blue',
      6 => 'LightBlue',
      7 => 'Cyan',
      8 => 'Teal',
      9 => 'Green',
      10 => 'LightGreen',
      11 => 'Lime',
      12 => 'Yellow',
      13 => 'Amber',
      14 => 'Orange',
      15 => 'DeepOrange',
      16 => 'Brown',
      17 => 'BlueGrey',
      _ => throw AssertionError('This should be unreachable.'),
    };
  }
}
