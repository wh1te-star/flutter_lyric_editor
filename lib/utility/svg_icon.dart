import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgIcon extends StatelessWidget {
  final String assetName;
  final Color iconColor;
  final Color backgroundColor;
  final double? width;
  final double? height;

  const SvgIcon({
    Key? key,
    required this.assetName,
    required this.iconColor,
    required this.backgroundColor,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.rectangle,
      ),
      child: SvgPicture.asset(
        assetName,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
      ),
    );
  }
}
