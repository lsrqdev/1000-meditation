import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../visual_spec.dart';

/// An animated badge that appears when unlocking a new phase.
///
/// Slides down from the top with a fade-in animation and displays
/// the phase milestone achievement text.
class PhaseBadge extends StatelessWidget {
  /// Creates a phase badge.
  const PhaseBadge({
    super.key,
    required this.text,
    required this.accentColor,
    required this.visible,
  });

  /// The badge text to display (e.g., "Phase 3 unlocked • 5 min target").
  final String text;

  /// Accent color for the badge border and text.
  final Color accentColor;

  /// Whether the badge is currently visible.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, -0.25),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 260),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: VisualSpec.surface.withOpacity(0.74),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: VisualSpec.hairWithOpacity(1.6),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: VisualSpec.ink.withOpacity(0.88),
              letterSpacing: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}
