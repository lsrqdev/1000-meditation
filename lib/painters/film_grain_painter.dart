import 'dart:ui';

import 'package:flutter/material.dart';

/// A custom painter that draws a film grain texture effect.
///
/// This painter creates a subtle noise texture by drawing random points
/// across the canvas. The number of points scales with the canvas area
/// to maintain consistent visual density.
class FilmGrainPainter extends CustomPainter {
  /// Creates a film grain painter.
  const FilmGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final area = size.width * size.height;
    // Scale point count with area, clamped to reasonable bounds
    final sampleCount = ((area / 1250).clamp(220, 900)).toInt();

    final brightPaint = Paint()
      ..color = Colors.white.withOpacity(0.045)
      ..strokeWidth = 1;

    final darkPaint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..strokeWidth = 1;

    // Use pseudo-random distribution for deterministic rendering
    for (var index = 0; index < sampleCount; index++) {
      final x = ((index * 73) % 997) / 997 * size.width;
      final y = ((index * 151 + 47) % 991) / 991 * size.height;
      final paint = index.isEven ? brightPaint : darkPaint;
      canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant FilmGrainPainter oldDelegate) => false;
}
