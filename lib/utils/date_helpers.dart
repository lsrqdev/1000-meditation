/// Utility functions for date and time operations.
///
/// Provides consistent date formatting and calculation functions
/// used throughout the meditation app.
class DateHelpers {
  DateHelpers._(); // Prevent instantiation

  /// Formats a date as a sortable string key: 'YYYY-MM-DD'.
  ///
  /// This format is used for storage keys and ensures chronological sorting.
  static String dayKey(DateTime date) {
    final day = startOfLocalDay(date);
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final dayValue = day.day.toString().padLeft(2, '0');
    return '$year-$month-$dayValue';
  }

  /// Returns the start of the local day (midnight) for the given date.
  static DateTime startOfLocalDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns a new date by adding the specified number of days.
  static DateTime dateByAddingDays(int days, DateTime date) {
    return date.add(Duration(days: days));
  }

  /// Returns a list of the last 7 dates ending with the given date.
  ///
  /// The list is ordered from oldest to newest (index 0 = 6 days ago,
  /// index 6 = today).
  static List<DateTime> last7Dates(DateTime date) {
    final todayStart = startOfLocalDay(date);
    return List<DateTime>.generate(7, (index) {
      final offset = 6 - index;
      return dateByAddingDays(-offset, todayStart);
    });
  }

  /// Returns a list of dates for the given range.
  ///
  /// [start] is inclusive, [end] is inclusive.
  static List<DateTime> datesInRange(DateTime start, DateTime end) {
    final startDay = startOfLocalDay(start);
    final endDay = startOfLocalDay(end);
    final days = endDay.difference(startDay).inDays;

    return List<DateTime>.generate(days + 1, (index) {
      return dateByAddingDays(index, startDay);
    });
  }

  /// Formats remaining seconds as 'M:SS' for timer display.
  ///
  /// Example: 65 seconds → '1:05', 0 seconds → '0:00'
  static String formatRemaining(double seconds) {
    var total = seconds.ceil();
    if (total < 0) {
      total = 0;
    }
    final minutes = total ~/ 60;
    final secs = total % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  /// Formats a duration as a human-readable string.
  ///
  /// Example: 90 minutes → '1h 30m', 45 minutes → '45m'
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  /// Formats a date for display.
  ///
  /// Example: 'Jan 15, 2026'
  static String formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  /// Returns true if two dates are the same day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns true if the date is today.
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Returns the day of week name (short).
  ///
  /// Example: 'Mon', 'Tue', etc.
  static String dayOfWeekShort(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    // DateTime.weekday returns 1-7 (Monday-Sunday)
    return days[date.weekday - 1];
  }

  /// Returns the day of week name (single letter).
  ///
  /// Example: 'M', 'T', 'W', etc.
  static String dayOfWeekLetter(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }
}
