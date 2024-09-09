import 'package:flutter/material.dart';

class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final double size;

  const SquareIconButton({super.key, required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        icon: Icon(icon),
        iconSize: size * 0.6,
        onPressed: () {},
      ),
    );
  }
}
