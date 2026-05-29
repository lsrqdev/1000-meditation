import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onetoten_mobile/models/program_model.dart';

void main() {
  group('ProgramModel', () {
    late SharedPreferences prefs;
    late ProgramModel model;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      model = ProgramModel(prefs);
    });

    group('programStartDate', () {
      test('initializes with today when no date is stored', () {
        final today = DateTime.now();
        final startDate = model.programStartDate;

        expect(startDate.year, today.year);
        expect(startDate.month, today.month);
        expect(startDate.day, today.day);
        expect(startDate.hour, 0);
        expect(startDate.minute, 0);
      });

      test('reads stored start date', () async {
        final storedDate = DateTime(2026, 1, 15);
        await prefs.setInt(
          'programStartDate',
          storedDate.millisecondsSinceEpoch,
        );

        final newModel = ProgramModel(prefs);
        expect(newModel.programStartDate, storedDate);
      });

      test('setting start date normalizes to midnight', () {
        final date = DateTime(2026, 3, 15, 14, 30, 45);
        model.programStartDate = date;

        final stored = model.programStartDate;
        expect(stored.year, 2026);
        expect(stored.month, 3);
        expect(stored.day, 15);
        expect(stored.hour, 0);
        expect(stored.minute, 0);
        expect(stored.second, 0);
      });
    });

    group('dayIndexSinceStart', () {
      test('returns 1 on start date', () {
        final startDate = DateTime(2026, 1, 1);
        model.programStartDate = startDate;

        expect(model.dayIndexSinceStart(startDate), 1);
      });

      test('returns 2 on day after start', () {
        final startDate = DateTime(2026, 1, 1);
        model.programStartDate = startDate;

        expect(model.dayIndexSinceStart(DateTime(2026, 1, 2)), 2);
      });

      test('returns 30 on day 30', () {
        final startDate = DateTime(2026, 1, 1);
        model.programStartDate = startDate;

        expect(model.dayIndexSinceStart(DateTime(2026, 1, 30)), 30);
      });

      test('returns 1 for dates before start', () {
        final startDate = DateTime(2026, 1, 15);
        model.programStartDate = startDate;

        expect(model.dayIndexSinceStart(DateTime(2026, 1, 10)), 1);
      });

      test('ignores time component', () {
        final startDate = DateTime(2026, 1, 1);
        model.programStartDate = startDate;

        final evening = DateTime(2026, 1, 5, 23, 59);
        expect(model.dayIndexSinceStart(evening), 5);
      });
    });

    group('targetMinutesForDay', () {
      test('returns 3 minutes for days 1-30', () {
        for (var day = 1; day <= 30; day++) {
          expect(model.targetMinutesForDay(day), 3, reason: 'Day $day');
        }
      });

      test('returns 5 minutes for days 31-90', () {
        for (var day = 31; day <= 90; day++) {
          expect(model.targetMinutesForDay(day), 5, reason: 'Day $day');
        }
      });

      test('returns 7 minutes for days 91-180', () {
        for (var day = 91; day <= 180; day++) {
          expect(model.targetMinutesForDay(day), 7, reason: 'Day $day');
        }
      });

      test('returns 10 minutes for days 181-300', () {
        expect(model.targetMinutesForDay(181), 10);
        expect(model.targetMinutesForDay(300), 10);
      });

      test('returns 12 minutes for days 301-450', () {
        expect(model.targetMinutesForDay(301), 12);
        expect(model.targetMinutesForDay(450), 12);
      });

      test('returns 15 minutes for days 451-650', () {
        expect(model.targetMinutesForDay(451), 15);
        expect(model.targetMinutesForDay(650), 15);
      });

      test('returns 20 minutes for days 651-800', () {
        expect(model.targetMinutesForDay(651), 20);
        expect(model.targetMinutesForDay(800), 20);
      });

      test('returns 25 minutes for days 801-900', () {
        expect(model.targetMinutesForDay(801), 25);
        expect(model.targetMinutesForDay(900), 25);
      });

      test('returns 30 minutes for days 901-1000', () {
        expect(model.targetMinutesForDay(901), 30);
        expect(model.targetMinutesForDay(1000), 30);
      });

      test('returns 30 minutes for days beyond 1000', () {
        expect(model.targetMinutesForDay(1001), 30);
        expect(model.targetMinutesForDay(2000), 30);
      });
    });

    group('phaseIndexForDay', () {
      test('returns 0 for phase 1 (days 1-30)', () {
        expect(model.phaseIndexForDay(1), 0);
        expect(model.phaseIndexForDay(30), 0);
      });

      test('returns 1 for phase 2 (days 31-90)', () {
        expect(model.phaseIndexForDay(31), 1);
        expect(model.phaseIndexForDay(90), 1);
      });

      test('returns 8 for phase 9 (days 901-1000)', () {
        expect(model.phaseIndexForDay(901), 8);
        expect(model.phaseIndexForDay(1000), 8);
      });

      test('returns 8 for days beyond 1000', () {
        expect(model.phaseIndexForDay(1500), 8);
      });
    });

    group('programProgress', () {
      test('returns 0.0 on day 1', () {
        model.programStartDate = DateTime(2026, 1, 1);
        expect(model.programProgress(DateTime(2026, 1, 1)), 0.0);
      });

      test('returns 1.0 on day 1000', () {
        model.programStartDate = DateTime(2026, 1, 1);
        expect(
          model.programProgress(DateTime(2028, 9, 27)),
          closeTo(1.0, 0.001),
        );
      });

      test('returns 0.5 at halfway point (day 500)', () {
        model.programStartDate = DateTime(2026, 1, 1);
        final day500 = DateTime(2026, 1, 1).add(const Duration(days: 499));
        expect(model.programProgress(day500), closeTo(0.499, 0.001));
      });

      test('clamps to 0.0 for dates before start', () {
        model.programStartDate = DateTime(2026, 1, 15);
        expect(model.programProgress(DateTime(2026, 1, 10)), 0.0);
      });

      test('clamps to 1.0 for dates after day 1000', () {
        model.programStartDate = DateTime(2026, 1, 1);
        final day1500 = DateTime(2026, 1, 1).add(const Duration(days: 1500));
        expect(model.programProgress(day1500), 1.0);
      });
    });

    group('phaseProgress', () {
      test('returns 0.0 at start of phase', () {
        model.programStartDate = DateTime(2026, 1, 1);
        // Day 31 is first day of phase 2
        expect(
          model.phaseProgress(DateTime(2026, 1, 31)),
          closeTo(0.016, 0.01),
        );
      });

      test('returns 1.0 at end of phase', () {
        model.programStartDate = DateTime(2026, 1, 1);
        // Day 30 is last day of phase 1
        expect(model.phaseProgress(DateTime(2026, 1, 30)), 1.0);
      });
    });

    group('isPhaseStartDay', () {
      test('returns true for day 1', () {
        expect(model.isPhaseStartDay(1), true);
      });

      test('returns true for first day of each phase', () {
        expect(model.isPhaseStartDay(31), true); // Phase 2
        expect(model.isPhaseStartDay(91), true); // Phase 3
        expect(model.isPhaseStartDay(901), true); // Phase 9
      });

      test('returns false for non-start days', () {
        expect(model.isPhaseStartDay(2), false);
        expect(model.isPhaseStartDay(30), false);
        expect(model.isPhaseStartDay(32), false);
      });
    });

    group('todayTargetMinutes', () {
      test('returns correct target for today', () {
        model.programStartDate = DateTime(2026, 1, 1);
        expect(model.todayTargetMinutes(DateTime(2026, 1, 1)), 3);
        expect(model.todayTargetMinutes(DateTime(2026, 1, 30)), 3);
        expect(model.todayTargetMinutes(DateTime(2026, 1, 31)), 5);
      });
    });

    group('todayTargetSeconds', () {
      test('returns minutes * 60', () {
        model.programStartDate = DateTime(2026, 1, 1);
        expect(model.todayTargetSeconds(DateTime(2026, 1, 1)), 180.0);
        expect(model.todayTargetSeconds(DateTime(2026, 1, 31)), 300.0);
      });
    });
  });
}
