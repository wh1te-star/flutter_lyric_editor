import 'package:flutter/material.dart';

class AdjustablePaneBorder extends StatefulWidget {
  final Widget textPane;
  final Widget timelinePane;
  final Widget videoPane;

  AdjustablePaneBorder({
    Key? key,
    required this.videoPane,
    required this.textPane,
    required this.timelinePane,
  }) : super(key: key);

  @override
  _AdjustablePaneBorderState createState() => _AdjustablePaneBorderState();
}

class _AdjustablePaneBorderState extends State<AdjustablePaneBorder> {
  double videoPaneHeight = 400;
  double textPaneHeight = 50;

  @override
  Widget build(BuildContext context) {
    Widget videoTextPaneBorder = GestureDetector(
      child: Container(
        height: 10,
        color: Colors.grey,
      ),
      onVerticalDragUpdate: (details) {
        videoPaneHeight += details.delta.dy;
        setState(() {});
      },
    );
    Widget textTimelinePaneBorder = GestureDetector(
      child: Container(
        height: 10,
        color: Colors.grey,
      ),
      onVerticalDragUpdate: (details) {
        textPaneHeight += details.delta.dy;
        setState(() {});
      },
    );
    return Column(
      children: [
        Container(
          height: videoPaneHeight,
          child: widget.videoPane,
        ),
        videoTextPaneBorder,
        Container(
          height: textPaneHeight,
          child: widget.textPane,
        ),
        textTimelinePaneBorder,
        Expanded(
          child: Container(
            child: widget.timelinePane,
          ),
        ),
      ],
    );
  }
}
