import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onetoten_mobile/widgets/onboarding_overlay.dart';

void main() {
  group('OnboardingOverlay', () {
    testWidgets('displays onboarding text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingOverlay(accentColor: Colors.teal, onDismiss: () {}),
          ),
        ),
      );

      expect(find.textContaining('Build from 3 to 30 minutes'), findsOneWidget);
      expect(find.textContaining('Tap the orb'), findsOneWidget);
      expect(find.textContaining('Long-press'), findsOneWidget);
      expect(find.text('Begin'), findsOneWidget);
    });

    testWidgets('calls onDismiss when Begin is tapped', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingOverlay(
              accentColor: Colors.teal,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Begin'));
      expect(dismissed, true);
    });
  });
}
