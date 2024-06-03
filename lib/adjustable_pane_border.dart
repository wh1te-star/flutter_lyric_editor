import 'package:flutter/material.dart';


class AdjustablePaneBorder extends StatelessWidget {
  final Widget child;
  final Function onHorizontalDragUpdate;
  final Function onVerticalDragUpdate;

  AdjustablePaneBorder({
    required this.child,
    required this.onHorizontalDragUpdate,
    required this.onVerticalDragUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) => onHorizontalDragUpdate(details),
      onVerticalDragUpdate: (details) => onVerticalDragUpdate(details),
      child: child,
    );
  }
}
