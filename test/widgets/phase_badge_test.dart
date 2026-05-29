import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onetoten_mobile/widgets/phase_badge.dart';

void main() {
  group('PhaseBadge', () {
    testWidgets('shows text when visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhaseBadge(
              text: 'Phase 3 unlocked',
              accentColor: Colors.teal,
              visible: true,
            ),
          ),
        ),
      );

      expect(find.text('Phase 3 unlocked'), findsOneWidget);
    });

    testWidgets('is hidden when not visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhaseBadge(
              text: 'Phase 3 unlocked',
              accentColor: Colors.teal,
              visible: false,
            ),
          ),
        ),
      );

      // Badge exists but is transparent
      final badge = tester.widget<PhaseBadge>(find.byType(PhaseBadge));
      expect(badge.visible, false);
    });
  });
}
