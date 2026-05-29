import 'dart:developer' as developer;

import 'package:flutter/services.dart';

/// Provides enhanced haptic feedback for meditation sessions.
///
/// Offers distinct haptic patterns for:
/// - Session start
/// - 50% progress milestone
/// - Session completion
/// - Reminder notifications
class HapticService {
  HapticService._();

  /// The singleton instance.
  static final HapticService instance = HapticService._();

  bool _enabled = true;

  /// Whether haptics are enabled.
  bool get enabled => _enabled;
  set enabled(bool value) => _enabled = value;

  /// Triggers the session start haptic pattern.
  ///
  /// A light, welcoming pattern to signal the beginning of meditation.
  void sessionStart() {
    if (!_enabled) return;

    try {
      // Light impact followed by selection click
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.selectionClick();
      });
      developer.log('Session start haptic', name: 'HapticService');
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }

  /// Triggers the 50% progress haptic pattern.
  ///
  /// A subtle double-tap to indicate halfway point.
  void progress50Percent() {
    if (!_enabled) return;

    try {
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.lightImpact();
      });
      developer.log('50% progress haptic', name: 'HapticService');
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }

  /// Triggers the session completion haptic pattern.
  ///
  /// A celebratory pattern: medium impact + success notification.
  void sessionComplete() {
    if (!_enabled) return;

    try {
      // Success pattern
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.lightImpact();
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        HapticFeedback.selectionClick();
      });
      developer.log('Session complete haptic', name: 'HapticService');
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }

  /// Triggers a reminder notification haptic.
  void reminder() {
    if (!_enabled) return;

    try {
      HapticFeedback.lightImpact();
      developer.log('Reminder haptic', name: 'HapticService');
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }

  /// Triggers a button tap haptic (light feedback).
  void buttonTap() {
    if (!_enabled) return;

    try {
      HapticFeedback.selectionClick();
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }

  /// Triggers an important action haptic (medium feedback).
  void importantAction() {
    if (!_enabled) return;

    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }

  /// Triggers an error/warning haptic.
  void warning() {
    if (!_enabled) return;

    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }

  /// Triggers a rest day used haptic pattern.
  void restDayUsed() {
    if (!_enabled) return;

    try {
      // Gentle pattern to acknowledge rest day
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.selectionClick();
      });
      developer.log('Rest day haptic', name: 'HapticService');
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }

  /// Triggers a streak frozen haptic pattern.
  void streakFrozen() {
    if (!_enabled) return;

    try {
      // Ice-like pattern: light tap, pause, confirmation
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
      Future.delayed(const Duration(milliseconds: 250), () {
        HapticFeedback.selectionClick();
      });
      developer.log('Streak frozen haptic', name: 'HapticService');
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }

  /// Triggers a phase milestone haptic pattern.
  void phaseMilestone() {
    if (!_enabled) return;

    try {
      // Celebratory pattern for new phase
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.lightImpact();
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.lightImpact();
      });
      Future.delayed(const Duration(milliseconds: 350), () {
        HapticFeedback.selectionClick();
      });
      developer.log('Phase milestone haptic', name: 'HapticService');
    } catch (e) {
      developer.log('Error triggering haptic: $e', name: 'HapticService');
    }
  }
}
