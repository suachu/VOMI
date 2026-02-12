import 'package:flutter/widgets.dart';

class FigmaScale {
  const FigmaScale._({
    required this.sx,
    required this.sy,
  });

  factory FigmaScale.fromContext(
    BuildContext context, {
    double designWidth = 402,
    double designHeight = 874,
  }) {
    final size = MediaQuery.of(context).size;
    return FigmaScale._(
      sx: size.width / designWidth,
      sy: size.height / designHeight,
    );
  }

  final double sx;
  final double sy;

  double x(double value) => value * sx;
  double y(double value) => value * sy;
}
