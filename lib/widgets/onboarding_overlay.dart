import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// An onboarding overlay that appears on first app launch.
///
/// Explains the 1000-day meditation program and how to interact
/// with the app. Includes a "Got it" button to dismiss.
class OnboardingOverlay extends StatelessWidget {
  /// Creates an onboarding overlay.
  const OnboardingOverlay({
    super.key,
    required this.accentColor,
    required this.onDismiss,
  });

  /// Accent color for highlighting key text.
  final Color accentColor;

  /// Callback when the user dismisses the onboarding.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Build from 3 to 30 minutes in 1000 days.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: accentColor.withOpacity(0.95),
              ),
            ),
            const SizedBox(height: 12),
            _buildInstructionRow(
              icon: Icons.touch_app,
              text: 'Tap the orb to begin your session',
            ),
            const SizedBox(height: 8),
            _buildInstructionRow(
              icon: Icons.touch_app_outlined,
              text: 'Long-press for menu',
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: accentColor.withOpacity(0.2),
                foregroundColor: accentColor.withOpacity(0.95),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onDismiss,
              child: Text(
                'Got it',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionRow({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.85),
          ),
        ),
      ],
    );
  }
}
