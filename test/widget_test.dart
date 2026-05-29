import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onetoten_mobile/main.dart';

void main() {
  group('ThousandApp', () {
    testWidgets('Shows onboarding on first launch', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(ThousandApp(prefs: prefs));
      await tester.pump();

      expect(find.textContaining('Build from 3 to 30 minutes'), findsOneWidget);
      expect(find.textContaining('Tap the orb'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('Skips onboarding when already seen', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(ThousandApp(prefs: prefs));
      await tester.pump();

      // Onboarding should not be visible
      expect(find.textContaining('Build from 3 to 30 minutes'), findsNothing);

      // Main screen elements should be visible
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
