import 'package:flutter_test/flutter_test.dart';
import 'package:onetoten_mobile/utils/date_helpers.dart';

void main() {
  group('DateHelpers', () {
    group('dayKey', () {
      test('formats date as YYYY-MM-DD', () {
        final date = DateTime(2026, 3, 15);
        expect(DateHelpers.dayKey(date), '2026-03-15');
      });

      test('zero-pads month and day', () {
        final date = DateTime(2026, 1, 5);
        expect(DateHelpers.dayKey(date), '2026-01-05');
      });

      test('ignores time component', () {
        final morning = DateTime(2026, 3, 15, 8, 30);
        final evening = DateTime(2026, 3, 15, 20, 45);
        expect(DateHelpers.dayKey(morning), DateHelpers.dayKey(evening));
      });
    });

    group('startOfLocalDay', () {
      test('returns midnight of the given date', () {
        final date = DateTime(2026, 3, 15, 14, 30, 45);
        final start = DateHelpers.startOfLocalDay(date);

        expect(start.year, 2026);
        expect(start.month, 3);
        expect(start.day, 15);
        expect(start.hour, 0);
        expect(start.minute, 0);
        expect(start.second, 0);
        expect(start.millisecond, 0);
      });
    });

    group('dateByAddingDays', () {
      test('adds positive days', () {
        final date = DateTime(2026, 3, 15);
        final result = DateHelpers.dateByAddingDays(5, date);
        expect(result, DateTime(2026, 3, 20));
      });

      test('adds negative days', () {
        final date = DateTime(2026, 3, 15);
        final result = DateHelpers.dateByAddingDays(-5, date);
        expect(result, DateTime(2026, 3, 10));
      });

      test('handles month boundaries', () {
        final date = DateTime(2026, 3, 30);
        final result = DateHelpers.dateByAddingDays(5, date);
        expect(result, DateTime(2026, 4, 4));
      });
    });

    group('last7Dates', () {
      test('returns 7 dates ending with given date', () {
        final today = DateTime(2026, 3, 20);
        final dates = DateHelpers.last7Dates(today);

        expect(dates.length, 7);
        expect(DateHelpers.isSameDay(dates.last, today), true);
        expect(DateHelpers.isSameDay(dates.first, DateTime(2026, 3, 14)), true);
      });

      test('all dates are at midnight', () {
        final today = DateTime(2026, 3, 20, 15, 30);
        final dates = DateHelpers.last7Dates(today);

        for (final date in dates) {
          expect(date.hour, 0);
          expect(date.minute, 0);
        }
      });

      test('dates are consecutive', () {
        final today = DateTime(2026, 3, 20);
        final dates = DateHelpers.last7Dates(today);

        for (var i = 1; i < dates.length; i++) {
          final diff = dates[i].difference(dates[i - 1]).inDays;
          expect(diff, 1);
        }
      });
    });

    group('datesInRange', () {
      test('returns inclusive range', () {
        final start = DateTime(2026, 3, 15);
        final end = DateTime(2026, 3, 20);
        final dates = DateHelpers.datesInRange(start, end);

        expect(dates.length, 6);
        expect(DateHelpers.isSameDay(dates.first, start), true);
        expect(DateHelpers.isSameDay(dates.last, end), true);
      });

      test('handles same start and end', () {
        final date = DateTime(2026, 3, 15);
        final dates = DateHelpers.datesInRange(date, date);

        expect(dates.length, 1);
        expect(DateHelpers.isSameDay(dates.first, date), true);
      });
    });

    group('formatRemaining', () {
      test('formats seconds correctly', () {
        expect(DateHelpers.formatRemaining(65), '1:05');
        expect(DateHelpers.formatRemaining(60), '1:00');
        expect(DateHelpers.formatRemaining(59), '0:59');
        expect(DateHelpers.formatRemaining(0), '0:00');
      });

      test('rounds up', () {
        expect(DateHelpers.formatRemaining(65.1), '1:06');
        expect(
          DateHelpers.formatRemaining(65.9),
          '1:06',
        ); // ceil rounds 65.9 to 66
      });

      test('clamps negative to 0', () {
        expect(DateHelpers.formatRemaining(-10), '0:00');
      });

      test('handles large values', () {
        expect(DateHelpers.formatRemaining(3661), '61:01');
      });
    });

    group('formatDuration', () {
      test('formats minutes only', () {
        expect(DateHelpers.formatDuration(const Duration(minutes: 45)), '45m');
      });

      test('formats hours only', () {
        expect(DateHelpers.formatDuration(const Duration(hours: 2)), '2h');
      });

      test('formats hours and minutes', () {
        expect(
          DateHelpers.formatDuration(const Duration(hours: 1, minutes: 30)),
          '1h 30m',
        );
      });
    });

    group('formatDate', () {
      test('formats as MMM d, yyyy', () {
        expect(DateHelpers.formatDate(DateTime(2026, 3, 15)), 'Mar 15, 2026');
        expect(DateHelpers.formatDate(DateTime(2026, 12, 1)), 'Dec 1, 2026');
      });
    });

    group('isSameDay', () {
      test('returns true for same day', () {
        final a = DateTime(2026, 3, 15, 8, 0);
        final b = DateTime(2026, 3, 15, 20, 0);
        expect(DateHelpers.isSameDay(a, b), true);
      });

      test('returns false for different days', () {
        final a = DateTime(2026, 3, 15);
        final b = DateTime(2026, 3, 16);
        expect(DateHelpers.isSameDay(a, b), false);
      });
    });

    group('isToday', () {
      test('returns true for today', () {
        expect(DateHelpers.isToday(DateTime.now()), true);
      });

      test('returns false for other days', () {
        expect(DateHelpers.isToday(DateTime(2026, 1, 1)), false);
      });
    });

    group('dayOfWeekShort', () {
      test('returns 3-letter day name', () {
        expect(DateHelpers.dayOfWeekShort(DateTime(2026, 3, 16)), 'Mon');
        expect(DateHelpers.dayOfWeekShort(DateTime(2026, 3, 17)), 'Tue');
        expect(DateHelpers.dayOfWeekShort(DateTime(2026, 3, 22)), 'Sun');
      });
    });

    group('dayOfWeekLetter', () {
      test('returns single letter', () {
        expect(DateHelpers.dayOfWeekLetter(DateTime(2026, 3, 16)), 'M');
        expect(DateHelpers.dayOfWeekLetter(DateTime(2026, 3, 17)), 'T');
      });
    });
  });
}
