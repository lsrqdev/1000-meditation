import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

/// Persists user settings and app state.
///
/// Provides type-safe getters and setters for all user preferences.
/// All operations silently fail if storage is unavailable.
class SettingsStore {
  /// Creates a settings store with the given preferences.
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  // Keys
  static const _parallaxKey = 'parallaxEnabled';
  static const _hasSeenOnboardingKey = 'hasSeenOnboarding';
  static const _hasOpenedMenuKey = 'hasOpenedMenu';
  static const _remindersEnabledKey = 'remindersEnabled';
  static const _reminderTimeMinutesKey = 'reminderTimeMinutes';
  static const _lastReminderDayKey = 'lastReminderDay';
  static const _soundEnabledKey = 'soundEnabled';
  static const _hapticsEnabledKey = 'hapticsEnabled';
  static const _lastPhaseBadgeDayKey = 'lastPhaseBadgeDay';
  static const _restDaysEnabledKey = 'restDaysEnabled';
  static const _freezeStreaksCountKey = 'freezeStreaksCount';
  static const _freezeStreaksUsedKey = 'freezeStreaksUsed';
  static const _selectedSoundscapeKey = 'selectedSoundscape';

  // Parallax/motion effects
  bool get parallaxEnabled => _getBool(_parallaxKey, defaultValue: false);
  set parallaxEnabled(bool value) => _setBool(_parallaxKey, value);

  // Onboarding state
  bool get hasSeenOnboarding =>
      _getBool(_hasSeenOnboardingKey, defaultValue: false);
  set hasSeenOnboarding(bool value) => _setBool(_hasSeenOnboardingKey, value);

  bool get hasOpenedMenu => _getBool(_hasOpenedMenuKey, defaultValue: false);
  set hasOpenedMenu(bool value) => _setBool(_hasOpenedMenuKey, value);

  // Reminders
  bool get remindersEnabled =>
      _getBool(_remindersEnabledKey, defaultValue: false);
  set remindersEnabled(bool value) => _setBool(_remindersEnabledKey, value);

  int get reminderTimeMinutes =>
      _getInt(_reminderTimeMinutesKey, defaultValue: 480); // 8:00 AM
  set reminderTimeMinutes(int value) => _setInt(_reminderTimeMinutesKey, value);

  String? get lastReminderDay {
    try {
      return _prefs.getString(_lastReminderDayKey);
    } catch (e) {
      developer.log('Error reading lastReminderDay: $e', name: 'SettingsStore');
      return null;
    }
  }

  set lastReminderDay(String? value) {
    try {
      if (value == null) {
        _prefs.remove(_lastReminderDayKey);
      } else {
        _prefs.setString(_lastReminderDayKey, value);
      }
    } catch (e) {
      developer.log('Error setting lastReminderDay: $e', name: 'SettingsStore');
    }
  }

  // Sound and haptics
  bool get soundEnabled => _getBool(_soundEnabledKey, defaultValue: true);
  set soundEnabled(bool value) => _setBool(_soundEnabledKey, value);

  bool get hapticsEnabled => _getBool(_hapticsEnabledKey, defaultValue: true);
  set hapticsEnabled(bool value) => _setBool(_hapticsEnabledKey, value);

  // Phase badge tracking
  int? get lastPhaseBadgeDay {
    try {
      return _prefs.getInt(_lastPhaseBadgeDayKey);
    } catch (e) {
      developer.log(
        'Error reading lastPhaseBadgeDay: $e',
        name: 'SettingsStore',
      );
      return null;
    }
  }

  set lastPhaseBadgeDay(int? value) {
    try {
      if (value == null) {
        _prefs.remove(_lastPhaseBadgeDayKey);
      } else {
        _prefs.setInt(_lastPhaseBadgeDayKey, value);
      }
    } catch (e) {
      developer.log(
        'Error setting lastPhaseBadgeDay: $e',
        name: 'SettingsStore',
      );
    }
  }

  // Rest Days Feature - allow 1 rest day per week without breaking streak
  bool get restDaysEnabled => _getBool(_restDaysEnabledKey, defaultValue: true);
  set restDaysEnabled(bool value) => _setBool(_restDaysEnabledKey, value);

  // Streak Recovery - Freeze streak feature
  int get freezeStreaksAvailable =>
      _getInt(_freezeStreaksCountKey, defaultValue: 3);
  set freezeStreaksAvailable(int value) =>
      _setInt(_freezeStreaksCountKey, value);

  int get freezeStreaksUsed => _getInt(_freezeStreaksUsedKey, defaultValue: 0);
  set freezeStreaksUsed(int value) => _setInt(_freezeStreaksUsedKey, value);

  int get freezeStreaksRemaining => freezeStreaksAvailable - freezeStreaksUsed;

  // Soundscapes
  String get selectedSoundscape =>
      _getString(_selectedSoundscapeKey, defaultValue: 'silence');
  set selectedSoundscape(String value) =>
      _setString(_selectedSoundscapeKey, value);

  // Helper methods
  bool _getBool(String key, {required bool defaultValue}) {
    try {
      return _prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      developer.log('Error reading $key: $e', name: 'SettingsStore');
      return defaultValue;
    }
  }

  void _setBool(String key, bool value) {
    try {
      _prefs.setBool(key, value);
    } catch (e) {
      developer.log('Error writing $key: $e', name: 'SettingsStore');
    }
  }

  int _getInt(String key, {required int defaultValue}) {
    try {
      return _prefs.getInt(key) ?? defaultValue;
    } catch (e) {
      developer.log('Error reading $key: $e', name: 'SettingsStore');
      return defaultValue;
    }
  }

  void _setInt(String key, int value) {
    try {
      _prefs.setInt(key, value);
    } catch (e) {
      developer.log('Error writing $key: $e', name: 'SettingsStore');
    }
  }

  String _getString(String key, {required String defaultValue}) {
    try {
      return _prefs.getString(key) ?? defaultValue;
    } catch (e) {
      developer.log('Error reading $key: $e', name: 'SettingsStore');
      return defaultValue;
    }
  }

  void _setString(String key, String value) {
    try {
      _prefs.setString(key, value);
    } catch (e) {
      developer.log('Error writing $key: $e', name: 'SettingsStore');
    }
  }
}
