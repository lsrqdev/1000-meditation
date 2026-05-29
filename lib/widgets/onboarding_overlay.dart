import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../visual_spec.dart';

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
    return SizedBox.expand(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: VisualSpec.bgFloor.withOpacity(0.78),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Build from 3 to 30 minutes over 1000 days.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 35,
                            height: 1.04,
                            fontWeight: FontWeight.w300,
                            color: VisualSpec.ink.withOpacity(0.96),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: 56,
                          height: 1,
                          color: VisualSpec.hairWithOpacity(1.8),
                        ),
                        const SizedBox(height: 24),
                        _buildInstructionRow(
                          icon: Icons.touch_app_outlined,
                          text: 'Tap the orb to begin',
                        ),
                        const SizedBox(height: 12),
                        _buildInstructionRow(
                          icon: Icons.touch_app_outlined,
                          text: 'Long-press for menu',
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: VisualSpec.ink.withOpacity(0.94),
                              foregroundColor: VisualSpec.bg,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            onPressed: onDismiss,
                            child: Text(
                              'Begin',
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
        Icon(icon, size: 18, color: VisualSpec.ink.withOpacity(0.72)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            softWrap: true,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: VisualSpec.ink.withOpacity(0.82),
            ),
          ),
        ),
      ],
    );
  }
}
