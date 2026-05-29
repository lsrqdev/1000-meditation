import 'package:flutter/material.dart';

/// A custom painter that draws a gradient ring/oval.
///
/// Creates a subtle gradient ring with a linear gradient from the accent
/// color to transparent white, giving a refined ambient glow effect.
class RingGradientPainter extends CustomPainter {
  /// Creates a ring gradient painter.
  const RingGradientPainter({
    required this.lineWidth,
    required this.accentColor,
  });

  /// The width of the ring stroke.
  final double lineWidth;

  /// The accent color to use for the gradient start.
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withOpacity(0.25),
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;

    canvas.drawOval(rect.deflate(lineWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant RingGradientPainter oldDelegate) {
    return oldDelegate.lineWidth != lineWidth ||
        oldDelegate.accentColor != accentColor;
  }
}
