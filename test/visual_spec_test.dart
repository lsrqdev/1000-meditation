import 'package:flutter_test/flutter_test.dart';
import 'package:onetoten_mobile/visual_spec.dart';

void main() {
  group('VisualSpec', () {
    group('orbDiameter', () {
      test('returns 68% of smaller dimension within design bounds', () {
        expect(VisualSpec.orbDiameter(100, 200), 220.0);
        expect(VisualSpec.orbDiameter(400, 800), 272.0);
        expect(VisualSpec.orbDiameter(1000, 1000), 420.0);
      });
    });

    group('orbCenter', () {
      test('centers horizontally at 47% height', () {
        final center = VisualSpec.orbCenter(200, 400);
        expect(center.dx, 100.0); // 50% of 200
        expect(center.dy, 188.0); // 47% of 400
      });
    });

    group('clamp', () {
      test('returns value when within range', () {
        expect(VisualSpec.clamp(0, 5, 10), 5);
      });

      test('returns min when below range', () {
        expect(VisualSpec.clamp(0, -5, 10), 0);
      });

      test('returns max when above range', () {
        expect(VisualSpec.clamp(0, 15, 10), 10);
      });
    });

    group('deg2rad', () {
      test('converts degrees to radians', () {
        expect(VisualSpec.deg2rad(0), 0.0);
        expect(VisualSpec.deg2rad(180), closeTo(3.14159, 0.0001));
        expect(VisualSpec.deg2rad(360), closeTo(6.28318, 0.0001));
      });
    });

    group('dotsOpacity', () {
      test('returns higher opacity at low focus', () {
        expect(VisualSpec.dotsOpacity(0), closeTo(1.0, 0.01));
        expect(VisualSpec.dotsOpacity(0.5), closeTo(0.44, 0.01));
        expect(VisualSpec.dotsOpacity(1), closeTo(0.25, 0.01));
      });
    });

    group('backgroundOpacity', () {
      test('returns higher opacity at low focus', () {
        expect(VisualSpec.backgroundOpacity(0), closeTo(1.0, 0.01));
        expect(VisualSpec.backgroundOpacity(0.5), closeTo(0.39, 0.01));
        expect(VisualSpec.backgroundOpacity(1), closeTo(0.3, 0.01));
      });
    });

    group('phaseAccent', () {
      test('returns correct color for phase index', () {
        expect(VisualSpec.phaseAccent(0), VisualSpec.warmPhaseBase);
        expect(VisualSpec.phaseAccent(8), VisualSpec.ink);
      });

      test('clamps index to valid range', () {
        expect(VisualSpec.phaseAccent(-1), VisualSpec.warmPhaseBase);
        expect(VisualSpec.phaseAccent(100), VisualSpec.ink);
      });

      test('dims toward the background when luminance reduced', () {
        final normal = VisualSpec.phaseAccent(0);
        final reduced = VisualSpec.phaseAccent(0, isLuminanceReduced: true);
        expect(reduced.opacity, closeTo(1.0, 0.01));
        expect(reduced.computeLuminance(), lessThan(normal.computeLuminance()));
      });
    });

    group('phaseAccents', () {
      test('has 9 colors for 9 phases', () {
        expect(VisualSpec.phaseAccents.length, 9);
      });
    });
  });
}
