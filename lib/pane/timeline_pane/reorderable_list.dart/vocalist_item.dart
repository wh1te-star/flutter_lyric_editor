import 'package:flutter/material.dart';
import 'package:lyric_editor/utility/utility_functions.dart';

class VocalistItem extends StatefulWidget {
  late Color nonselectedColor;
  late Color selectedColor;
  final Color shadowColor = Colors.black38;

  final double width;
  final double height;
  final String sentence;
  final Color vocalistColor;

  VocalistItem({
    Key? key,
    required this.width,
    required this.height,
    required this.sentence,
    required this.vocalistColor,
  }) : super(key: key) {
    selectedColor = adjustColorBrightness(vocalistColor, 0.5);
    nonselectedColor = vocalistColor;
  }

  @override
  _RippleColorContainerState createState() => _RippleColorContainerState();
}

class _RippleColorContainerState extends State<VocalistItem> {
  bool _selected = false;

  @override
  void initState() {
    super.initState();
  }

  void changeColor() {
    _selected = !_selected;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius effectiveBorderRadius = BorderRadius.circular(1.0);

    final Color currentBackgroundColor = _selected ? widget.selectedColor : widget.nonselectedColor;

    final Color splashAndHighlightColor = _selected ? widget.nonselectedColor : widget.selectedColor;

    return Container(
      decoration: BoxDecoration(
        color: currentBackgroundColor,
        borderRadius: effectiveBorderRadius,
        boxShadow: [
          BoxShadow(
            color: widget.shadowColor.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 0.5,
            offset: const Offset(0.5, 0.5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          onTap: changeColor,
          splashColor: splashAndHighlightColor,
          borderRadius: effectiveBorderRadius,
          child: Ink(
            width: widget.width,
            height: widget.height,
            child: Text(
              widget.sentence,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: determineBlackOrWhite(widget.vocalistColor), fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
