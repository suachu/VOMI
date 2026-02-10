import 'package:flutter/material.dart';

class ScreenFrame extends StatelessWidget {
  final Widget child;
  final Clip clipBehavior;
  final Color background;
  final double width;
  final double height;

  const ScreenFrame({
    super.key,
    required this.child,
    this.clipBehavior = Clip.antiAlias,
    this.background = const Color(0xFFF9F8F3),
    this.width = 402,
    this.height = 874,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        clipBehavior: clipBehavior,
        decoration: BoxDecoration(color: background),
        child: child,
      ),
    );
  }
}
