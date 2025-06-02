import 'package:flutter/material.dart';
import 'package:lyric_editor/pane/timeline_pane/top_title/function_cell.dart';
import 'package:lyric_editor/pane/timeline_pane/top_title/scale_mark.dart';
import 'package:lyric_editor/position/seek_position/absolute_seek_position.dart';

class TopTitle extends StatelessWidget {
  AbsoluteSeekPosition seekPosition;
  Duration audioDuration;
  double intervalLength;
  int intervalDuration;
  ScrollController scrollController;
  double pinnedWidth;
  double height;

  TopTitle({
    required this.seekPosition,
    required this.audioDuration,
    required this.intervalLength,
    required this.intervalDuration,
    required this.scrollController,
    this.pinnedWidth = 155,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: pinnedWidth,
          height: height,
          child: FunctionCell(seekPosition),
        ),
        Container(
          width: 5,
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: Colors.black,
                width: 5,
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey("Scale Mark"),
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: audioDuration.inMilliseconds * intervalLength / intervalDuration,
              height: height,
              child: CustomPaint(
                size: Size(audioDuration.inMilliseconds * intervalLength / intervalDuration, height),
                painter: ScaleMark(
                  intervalLength: intervalLength,
                  intervalDuration: intervalDuration,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
