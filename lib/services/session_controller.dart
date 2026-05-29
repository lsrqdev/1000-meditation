import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/program_model.dart';
import 'daily_completion_store.dart';
import 'haptic_service.dart';
import 'logging_service.dart';
import 'soundscape_service.dart';

/// Controls the meditation session lifecycle and timer state.
///
/// Manages:
/// - Session start/stop
/// - Timer tick updates
/// - Completion detection
/// - Session persistence across app restarts
/// - Completion animations and hold state
/// - 50% progress milestone
/// - Soundscape integration
///
/// Use [ListenableBuilder] or [AnimatedBuilder] to listen to state changes.
class SessionController extends ChangeNotifier {
  /// Creates a session controller.
  ///
  /// Automatically attempts to restore any active session from persistence.
  SessionController({
    required this.programModel,
    required this.completionStore,
    required SharedPreferences prefs,
  }) : _prefs = prefs {
    _restoreSessionIfNeeded();
  }

  final ProgramModel programModel;
  final DailyCompletionStore completionStore;
  final SharedPreferences _prefs;

  // Session state
  bool _isRunning = false;
  DateTime? _startDate;
  DateTime? _endDate;
  double _targetSeconds = 0;
  double _progressToFinish = 0;
  double _remainingSeconds = 0;
  double _completionPulse = 0;
  bool _completionHold = false;
  bool _completedTodayNotice = false;
  bool _fiftyPercentMilestoneReached = false;

  // Timers
  Timer? _timer;
  Timer? _completionPulseTimer;
  Timer? _completionHoldTimer;
  Timer? _completedNoticeTimer;

  // Lifecycle
  bool _isDisposed = false;

  // Persistence keys
  static const _sessionActiveKey = 'sessionActive';
  static const _sessionStartKey = 'sessionStart';
  static const _sessionEndKey = 'sessionEnd';
  static const _sessionTargetKey = 'sessionTarget';

  // Getters
  /// Whether a session is currently running.
  bool get isRunning => _isRunning;

  /// The start time of the current session, or null if not running.
  DateTime? get startDate => _startDate;

  /// The scheduled end time of the current session, or null if not running.
  DateTime? get endDate => _endDate;

  /// The target duration in seconds for the current session.
  double get targetSeconds => _targetSeconds;

  /// Current progress toward completion (0.0 to 1.0).
  double get progressToFinish => _progressToFinish;

  /// Seconds remaining in the session.
  double get remainingSeconds => _remainingSeconds;

  /// Animation value for completion pulse (0.0 to 1.0).
  double get completionPulse => _completionPulse;

  /// Whether the completion hold animation is active.
  bool get completionHold => _completionHold;

  /// Whether to show the "already completed today" notice.
  bool get completedTodayNotice => _completedTodayNotice;

  /// Toggles the session state (start if stopped, stop if running).
  void toggleSession() {
    if (_isRunning) {
      _stopSession(userInitiated: true);
    } else {
      _startSession();
    }
  }

  /// Resets all session state to initial values.
  ///
  /// Cancels any active timers and clears persistence.
  void resetSessionState() {
    _cancelScheduledNotifications();
    _stopTimer();
    _isRunning = false;
    _startDate = null;
    _endDate = null;
    _targetSeconds = 0;
    _remainingSeconds = 0;
    _progressToFinish = 0;
    _completionPulse = 0;
    _completionHold = false;
    _completedTodayNotice = false;
    _fiftyPercentMilestoneReached = false;
    _persistSession(active: false);
    _safeNotify();

    // Stop soundscape
    SoundscapeService.instance.stop();

    LoggingService.instance.info('Session state reset');
  }

  /// Refreshes the session state based on current time.
  ///
  /// Should be called when the app resumes from background.
  void refresh() {
    if (_isRunning) {
      _tick();
    }
  }

  // Session lifecycle

  void _startSession() {
    _cancelScheduledNotifications();
    final now = DateTime.now();

    // Check if already completed today
    if (completionStore.isCompleted(now)) {
      _showCompletedTodayNotice();
      return;
    }

    // Calculate target duration
    final target = programModel.todayTargetSeconds(now);

    _startDate = now;
    _endDate = now.add(Duration(milliseconds: (target * 1000).round()));
    _targetSeconds = target;
    _remainingSeconds = target;
    _isRunning = true;
    _progressToFinish = 0;
    _completionPulse = 0;
    _completionHold = false;
    _completedTodayNotice = false;
    _fiftyPercentMilestoneReached = false;

    _persistSession(active: true);
    _startTimer();
    _safeNotify();

    // Trigger haptic and soundscape
    HapticService.instance.sessionStart();
    SoundscapeService.instance.play();

    LoggingService.instance.info(
      'Session started',
      tag: 'SessionController',
      data: {'targetSeconds': target, 'targetMinutes': target / 60},
    );
  }

  void _stopSession({required bool userInitiated}) {
    if (!_isRunning) return;

    _cancelScheduledNotifications();
    final now = DateTime.now();
    final completed = _isEligibleCompletion(now);

    _isRunning = false;
    _stopTimer();
    _persistSession(active: false);

    // Stop soundscape
    SoundscapeService.instance.stop();

    if (completed) {
      _markCompletion(now);
      _progressToFinish = 1;
      _triggerCompletionPulse();
      LoggingService.instance.info(
        'Session completed',
        tag: 'SessionController',
      );
    } else {
      _progressToFinish = 0;
      _completionPulse = 0;
      _completionHold = false;
      _completedTodayNotice = false;
      _fiftyPercentMilestoneReached = false;
      SoundscapeService.instance.stopWebSessionAudio();
      if (userInitiated) {
        LoggingService.instance.info(
          'Session cancelled by user',
          tag: 'SessionController',
        );
      }
    }

    _startDate = null;
    _endDate = null;
    _targetSeconds = 0;
    _remainingSeconds = 0;
    _safeNotify();
  }

  // Timer management

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _tick();
    });
    _tick();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (!_isRunning || _startDate == null || _endDate == null) {
      return;
    }

    final now = DateTime.now();

    // Update progress
    if (_targetSeconds > 0) {
      final elapsed = now.difference(_startDate!).inMilliseconds / 1000.0;
      final progress = elapsed / _targetSeconds;
      _progressToFinish = progress.clamp(0.0, 1.0);

      // Check for 50% milestone
      if (!_fiftyPercentMilestoneReached && _progressToFinish >= 0.5) {
        _fiftyPercentMilestoneReached = true;
        HapticService.instance.progress50Percent();
        LoggingService.instance.debug(
          '50% milestone reached',
          tag: 'SessionController',
        );
      }
    } else {
      _progressToFinish = 0;
    }

    // Update remaining time
    _remainingSeconds = (_endDate!.difference(now).inMilliseconds / 1000.0)
        .clamp(0.0, 1e9);

    // Check for completion
    if (!now.isBefore(_endDate!)) {
      _stopSession(userInitiated: false);
      return;
    }

    _safeNotify();
  }

  // Completion handling

  bool _isEligibleCompletion(DateTime date) {
    if (_startDate == null || _targetSeconds <= 0) {
      return false;
    }
    return date.difference(_startDate!).inMilliseconds >=
        (_targetSeconds * 1000).round();
  }

  void _markCompletion(DateTime completionDate) {
    try {
      completionStore.setCompleted(true, completionDate);
    } catch (e) {
      LoggingService.instance.error(
        'Error marking completion',
        tag: 'SessionController',
        error: e,
      );
    }
  }

  void _triggerCompletionPulse() {
    const holdDuration = Duration(milliseconds: 1500);

    _completionPulse = 1;
    _completionHold = true;
    _safeNotify();

    // Trigger completion feedback (haptics and sound)
    HapticService.instance.sessionComplete();
    SoundscapeService.instance.playCompletionBell();
    LoggingService.instance.info(
      'Completion pulse triggered with sound',
      tag: 'SessionController',
    );

    // Pulse animation timer
    _completionPulseTimer?.cancel();
    _completionPulseTimer = Timer(const Duration(milliseconds: 220), () {
      if (_isRunning || _isDisposed) return;
      _completionPulse = 0;
      _safeNotify();
    });

    // Hold state timer
    _completionHoldTimer?.cancel();
    _completionHoldTimer = Timer(holdDuration, () {
      if (_isRunning || _isDisposed) return;
      _completionHold = false;
      _progressToFinish = 0;
      _safeNotify();
    });
  }

  void _showCompletedTodayNotice() {
    _completedTodayNotice = true;
    _safeNotify();

    _completedNoticeTimer?.cancel();
    _completedNoticeTimer = Timer(const Duration(seconds: 2), () {
      if (_isRunning || _isDisposed) return;
      _completedTodayNotice = false;
      _safeNotify();
    });
  }

  // Persistence

  void _persistSession({required bool active}) {
    try {
      _prefs.setBool(_sessionActiveKey, active);
      if (active && _startDate != null && _endDate != null) {
        _prefs.setInt(_sessionStartKey, _startDate!.millisecondsSinceEpoch);
        _prefs.setInt(_sessionEndKey, _endDate!.millisecondsSinceEpoch);
        _prefs.setDouble(_sessionTargetKey, _targetSeconds);
      } else {
        _prefs.remove(_sessionStartKey);
        _prefs.remove(_sessionEndKey);
        _prefs.remove(_sessionTargetKey);
      }
    } catch (e) {
      LoggingService.instance.error(
        'Error persisting session',
        tag: 'SessionController',
        error: e,
      );
    }
  }

  void _restoreSessionIfNeeded() {
    try {
      final isActive = _prefs.getBool(_sessionActiveKey) ?? false;
      if (!isActive) return;

      final storedStart = _prefs.getInt(_sessionStartKey);
      final storedEnd = _prefs.getInt(_sessionEndKey);
      if (storedStart == null || storedEnd == null) {
        _prefs.setBool(_sessionActiveKey, false);
        return;
      }

      final storedTarget = _prefs.getDouble(_sessionTargetKey) ?? 0;
      final now = DateTime.now();
      final storedStartDate = DateTime.fromMillisecondsSinceEpoch(storedStart);
      final storedEndDate = DateTime.fromMillisecondsSinceEpoch(storedEnd);

      // Session already ended while app was backgrounded
      if (!now.isBefore(storedEndDate)) {
        _startDate = storedStartDate;
        _endDate = storedEndDate;
        _targetSeconds = storedTarget;
        _markCompletion(storedEndDate);
        _prefs.setBool(_sessionActiveKey, false);
        _resetState();
        return;
      }

      // Restore active session
      _startDate = storedStartDate;
      _endDate = storedEndDate;
      _targetSeconds = storedTarget;
      _remainingSeconds =
          (storedEndDate.difference(now).inMilliseconds / 1000.0).clamp(
            0.0,
            1e9,
          );
      _isRunning = true;
      _startTimer();

      // Resume soundscape
      SoundscapeService.instance.play();

      LoggingService.instance.info(
        'Session restored',
        tag: 'SessionController',
      );
    } catch (e) {
      LoggingService.instance.error(
        'Error restoring session',
        tag: 'SessionController',
        error: e,
      );
    }
  }

  void _resetState() {
    _startDate = null;
    _endDate = null;
    _targetSeconds = 0;
    _progressToFinish = 0;
    _remainingSeconds = 0;
    _completionHold = false;
    _completedTodayNotice = false;
    _fiftyPercentMilestoneReached = false;
  }

  void _cancelScheduledNotifications() {
    _completionPulseTimer?.cancel();
    _completionPulseTimer = null;
    _completionHoldTimer?.cancel();
    _completionHoldTimer = null;
    _completedNoticeTimer?.cancel();
    _completedNoticeTimer = null;
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelScheduledNotifications();
    _stopTimer();
    SoundscapeService.instance.stop();
    super.dispose();
  }
}
