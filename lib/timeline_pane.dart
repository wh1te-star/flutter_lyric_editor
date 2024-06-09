import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';
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
  bool isPlaying = true;
  int time = 0;

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {});
  }

  String defaultText = "Timeline Pane";

  Widget TwoDimensionalScrollWidget() {
    final ScrollController _verticalController = ScrollController();
    final ScrollController _horizontalController = ScrollController();

    return Listener(
      onPointerPanZoomStart: (PointerPanZoomStartEvent event) {
        debugPrint('trackpad scroll started');
      },
      onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
        debugPrint('trackpad scrolled ${event.panDelta}');
        _horizontalController
            .jumpTo(_horizontalController.offset - event.panDelta.dx);
        _verticalController
            .jumpTo(_verticalController.offset - event.panDelta.dy);
      },
      onPointerPanZoomEnd: (PointerPanZoomEndEvent event) {
        debugPrint('trackpad scroll ended');
      },
      child: TableView.builder(
        verticalDetails: ScrollableDetails.vertical(
          controller: _verticalController,
        ),
        horizontalDetails: ScrollableDetails.horizontal(
          controller: _horizontalController,
        ),
        cellBuilder: _buildCell,
        columnCount: 20,
        columnBuilder: _buildColumnSpan,
        rowCount: 10,
        rowBuilder: _buildRowSpan,
      ),
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final bool showBorder = ((vicinity.row + vicinity.column) % 2 == 0);
    final BorderSide transparentBorderSide = BorderSide(
      color: Colors.transparent,
      width: 3,
    );
    final BorderSide blackBorderSide = BorderSide(
      color: Colors.black,
      width: 3,
    );
    final Border transparentBorder = Border(
      top: transparentBorderSide,
      bottom: showBorder ? blackBorderSide : transparentBorderSide,
      left: transparentBorderSide,
      right: showBorder ? blackBorderSide : transparentBorderSide,
    );

    return TableViewCell(
      child: Container(
        decoration: BoxDecoration(
          border: transparentBorder,
        ),
        child: Center(
          child: Text('Tile c: ${vicinity.column}, r: ${vicinity.row}'),
        ),
      ),
    );
  }

  TableSpan _buildRowSpan(int index) {
    final TableSpanDecoration decoration = TableSpanDecoration(
      color: index.isEven ? Colors.purple[100] : null,
    );

    switch (index % 3) {
      case 0:
        return TableSpan(
          backgroundDecoration: decoration,
          extent: const FixedTableSpanExtent(50),
        );
      case 1:
        return TableSpan(
          backgroundDecoration: decoration,
          extent: const FixedTableSpanExtent(65),
          cursor: SystemMouseCursors.click,
        );
      case 2:
        return TableSpan(
          backgroundDecoration: decoration,
          extent: const FractionalTableSpanExtent(0.15),
        );
    }
    throw AssertionError(
      'This should be unreachable, as every index is accounted for in the '
      'switch clauses.',
    );
  }

  TableSpan _buildColumnSpan(int index) {
    switch (index % 5) {
      case 0:
        return TableSpan(
          extent: const FixedTableSpanExtent(100),
          onEnter: (_) => print('Entered column $index'),
        );
      case 1:
        return TableSpan(
          extent: const FractionalTableSpanExtent(0.5),
          onEnter: (_) => print('Entered column $index'),
          cursor: SystemMouseCursors.contextMenu,
        );
      case 2:
        return TableSpan(
          extent: const FixedTableSpanExtent(120),
          onEnter: (_) => print('Entered column $index'),
        );
      case 3:
        return TableSpan(
          extent: const FixedTableSpanExtent(145),
          onEnter: (_) => print('Entered column $index'),
        );
      case 4:
        return TableSpan(
          extent: const FixedTableSpanExtent(200),
          onEnter: (_) => print('Entered column $index'),
        );
    }
    throw AssertionError(
      'This should be unreachable, as every index is accounted for in the '
      'switch clauses.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          children: <Widget>[
            Container(
              height: 30,
              child: Row(
                children: <Widget>[
                  Container(width: 100, color: Colors.purple),
                  Expanded(child: Container(color: Colors.orange)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: <Widget>[
                  Container(width: 100, color: Colors.orangeAccent),
                  Expanded(child: TwoDimensionalScrollWidget()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
