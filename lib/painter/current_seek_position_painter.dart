import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CurrentSeekPositionPainter extends TwoDimensionalScrollView {
  final double x;
  final double height;

  const CurrentSeekPositionPainter({
    super.key,
    required this.x,
    required this.height,
    required super.delegate,
    required verticalDetails,
    required horizontalDetails,
  }) : super(
          verticalDetails: verticalDetails,
          horizontalDetails: horizontalDetails,
        );

  @override
  Widget buildViewport(BuildContext context, ViewportOffset verticalOffset, ViewportOffset horizontalOffset) {
    return Container(
      color: Colors.transparent,
    );
  }
}
