import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onetoten_mobile/widgets/weekly_progress_pill.dart';

void main() {
  group('WeeklyProgressPill', () {
    testWidgets('displays weekly completions and streak', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyProgressPill(
              weeklyCompletions: 5,
              weeklyTargetDays: 5,
              streakLength: 3,
              accentColor: Colors.teal,
            ),
          ),
        ),
      );

      // Check the widget renders
      expect(find.byType(WeeklyProgressPill), findsOneWidget);

      // Check for RichText (contains the formatted text)
      expect(find.byType(RichText), findsOneWidget);
    });

    testWidgets('renders with 1 day streak', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyProgressPill(
              weeklyCompletions: 1,
              weeklyTargetDays: 5,
              streakLength: 1,
              accentColor: Colors.teal,
            ),
          ),
        ),
      );

      expect(find.byType(WeeklyProgressPill), findsOneWidget);
    });

    testWidgets('renders with multi-day streak', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeeklyProgressPill(
              weeklyCompletions: 7,
              weeklyTargetDays: 7,
              streakLength: 7,
              accentColor: Colors.teal,
            ),
          ),
        ),
      );

      expect(find.byType(WeeklyProgressPill), findsOneWidget);
    });
  });
}
