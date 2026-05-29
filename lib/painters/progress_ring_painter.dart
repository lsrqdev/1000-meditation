import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A custom painter that draws a circular progress ring.
///
/// Displays a track ring and a progress arc that fills as the session
/// progresses. The progress is displayed as an arc from 12 o'clock position.
class ProgressRingPainter extends CustomPainter {
  /// Creates a progress ring painter.
  ProgressRingPainter({
    required this.progress,
    required this.lineWidth,
    required this.trackOpacity,
    required this.progressOpacity,
    required this.accentColor,
  });

  /// Current progress value between 0.0 and 1.0.
  final double progress;

  /// The width of the ring stroke.
  final double lineWidth;

  /// Opacity for the track (background) ring.
  final double trackOpacity;

  /// Opacity for the progress arc.
  final double progressOpacity;

  /// The accent color for the progress arc.
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(trackOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = accentColor.withOpacity(progressOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    // Draw track ring
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi * 2,
      false,
      trackPaint,
    );

    // Draw progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        math.pi * 2 * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.lineWidth != lineWidth ||
        oldDelegate.trackOpacity != trackOpacity ||
        oldDelegate.progressOpacity != progressOpacity ||
        oldDelegate.accentColor != accentColor;
  }
}
