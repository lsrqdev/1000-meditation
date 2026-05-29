import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onetoten_mobile/services/daily_completion_store.dart';

void main() {
  group('DailyCompletionStore', () {
    late SharedPreferences prefs;
    late DailyCompletionStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      store = DailyCompletionStore(prefs);
    });

    group('isCompleted', () {
      test('returns false for unset dates', () {
        final date = DateTime(2026, 3, 15);
        expect(store.isCompleted(date), false);
      });

      test('returns true for completed dates', () {
        final date = DateTime(2026, 3, 15);
        store.setCompleted(true, date);
        expect(store.isCompleted(date), true);
      });

      test('returns false for incomplete dates', () {
        final date = DateTime(2026, 3, 15);
        store.setCompleted(false, date);
        expect(store.isCompleted(date), false);
      });

      test('different dates have independent state', () {
        final date1 = DateTime(2026, 3, 15);
        final date2 = DateTime(2026, 3, 16);

        store.setCompleted(true, date1);

        expect(store.isCompleted(date1), true);
        expect(store.isCompleted(date2), false);
      });

      test('ignores time component', () {
        final morning = DateTime(2026, 3, 15, 8, 0);
        final evening = DateTime(2026, 3, 15, 20, 0);

        store.setCompleted(true, morning);
        expect(store.isCompleted(evening), true);
      });
    });

    group('rest days', () {
      test('returns false for non-rest days', () {
        final date = DateTime(2026, 3, 15);
        expect(store.isRestDay(date), false);
      });

      test('returns true for rest days', () {
        final date = DateTime(2026, 3, 15);
        store.setRestDay(date);
        expect(store.isRestDay(date), true);
      });

      test('rest days are independent of completions', () {
        final date = DateTime(2026, 3, 15);
        store.setRestDay(date);

        expect(store.isRestDay(date), true);
        expect(store.isCompleted(date), false);
      });

      test('can clear rest day', () {
        final date = DateTime(2026, 3, 15);
        store.setRestDay(date);
        expect(store.isRestDay(date), true);

        store.clearRestDay(date);
        expect(store.isRestDay(date), false);
      });

      test('counts rest days used this week', () {
        // Monday of a week
        final monday = DateTime(2026, 3, 16);

        // Use rest day on Wednesday
        final wednesday = monday.add(const Duration(days: 2));
        store.setRestDay(wednesday);

        expect(store.getRestDaysUsedThisWeek(wednesday), 1);
      });

      test('rest day available when none used', () {
        final today = DateTime(2026, 3, 15);
        expect(store.isRestDayAvailable(today), true);
      });

      test('rest day not available when already used', () {
        final today = DateTime(2026, 3, 15);
        store.setRestDay(today);
        expect(store.isRestDayAvailable(today), false);
      });
    });

    group('freeze streak', () {
      test('returns false for non-frozen dates', () {
        final date = DateTime(2026, 3, 15);
        expect(store.isFrozen(date), false);
      });

      test('returns true for frozen dates', () {
        final date = DateTime(2026, 3, 15);
        store.freezeStreak(date);
        expect(store.isFrozen(date), true);
      });

      test('frozen days do not break streak', () {
        final today = DateTime(2026, 3, 17);
        final yesterday = DateTime(2026, 3, 16);

        // Complete yesterday
        store.setCompleted(true, yesterday);

        // Freeze today (didn't meditate)
        store.freezeStreak(today);

        // When checking streak from yesterday, today is frozen so it doesn't break
        // But since today is not completed, the streak from today is 0
        // The streak from yesterday includes the completed yesterday
        final streakYesterday = store.getStreakLength(
          yesterday,
          allowFrozen: true,
        );
        expect(streakYesterday, 1);
      });
    });

    group('streak calculation', () {
      test('counts consecutive days', () {
        final today = DateTime(2026, 3, 20);

        store.setCompleted(true, today);
        store.setCompleted(true, today.subtract(const Duration(days: 1)));
        store.setCompleted(true, today.subtract(const Duration(days: 2)));

        expect(store.getStreakLength(today), 3);
      });

      test('stops at gap', () {
        final today = DateTime(2026, 3, 20);

        store.setCompleted(true, today);
        // Gap on day -1
        store.setCompleted(true, today.subtract(const Duration(days: 2)));

        expect(store.getStreakLength(today), 1);
      });

      test('allows one rest day in streak when enabled', () {
        final today = DateTime(2026, 3, 20);
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));

        store.setCompleted(true, today);
        store.setRestDay(yesterday);
        store.setCompleted(true, dayBefore);

        expect(store.getStreakLength(today, allowRestDays: true), 2);
      });

      test('rest day breaks streak when not allowed', () {
        final today = DateTime(2026, 3, 20);
        final yesterday = today.subtract(const Duration(days: 1));
        final dayBefore = today.subtract(const Duration(days: 2));

        store.setCompleted(true, today);
        store.setRestDay(yesterday);
        store.setCompleted(true, dayBefore);

        expect(store.getStreakLength(today, allowRestDays: false), 1);
      });

      test('only allows one rest day per streak', () {
        final today = DateTime(2026, 3, 20);

        store.setCompleted(true, today);
        store.setRestDay(today.subtract(const Duration(days: 1)));
        store.setRestDay(
          today.subtract(const Duration(days: 2)),
        ); // Second rest day
        store.setCompleted(true, today.subtract(const Duration(days: 3)));

        expect(store.getStreakLength(today, allowRestDays: true), 1);
      });
    });

    group('clearAll', () {
      test('removes all completion records', () async {
        store.setCompleted(true, DateTime(2026, 3, 15));
        store.setRestDay(DateTime(2026, 3, 16));
        store.freezeStreak(DateTime(2026, 3, 17));

        await store.clearAll();

        expect(store.isCompleted(DateTime(2026, 3, 15)), false);
        expect(store.isRestDay(DateTime(2026, 3, 16)), false);
        expect(store.isFrozen(DateTime(2026, 3, 17)), false);
      });

      test('does not affect other preferences', () async {
        await prefs.setString('other_key', 'value');
        store.setCompleted(true, DateTime(2026, 3, 15));

        await store.clearAll();

        expect(prefs.getString('other_key'), 'value');
      });
    });

    group('getAllCompletedDates', () {
      test('returns empty list when no completions', () {
        expect(store.getAllCompletedDates(), isEmpty);
      });

      test('returns all completed dates', () {
        store.setCompleted(true, DateTime(2026, 3, 15));
        store.setCompleted(true, DateTime(2026, 3, 17));
        store.setCompleted(false, DateTime(2026, 3, 16));

        final completed = store.getAllCompletedDates();
        expect(completed.length, 2);
        expect(completed, contains('2026-03-15'));
        expect(completed, contains('2026-03-17'));
        expect(completed, isNot(contains('2026-03-16')));
      });
    });

    group('getAllRestDays', () {
      test('returns empty list when no rest days', () {
        expect(store.getAllRestDays(), isEmpty);
      });

      test('returns all rest day dates', () {
        store.setRestDay(DateTime(2026, 3, 15));
        store.setRestDay(DateTime(2026, 3, 22));

        final restDays = store.getAllRestDays();
        expect(restDays.length, 2);
        expect(restDays, contains('2026-03-15'));
        expect(restDays, contains('2026-03-22'));
      });
    });

    group('getCompletionCountForLastDays', () {
      test('counts completions in range', () {
        final endDate = DateTime(2026, 3, 20);

        // Complete 3 out of last 5 days
        store.setCompleted(true, DateTime(2026, 3, 16));
        store.setCompleted(true, DateTime(2026, 3, 18));
        store.setCompleted(true, DateTime(2026, 3, 20));

        expect(store.getCompletionCountForLastDays(endDate, 5), 3);
      });

      test('returns 0 when no completions', () {
        final endDate = DateTime(2026, 3, 20);
        expect(store.getCompletionCountForLastDays(endDate, 7), 0);
      });
    });

    group('getStreakLength', () {
      test('returns 0 when no recent completion', () {
        final today = DateTime(2026, 3, 20);
        expect(store.getStreakLength(today), 0);
      });

      test('returns 1 for single day streak', () {
        final today = DateTime(2026, 3, 20);
        store.setCompleted(true, today);
        expect(store.getStreakLength(today), 1);
      });

      test('counts consecutive days', () {
        final today = DateTime(2026, 3, 20);
        store.setCompleted(true, DateTime(2026, 3, 18));
        store.setCompleted(true, DateTime(2026, 3, 19));
        store.setCompleted(true, today);

        expect(store.getStreakLength(today), 3);
      });

      test('stops at gap in streak', () {
        final today = DateTime(2026, 3, 20);
        store.setCompleted(true, DateTime(2026, 3, 16)); // Gap on 17
        store.setCompleted(true, DateTime(2026, 3, 18));
        store.setCompleted(true, DateTime(2026, 3, 19));
        store.setCompleted(true, today);

        expect(store.getStreakLength(today), 3); // 18-20 only
      });
    });
  });
}
