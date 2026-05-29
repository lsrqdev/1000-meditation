import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/date_helpers.dart';

/// Persists daily meditation completion records.
///
/// Uses SharedPreferences to store completion status keyed by date.
/// Each completion is stored as a boolean with key format: `completion_YYYY-MM-DD`.
class DailyCompletionStore {
  /// Creates a completion store with the given preferences.
  DailyCompletionStore(this._prefs);

  final SharedPreferences _prefs;
  static const _prefix = 'completion_';
  static const _restDayPrefix = 'restday_';
  static const _frozenPrefix = 'frozen_';

  /// Checks if the given date has been completed.
  ///
  /// Returns false if no completion record exists or if an error occurs.
  bool isCompleted(DateTime date) {
    try {
      return _prefs.getBool(_key(date)) ?? false;
    } catch (e) {
      developer.log(
        'Error checking completion: $e',
        name: 'DailyCompletionStore',
      );
      return false;
    }
  }

  /// Sets the completion status for the given date.
  ///
  /// Silently fails if storage is unavailable.
  void setCompleted(bool completed, DateTime date) {
    try {
      _prefs.setBool(_key(date), completed);
    } catch (e) {
      developer.log(
        'Error setting completion: $e',
        name: 'DailyCompletionStore',
      );
    }
  }

  /// Checks if the given date is marked as a rest day.
  bool isRestDay(DateTime date) {
    try {
      return _prefs.getBool(_restDayKey(date)) ?? false;
    } catch (e) {
      developer.log(
        'Error checking rest day: $e',
        name: 'DailyCompletionStore',
      );
      return false;
    }
  }

  /// Marks a date as a rest day.
  ///
  /// Rest days don't break streaks but don't count as completions either.
  void setRestDay(DateTime date) {
    try {
      _prefs.setBool(_restDayKey(date), true);
    } catch (e) {
      developer.log('Error setting rest day: $e', name: 'DailyCompletionStore');
    }
  }

  /// Clears the rest day status for a date.
  void clearRestDay(DateTime date) {
    try {
      _prefs.remove(_restDayKey(date));
    } catch (e) {
      developer.log(
        'Error clearing rest day: $e',
        name: 'DailyCompletionStore',
      );
    }
  }

  /// Checks if the given date has a frozen streak.
  bool isFrozen(DateTime date) {
    try {
      return _prefs.getBool(_frozenKey(date)) ?? false;
    } catch (e) {
      developer.log('Error checking frozen: $e', name: 'DailyCompletionStore');
      return false;
    }
  }

  /// Freezes the streak for a date.
  ///
  /// Used by the streak recovery feature to prevent streak breakage.
  void freezeStreak(DateTime date) {
    try {
      _prefs.setBool(_frozenKey(date), true);
    } catch (e) {
      developer.log('Error freezing streak: $e', name: 'DailyCompletionStore');
    }
  }

  /// Clears all completion records.
  ///
  /// Removes all keys starting with the completion prefix.
  Future<void> clearAll() async {
    try {
      final keys = _prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith(_prefix) ||
            key.startsWith(_restDayPrefix) ||
            key.startsWith(_frozenPrefix)) {
          await _prefs.remove(key);
        }
      }
    } catch (e) {
      developer.log(
        'Error clearing completions: $e',
        name: 'DailyCompletionStore',
      );
    }
  }

  /// Returns a list of all completed dates as ISO date strings.
  ///
  /// Useful for data export/backup.
  List<String> getAllCompletedDates() {
    try {
      final keys = _prefs.getKeys();
      return keys
          .where((key) => key.startsWith(_prefix))
          .where((key) => _prefs.getBool(key) == true)
          .map((key) => key.substring(_prefix.length))
          .toList();
    } catch (e) {
      developer.log(
        'Error getting completions: $e',
        name: 'DailyCompletionStore',
      );
      return [];
    }
  }

  /// Returns a list of all rest day dates.
  List<String> getAllRestDays() {
    try {
      final keys = _prefs.getKeys();
      return keys
          .where((key) => key.startsWith(_restDayPrefix))
          .where((key) => _prefs.getBool(key) == true)
          .map((key) => key.substring(_restDayPrefix.length))
          .toList();
    } catch (e) {
      developer.log(
        'Error getting rest days: $e',
        name: 'DailyCompletionStore',
      );
      return [];
    }
  }

  /// Returns the completion count for the last N days.
  ///
  /// [date] is the end date (inclusive), [days] is the number of days to check.
  int getCompletionCountForLastDays(DateTime date, int days) {
    var count = 0;
    for (var i = 0; i < days; i++) {
      final checkDate = date.subtract(Duration(days: i));
      if (isCompleted(checkDate)) {
        count++;
      }
    }
    return count;
  }

  /// Returns the number of rest days used in the current week (Monday-Sunday).
  int getRestDaysUsedThisWeek(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    var count = 0;

    for (var i = 0; i < 7; i++) {
      final checkDate = weekStart.add(Duration(days: i));
      if (isRestDay(checkDate)) {
        count++;
      }
    }
    return count;
  }

  /// Returns the current streak length ending on the given date.
  ///
  /// If [allowRestDays] is true, rest days don't break the streak.
  /// If [allowFrozen] is true, frozen days don't break the streak.
  int getStreakLength(
    DateTime date, {
    bool allowRestDays = true,
    bool allowFrozen = true,
  }) {
    var streak = 0;
    var checkDate = date;
    var restDaysInStreak = 0;

    while (true) {
      if (isCompleted(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (allowRestDays &&
          isRestDay(checkDate) &&
          restDaysInStreak < 1) {
        // Allow 1 rest day per week in streak calculation
        restDaysInStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (allowFrozen && isFrozen(checkDate)) {
        // Frozen days don't break streak
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Checks if a rest day is available for the current week.
  bool isRestDayAvailable(DateTime date) {
    return getRestDaysUsedThisWeek(date) < 1;
  }

  String _key(DateTime date) {
    return '$_prefix${DateHelpers.dayKey(date)}';
  }

  String _restDayKey(DateTime date) {
    return '$_restDayPrefix${DateHelpers.dayKey(date)}';
  }

  String _frozenKey(DateTime date) {
    return '$_frozenPrefix${DateHelpers.dayKey(date)}';
  }
}
