import 'package:flutter/material.dart';

import '../visual_spec.dart';

/// A custom painter that draws the main meditation orb body.
///
/// Creates a 3D-like spherical orb with:
/// - Base gradient from light to dark gray
/// - Overlay shadow for depth
/// - Rim highlight for 3D effect
/// - Inner glow "soul" with accent color
/// - Parallax offset support for interactive motion
class OrbBodyPainter extends CustomPainter {
  /// Creates an orb body painter.
  OrbBodyPainter({
    required this.progress,
    required this.parallaxOffset,
    required this.accentColor,
    required this.isLuminanceReduced,
  });

  /// Current session progress (0.0 to 1.0).
  final double progress;

  /// Parallax offset for interactive 3D effect.
  final Offset parallaxOffset;

  /// Accent color for the orb's "soul" glow.
  final Color accentColor;

  /// Whether to reduce luminance for accessibility.
  final bool isLuminanceReduced;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = size.width;
    final center = Offset(diameter / 2, diameter / 2);
    final radius = diameter / 2;

    // Opacity values based on accessibility settings
    final rimLineWidth = diameter * (isLuminanceReduced ? 0.036 : 0.034);
    final rimInnerOpacity = isLuminanceReduced ? 0.22 : 0.18;
    final soulOpacity = isLuminanceReduced ? 0.22 : 0.38;
    final highlightOpacity = isLuminanceReduced ? 0.16 : 0.28;
    final overlayShade = isLuminanceReduced ? 0.08 : 0.14;

    final rect = Offset.zero & size;

    // Base gradient (warm pearl sphere)
    final baseGradient = RadialGradient(
      center: const Alignment(-0.6, -0.6),
      radius: 0.9,
      colors: VisualSpec.pearlGradient,
      stops: const [0.0, 0.58, 1.0],
    ).createShader(rect);

    final basePaint = Paint()..shader = baseGradient;
    canvas.drawCircle(center, radius, basePaint);

    // Overlay gradient for depth
    final overlayGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.black.withOpacity(0),
        Colors.black.withOpacity(overlayShade),
      ],
    ).createShader(rect);

    final overlayPaint = Paint()
      ..shader = overlayGradient
      ..blendMode = BlendMode.multiply;
    canvas.drawCircle(center, radius, overlayPaint);

    // Outer rim highlight
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          VisualSpec.ink.withOpacity(0.58),
          VisualSpec.bgFloor.withOpacity(0.08),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = rimLineWidth;
    canvas.drawCircle(center, radius - rimLineWidth / 2, rimPaint);

    // Inner rim line
    final innerRimPaint = Paint()
      ..color = VisualSpec.ink.withOpacity(rimInnerOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = diameter * 0.01;
    canvas.drawCircle(center, radius - rimLineWidth, innerRimPaint);

    // Soul (inner glow with parallax)
    final soulCenter = center + parallaxOffset;
    final soulRadius = diameter * (0.23 + progress.clamp(0.0, 1.0) * 0.08);
    final soulColor = isLuminanceReduced
        ? Color.lerp(accentColor, VisualSpec.bg, 0.28)!
        : accentColor;
    final soulGradient = RadialGradient(
      colors: [
        soulColor.withOpacity(0.72 * soulOpacity),
        soulColor.withOpacity(0.05 * soulOpacity),
      ],
    ).createShader(Rect.fromCircle(center: soulCenter, radius: soulRadius));

    canvas.saveLayer(rect, Paint());
    final soulPaint = Paint()
      ..shader = soulGradient
      ..blendMode = BlendMode.screen
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, diameter * 0.02);
    canvas.drawCircle(soulCenter, soulRadius, soulPaint);

    // Specular highlight
    final highlightPaint = Paint()
      ..color = VisualSpec.ink.withOpacity(highlightOpacity)
      ..blendMode = BlendMode.screen
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, diameter * 0.03);
    canvas.drawCircle(
      Offset(center.dx - diameter * 0.18, center.dy - diameter * 0.2),
      diameter * 0.115,
      highlightPaint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbBodyPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.parallaxOffset != parallaxOffset ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isLuminanceReduced != isLuminanceReduced;
  }
}
