import 'package:flutter/material.dart';

class SeekPositionIndicator extends StatelessWidget {
  final double seekPosition;

  const SeekPositionIndicator({
    Key? key,
    required this.seekPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allow positioned children to go outside bounds if needed
      children: <Widget>[
        Positioned(
          left: seekPosition,
          top: 0,
          bottom: 0, // Stretches the indicator vertically within the Stack's height
          child: Container(
            color: Colors.red,
            width: 2.0,
            // No height needed here if top and bottom are set in Positioned
            // If you want a fixed height, remove bottom:0 and set height here:
            // height: indicatorHeight,
          ),
        ),
      ],
    );
  }
}