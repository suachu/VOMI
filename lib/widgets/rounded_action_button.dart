import 'package:flutter/material.dart';

class RoundedActionButton extends StatelessWidget {
  final double width;
  final double height;
  final String text;
  final Color background;
  final TextStyle textStyle;
  final double radius;
  final BorderSide? border;
  final VoidCallback? onTap;

  const RoundedActionButton({
    super.key,
    required this.width,
    required this.height,
    required this.text,
    required this.background,
    required this.textStyle,
    this.radius = 27,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: border ?? BorderSide.none,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: textStyle,
        ),
      ),
    );
  }
}
