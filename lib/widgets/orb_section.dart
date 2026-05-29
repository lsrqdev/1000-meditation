import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../visual_spec.dart';
import 'orb_view.dart';

/// The main interactive orb section containing the meditation orb.
///
/// This widget combines:
/// - The animated orb with parallax support
/// - Progress ring showing session progress
/// - Center numeral display (target minutes or countdown)
/// - Status text below the orb
/// - Tap and long-press gesture handling
class OrbSection extends StatelessWidget {
  /// Creates an orb section.
  const OrbSection({
    super.key,
    required this.orbCenter,
    required this.orbDiameter,
    required this.accentColor,
    required this.isRunning,
    required this.isCompletionHold,
    required this.progressToFinish,
    required this.completionPulse,
    required this.reduceMotion,
    required this.isLuminanceReduced,
    required this.parallaxOffset,
    required this.isPressed,
    required this.targetMinutes,
    required this.remainingSeconds,
    required this.statusText,
    required this.showCompletedNotice,
    required this.showCompletionCopy,
    required this.onTap,
    required this.onLongPress,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
  });

  // Layout
  final Offset orbCenter;
  final double orbDiameter;

  // Visual
  final Color accentColor;
  final bool reduceMotion;
  final bool isLuminanceReduced;
  final Offset parallaxOffset;

  // State
  final bool isRunning;
  final bool isCompletionHold;
  final double progressToFinish;
  final double completionPulse;
  final bool isPressed;
  final int targetMinutes;
  final double remainingSeconds;

  // Status
  final String? statusText;
  final bool showCompletedNotice;
  final bool showCompletionCopy;

  // Callbacks
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  Widget build(BuildContext context) {
    final remainingText = _formatRemaining(remainingSeconds);
    final numeralText = isRunning
        ? remainingText
        : (isCompletionHold ? '✓' : '$targetMinutes');
    final numeralSize = (isRunning || isCompletionHold)
        ? VisualSpec.runningNumeralSize(orbDiameter)
        : VisualSpec.idleNumeralSize(orbDiameter);
    final numeralOpacity = isLuminanceReduced ? 0.72 : 0.82;

    return Stack(
      children: [
        // Orb with gestures
        Positioned(
          left: orbCenter.dx - orbDiameter / 2,
          top: orbCenter.dy - orbDiameter / 2,
          child: RepaintBoundary(
            child: SizedBox(
              width: orbDiameter,
              height: orbDiameter,
              child: GestureDetector(
                onTapDown: (_) => onTapDown(),
                onTapUp: (_) => onTapUp(),
                onTapCancel: onTapCancel,
                onTap: onTap,
                onLongPress: onLongPress,
                child: OrbView(
                  isRunning: isRunning,
                  reduceMotion: reduceMotion,
                  isLuminanceReduced: isLuminanceReduced,
                  parallaxOffset: parallaxOffset,
                  isPressed: isPressed,
                  progressToFinish: progressToFinish,
                  completionPulse: completionPulse,
                  completionHold: isCompletionHold,
                  accentColor: accentColor,
                ),
              ),
            ),
          ),
        ),

        // Center numeral
        Positioned(
          left: orbCenter.dx - orbDiameter / 2,
          top: orbCenter.dy - orbDiameter / 2,
          child: RepaintBoundary(
            child: SizedBox(
              width: orbDiameter,
              height: orbDiameter,
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, isRunning ? 0 : -3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        numeralText,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: numeralSize,
                          height: 0.88,
                          fontWeight: FontWeight.w300,
                          color: VisualSpec.numeralInk.withOpacity(
                            numeralOpacity,
                          ),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (!isRunning && !isCompletionHold) ...[
                        const SizedBox(height: 8),
                        Text(
                          'MIN',
                          style: GoogleFonts.manrope(
                            fontSize: _clamp(9.0, orbDiameter * 0.044, 12.0),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.8,
                            color: VisualSpec.numeralInk.withOpacity(0.48),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Status text
        if (statusText != null)
          Positioned(
            left: 0,
            right: 0,
            top: orbCenter.dy + orbDiameter * 0.69,
            child: Text(
              statusText!,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: _clamp(10.0, orbDiameter * 0.045, 13.0),
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: VisualSpec.ink.withOpacity(
                  isLuminanceReduced ? 0.56 : 0.68,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatRemaining(double seconds) {
    var total = seconds.ceil();
    if (total < 0) total = 0;
    final minutes = total ~/ 60;
    final secs = total % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  double _clamp(double min, double value, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}
