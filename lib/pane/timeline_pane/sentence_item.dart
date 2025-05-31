import 'package:flutter/material.dart';

class SentenceItem extends StatefulWidget {
  final double width;
  final double height;
  final Color nonselectedColor;
  final Color selectedColor;
  final Color shadowColor;
  final BorderRadius? borderRadius;
  final Widget? child;
  final VoidCallback? onTap;

  const SentenceItem({
    Key? key,
    this.width = 150.0,
    this.height = 100.0,
    this.nonselectedColor = Colors.deepPurple,
    this.selectedColor = Colors.purpleAccent,
    this.shadowColor = Colors.black38,
    this.borderRadius,
    this.child,
    this.onTap,
  }) : super(key: key);

  @override
  _RippleColorContainerState createState() => _RippleColorContainerState();
}

class _RippleColorContainerState extends State<SentenceItem> {
  bool _selected = false;

  @override
  void initState() {
    super.initState();
  }

  void _changeColor() {
    setState(() {
      _selected = !_selected;
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(12.0);

    final Color currentBackgroundColor = _selected ? widget.selectedColor : widget.nonselectedColor;

    final Color splashAndHighlightColor = _selected ? widget.nonselectedColor : widget.selectedColor;

    return Material(
      color: Colors.transparent,
      borderRadius: effectiveBorderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _changeColor,
        splashColor: splashAndHighlightColor,
        borderRadius: effectiveBorderRadius,
        child: Ink(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: currentBackgroundColor,
            borderRadius: effectiveBorderRadius,
            boxShadow: [
              BoxShadow(
                color: widget.shadowColor.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
