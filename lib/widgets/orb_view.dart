import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../painters/painters.dart';
import '../visual_spec.dart';

/// An animated meditation orb with levitation, breathing, and progress effects.
///
/// The orb features:
/// - Levitation animation (subtle up/down floating)
/// - Breathing animation (subtle scale pulsing)
/// - Progress ring showing session completion
/// - Completion celebration effects
/// - Parallax offset for interactive 3D effect
class OrbView extends StatefulWidget {
  /// Creates an orb view.
  const OrbView({
    super.key,
    required this.isRunning,
    required this.reduceMotion,
    required this.parallaxOffset,
    required this.isPressed,
    required this.progressToFinish,
    required this.completionPulse,
    required this.completionHold,
    required this.accentColor,
    this.isLuminanceReduced = false,
  });

  /// Whether a meditation session is currently running.
  final bool isRunning;

  /// Whether to reduce motion for accessibility.
  final bool reduceMotion;

  /// Whether to reduce luminance for accessibility.
  final bool isLuminanceReduced;

  /// Parallax offset for interactive 3D effect.
  final Offset parallaxOffset;

  /// Whether the orb is currently being pressed.
  final bool isPressed;

  /// Session progress from 0.0 to 1.0.
  final double progressToFinish;

  /// Completion pulse animation value from 0.0 to 1.0.
  final double completionPulse;

  /// Whether the completion hold animation is active.
  final bool completionHold;

  /// Accent color for progress ring and completion effects.
  final Color accentColor;

  @override
  State<OrbView> createState() => _OrbViewState();
}

class _OrbViewState extends State<OrbView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: (VisualSpec.levitationPeriod * 1000).round(),
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final diameter = math.min(constraints.maxWidth, constraints.maxHeight);
        final orbStack = _buildOrbStack(diameter);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final time = _controller.value * 2 * math.pi;
            final amplitude = VisualSpec.levitationAmplitude(
              constraints.maxHeight,
            );

            // Levitation effect (disabled for accessibility)
            final levitation =
                (widget.reduceMotion || widget.isLuminanceReduced)
                ? 0.0
                : (math.sin(time) * amplitude +
                      math.sin(time * 0.5) * amplitude * 0.25);

            // Breathing effect (different for running vs idle)
            final breath = (widget.reduceMotion || widget.isLuminanceReduced)
                ? 1.0
                : (widget.isRunning
                      ? 1.0 + math.sin(time) * 0.007
                      : (widget.completionHold
                            ? 1.0
                            : 1.0 + math.sin(time * 0.6) * 0.012));

            // Press feedback
            final pressScale = widget.isPressed ? 0.985 : 1.0;

            // Completion settle animation
            final settleScale = widget.completionHold ? 1.025 : 1.0;

            return Transform.translate(
              offset: Offset(0, levitation),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                scale: settleScale,
                child: Transform.scale(
                  scale: breath * pressScale,
                  child: child,
                ),
              ),
            );
          },
          child: orbStack,
        );
      },
    );
  }

  Widget _buildOrbStack(double diameter) {
    final completion = widget.completionPulse.clamp(0.0, 1.0).toDouble();
    final progress = widget.progressToFinish.clamp(0.0, 1.0).toDouble();
    final celebrationStrength = widget.completionHold ? 1.0 : completion;
    final ringDiameter = VisualSpec.progressRingDiameter(diameter);
    final ringLineWidth = VisualSpec.progressRingLineWidth(diameter);
    final ringTrackOpacity = widget.isLuminanceReduced ? 0.28 : 0.35;
    final ringProgressOpacity = widget.isLuminanceReduced ? 0.78 : 0.85;
    final completionScale = (widget.reduceMotion || widget.isLuminanceReduced)
        ? 1.0
        : 1.0 + 0.12 * completion;
    final checkScale = (widget.reduceMotion || widget.isLuminanceReduced)
        ? 1.0
        : 0.95 + 0.1 * completion;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Progress ring
        AnimatedOpacity(
          opacity: widget.isRunning || widget.completionHold ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          child: SizedBox(
            width: ringDiameter,
            height: ringDiameter,
            child: CustomPaint(
              painter: ProgressRingPainter(
                progress: progress,
                lineWidth: ringLineWidth,
                trackOpacity: ringTrackOpacity,
                progressOpacity: ringProgressOpacity,
                accentColor: widget.accentColor,
              ),
            ),
          ),
        ),

        // Celebration glow
        AnimatedOpacity(
          opacity: celebrationStrength,
          duration: const Duration(milliseconds: 220),
          child: Container(
            width: diameter * 1.2,
            height: diameter * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.accentColor.withOpacity(0.25),
                  blurRadius: diameter * 0.12,
                  spreadRadius: diameter * 0.02,
                ),
              ],
            ),
          ),
        ),

        // Orb body
        SizedBox(
          width: diameter,
          height: diameter,
          child: CustomPaint(
            painter: OrbBodyPainter(
              progress: progress,
              parallaxOffset: widget.parallaxOffset,
              accentColor: widget.accentColor,
              isLuminanceReduced: widget.isLuminanceReduced,
            ),
          ),
        ),

        // Completion ring
        Opacity(
          opacity: completion,
          child: Transform.scale(
            scale: completionScale,
            child: Container(
              width: diameter * 1.08,
              height: diameter * 1.08,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.accentColor.withOpacity(0.8 * completion),
                  width: diameter * 0.025,
                ),
              ),
            ),
          ),
        ),

        // Checkmark icon
        Opacity(
          opacity: completion,
          child: Transform.scale(
            scale: checkScale,
            child: Icon(
              Icons.check,
              size: diameter * 0.18,
              color: widget.accentColor.withOpacity(0.92),
            ),
          ),
        ),
      ],
    );
  }
}
