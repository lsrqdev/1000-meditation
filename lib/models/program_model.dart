import 'package:shared_preferences/shared_preferences.dart';

import '../utils/date_helpers.dart';

/// Manages the 1000-day progressive meditation program logic.
///
/// The program consists of 9 phases with increasing daily targets:
/// - Phase 1: Days 1-30 → 3 minutes
/// - Phase 2: Days 31-90 → 5 minutes
/// - Phase 3: Days 91-180 → 7 minutes
/// - Phase 4: Days 181-300 → 10 minutes
/// - Phase 5: Days 301-450 → 12 minutes
/// - Phase 6: Days 451-650 → 15 minutes
/// - Phase 7: Days 651-800 → 20 minutes
/// - Phase 8: Days 801-900 → 25 minutes
/// - Phase 9: Days 901-1000 → 30 minutes
class ProgramModel {
  /// Creates a program model with the given preferences.
  ProgramModel(this._prefs);

  final SharedPreferences _prefs;

  static const _startKey = 'programStartDate';

  /// Total number of days in the program.
  static const totalProgramDays = 1000;

  /// Day caps for each phase (inclusive).
  static const phaseDayCaps = [
    30, // Phase 1 ends
    90, // Phase 2 ends
    180, // Phase 3 ends
    300, // Phase 4 ends
    450, // Phase 5 ends
    650, // Phase 6 ends
    800, // Phase 7 ends
    900, // Phase 8 ends
    totalProgramDays, // Phase 9 ends
  ];

  /// Target minutes for each phase.
  static const phaseMinutes = [3, 5, 7, 10, 12, 15, 20, 25, 30];

  /// Gets the program start date.
  ///
  /// If no start date is stored, initializes with today.
  DateTime get programStartDate {
    try {
      final stored = _prefs.getInt(_startKey);
      if (stored != null) {
        return DateTime.fromMillisecondsSinceEpoch(stored);
      }
      final today = DateHelpers.startOfLocalDay(DateTime.now());
      _prefs.setInt(_startKey, today.millisecondsSinceEpoch);
      return today;
    } catch (e) {
      // Fallback to today if preferences fail
      return DateHelpers.startOfLocalDay(DateTime.now());
    }
  }

  /// Sets the program start date.
  set programStartDate(DateTime date) {
    try {
      final normalized = DateHelpers.startOfLocalDay(date);
      _prefs.setInt(_startKey, normalized.millisecondsSinceEpoch);
    } catch (e) {
      // Silently fail - start date is not critical
    }
  }

  /// Returns the day index (1-based) since the program started.
  ///
  /// Returns 1 for the first day, 2 for the second, etc.
  /// If the given date is before the start date, returns 1.
  int dayIndexSinceStart(DateTime date) {
    final start = DateHelpers.startOfLocalDay(programStartDate);
    final current = DateHelpers.startOfLocalDay(date);
    final diff = current.difference(start).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  /// Returns the target minutes for the given date.
  int todayTargetMinutes(DateTime date) {
    final dayIndex = dayIndexSinceStart(date);
    return targetMinutesForDay(dayIndex);
  }

  /// Returns the target minutes for a specific day index.
  ///
  /// Uses [phaseDayCaps] to determine which phase the day falls into.
  int targetMinutesForDay(int dayIndex) {
    for (var index = 0; index < phaseDayCaps.length; index++) {
      if (dayIndex <= phaseDayCaps[index]) {
        return phaseMinutes[index];
      }
    }
    return phaseMinutes.last;
  }

  /// Returns the phase index (0-based) for a specific day index.
  int phaseIndexForDay(int dayIndex) {
    for (var index = 0; index < phaseDayCaps.length; index++) {
      if (dayIndex <= phaseDayCaps[index]) {
        return index;
      }
    }
    return phaseDayCaps.length - 1;
  }

  /// Returns the current phase index (0-based) for the given date.
  int currentPhaseIndex(DateTime date) {
    return phaseIndexForDay(dayIndexSinceStart(date));
  }

  /// Returns the target seconds for the given date.
  double todayTargetSeconds(DateTime date) {
    return todayTargetMinutes(date) * 60.0;
  }

  /// Returns the overall program progress as a value between 0.0 and 1.0.
  ///
  /// 0.0 = Day 1, 1.0 = Day 1000 (or beyond).
  double programProgress(DateTime date) {
    final dayIndex = dayIndexSinceStart(date);
    final progress = (dayIndex - 1) / (totalProgramDays - 1);
    return progress.clamp(0.0, 1.0);
  }

  /// Returns the phase progress (0.0 to 1.0) within the current phase.
  double phaseProgress(DateTime date) {
    final dayIndex = dayIndexSinceStart(date);
    final phaseIdx = phaseIndexForDay(dayIndex);

    final phaseStartDay = phaseIdx == 0 ? 1 : phaseDayCaps[phaseIdx - 1] + 1;
    final phaseEndDay = phaseDayCaps[phaseIdx];
    final daysInPhase = phaseEndDay - phaseStartDay + 1;
    final daysIntoPhase = dayIndex - phaseStartDay + 1;

    return (daysIntoPhase / daysInPhase).clamp(0.0, 1.0);
  }

  /// Returns true if the given day is the first day of a new phase.
  bool isPhaseStartDay(int dayIndex) {
    if (dayIndex == 1) return true;
    for (final cap in phaseDayCaps) {
      if (dayIndex == cap + 1) return true;
    }
    return false;
  }

  /// Returns the day count in the current phase for the given date.
  int daysIntoPhase(DateTime date) {
    final dayIndex = dayIndexSinceStart(date);
    final phaseIdx = phaseIndexForDay(dayIndex);
    final phaseStartDay = phaseIdx == 0 ? 1 : phaseDayCaps[phaseIdx - 1] + 1;
    return dayIndex - phaseStartDay + 1;
  }

  /// Returns the total days in the current phase for the given date.
  int totalDaysInPhase(DateTime date) {
    final dayIndex = dayIndexSinceStart(date);
    final phaseIdx = phaseIndexForDay(dayIndex);
    final phaseStartDay = phaseIdx == 0 ? 1 : phaseDayCaps[phaseIdx - 1] + 1;
    final phaseEndDay = phaseDayCaps[phaseIdx];
    return phaseEndDay - phaseStartDay + 1;
  }
}
