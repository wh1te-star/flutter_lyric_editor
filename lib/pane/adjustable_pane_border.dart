import 'package:flutter/material.dart';

class AdjustablePaneBorder extends StatelessWidget {
  final Widget textPane;
  final Widget timelinePane;
  final Widget videoPane;

  AdjustablePaneBorder({
    required this.videoPane,
    required this.textPane,
    required this.timelinePane,
  });

  @override
  Widget build(BuildContext context) {
    /*
          return AdjustablePaneBorder(
        child: Container(
          width: horizontalBorderWidth,
          color: Colors.grey,
        ),
        onHorizontalDragUpdate: (details) {
          setState(() {
            if (details.delta.dx > 0) {
              LeftUpperPaneWidth += details.delta.dx;
            } else {
              if (LeftUpperPaneWidth > videoPaneWidthlimit) {
                LeftUpperPaneWidth += details.delta.dx;
              } else {
                LeftUpperPaneWidth = videoPaneWidthlimit;
              }
            }
          });
        },
        },
        */
    return Column(
  children: [
    Expanded(
        child: videoPane,
    ),
    Expanded(
        child: textPane,
    ),
    Expanded(
      child: Container(
        child: timelinePane,
      ),
    ),
  ],
);;
  }
}
