import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'signal_structure.dart';
import 'scale_mark.dart';
import 'lyric_snippet.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

class RectanglePainter extends CustomPainter {
  final LyricSnippet snippet;
  final double intervalLength;
  final int intervalDuration;
  final double topMargin;
  final double bottomMargin;
  final Color indexColor;

  RectanglePainter({
    required this.snippet,
    required this.intervalLength,
    required this.intervalDuration,
    required this.topMargin,
    required this.bottomMargin,
    required this.indexColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    final left = snippet.startTimestamp * intervalLength / intervalDuration;
    final right = snippet.endTimestamp * intervalLength / intervalDuration;
    final top = topMargin;
    final bottom = size.height - bottomMargin;

    paint.color = indexColor;

    final rect = Rect.fromLTRB(left, top, right, bottom);
    canvas.drawRect(rect, paint);

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

  List<LyricSnippet> snippets = [
    LyricSnippet(sentence: "abc", startTimestamp: 15000, endTimestamp: 45000),
    LyricSnippet(sentence: "def", startTimestamp: 30000, endTimestamp: 60000),
    LyricSnippet(sentence: "xyz", startTimestamp: 4500, endTimestamp: 60000),
    LyricSnippet(sentence: "あいう", startTimestamp: 60000, endTimestamp: 100000),
    LyricSnippet(
        sentence:
            "〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐〇✕△☐",
        startTimestamp: 80000,
        endTimestamp: 100000),
  ];
  int audioDuration = 60000;
  final double intervalLength = 10.0;
  final double majorMarkLength = 15.0;
  final double midiumMarkLength = 11.0;
  final double minorMarkLength = 8.0;
  final int intervalDuration = 1000;

  @override
  void initState() {
    super.initState();
    masterSubject.stream.listen((signal) {
      if (signal is NotifyAudioFileLoaded) {
        setState(() {
          audioDuration = signal.millisec;
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
      columnCount: 2,
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
            child: Text(cell.name, style: style),
          ),
        ),
      );
    }

    int row = vicinity.row - 1;
    int column = vicinity.column - 1;
    double topMargin = 0;
    double bottomMargin = 0;
    return TableViewCell(
      child: CustomPaint(
        painter: RectanglePainter(
          snippet: snippets[row],
          intervalLength: intervalLength,
          intervalDuration: intervalDuration,
          topMargin: topMargin,
          bottomMargin: bottomMargin,
          indexColor: indexColor(row),
        ),
      ),
    );
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
}
