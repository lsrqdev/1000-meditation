import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A pill-shaped widget displaying weekly completion stats and current streak.
///
/// Shows "This week X/7" and "Streak Y days" with accent color highlighting
/// for the completion count.
class WeeklyProgressPill extends StatelessWidget {
  /// Creates a weekly progress pill.
  const WeeklyProgressPill({
    super.key,
    required this.weeklyCompletions,
    required this.streakLength,
    required this.accentColor,
  });

  /// Number of completed days this week (0-7).
  final int weeklyCompletions;

  /// Current consecutive day streak.
  final int streakLength;

  /// Accent color for highlighting completion count.
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final streakLabel = streakLength == 1 ? '1 day' : '$streakLength days';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.88),
            letterSpacing: 0.1,
          ),
          children: [
            const TextSpan(text: 'This week '),
            TextSpan(
              text: '$weeklyCompletions/7',
              style: TextStyle(color: accentColor.withOpacity(0.92)),
            ),
            const TextSpan(text: '  |  Streak '),
            TextSpan(text: streakLabel),
          ],
        ),
      ),
    );
  }
}
