import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../visual_spec.dart';

/// A pill-shaped widget displaying weekly completion stats and current streak.
///
/// Shows "This week X/Y" and "Streak Y days" with accent color highlighting
/// for the completion count.
class WeeklyProgressPill extends StatelessWidget {
  /// Creates a weekly progress pill.
  const WeeklyProgressPill({
    super.key,
    required this.weeklyCompletions,
    required this.weeklyTargetDays,
    required this.streakLength,
    required this.accentColor,
  });

  /// Number of completed days this week.
  final int weeklyCompletions;

  /// Number of elapsed days in the current week.
  final int weeklyTargetDays;

  /// Current consecutive day streak.
  final int streakLength;

  /// Accent color for highlighting completion count.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: VisualSpec.surface.withOpacity(0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VisualSpec.hairWithOpacity(1.35), width: 1),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.manrope(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: VisualSpec.ink.withOpacity(0.84),
            letterSpacing: 2.2,
          ),
          children: [
            TextSpan(
              text: '$weeklyCompletions/$weeklyTargetDays',
              style: TextStyle(color: VisualSpec.ink.withOpacity(0.96)),
            ),
            const TextSpan(text: ' WK · '),
            TextSpan(text: '$streakLength DAY STREAK'),
          ],
        ),
      ),
    );
  }
}
