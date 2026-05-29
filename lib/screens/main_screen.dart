import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/program_model.dart';
import '../painters/painters.dart';
import '../services/services.dart';
import '../services/session_controller.dart';
import '../utils/date_helpers.dart';
import '../visual_spec.dart';
import '../week_dots_arc_view.dart';
import '../widgets/widgets.dart';
import 'statistics_screen.dart';

/// The main meditation screen.
///
/// Displays the interactive meditation orb, weekly progress,
/// and handles all user interactions including session control,
/// menu access, and phase milestone notifications.
class MainScreen extends StatefulWidget {
  /// Creates the main screen.
  const MainScreen({super.key, required this.prefs});

  /// Shared preferences instance for persistence.
  final SharedPreferences prefs;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Services
  late final ProgramModel _programModel;
  late final DailyCompletionStore _completionStore;
  late final SessionController _sessionController;
  late final SettingsStore _settingsStore;

  // UI State
  bool _parallaxEnabled = false;
  bool _hasSeenOnboarding = false;
  bool _hasOpenedMenu = false;
  bool _showProgramDayOverride = false;
  bool _isPressed = false;
  bool _remindersEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _restDaysEnabled = true;
  int _freezeStreaksRemaining = 3;
  String _selectedSoundscape = 'silence';

  // Parallax
  Offset _parallaxOffset = Offset.zero;

  // Phase badge
  bool _showPhaseBadge = false;
  String _phaseBadgeText = '';
  Timer? _phaseBadgeTimer;
  late final AnimationController _milestonePulseController;

  // Reminders
  Timer? _reminderTimer;
  bool _reminderDialogVisible = false;

  // Day tracking
  String? _lastEvaluatedDayKey;
  Timer? _programDayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    _milestonePulseController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 900),
        )..addListener(() {
          if (mounted) setState(() {});
        });

    _checkPhaseBoundaryMilestone(DateTime.now());
    _syncReminderSchedule();
    _initializeSoundscape();
  }

  void _initializeServices() {
    _settingsStore = SettingsStore(widget.prefs);
    _parallaxEnabled = _settingsStore.parallaxEnabled;
    _hasSeenOnboarding = _settingsStore.hasSeenOnboarding;
    _hasOpenedMenu = _settingsStore.hasOpenedMenu;
    _remindersEnabled = _settingsStore.remindersEnabled;
    _reminderTime = _timeFromMinutes(_settingsStore.reminderTimeMinutes);
    _soundEnabled = _settingsStore.soundEnabled;
    _hapticsEnabled = _settingsStore.hapticsEnabled;
    _restDaysEnabled = _settingsStore.restDaysEnabled;
    _freezeStreaksRemaining = _settingsStore.freezeStreaksRemaining;
    _selectedSoundscape = _settingsStore.selectedSoundscape;

    _programModel = ProgramModel(widget.prefs);
    _completionStore = DailyCompletionStore(widget.prefs);
    _sessionController = SessionController(
      programModel: _programModel,
      completionStore: _completionStore,
      prefs: widget.prefs,
    );
    _sessionController.addListener(_handleSessionUpdate);

    // Configure haptic service
    HapticService.instance.enabled = _hapticsEnabled;
  }

  Future<void> _initializeSoundscape() async {
    await SoundscapeService.instance.initialize();
    await SoundscapeService.instance.setSoundscape(_selectedSoundscape);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionController.removeListener(_handleSessionUpdate);
    _sessionController.dispose();
    _programDayTimer?.cancel();
    _reminderTimer?.cancel();
    _phaseBadgeTimer?.cancel();
    _milestonePulseController.dispose();
    SoundscapeService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sessionController.refresh();
      _checkReminder();
      _checkPhaseBoundaryMilestone(DateTime.now());
      _syncReminderSchedule();
    }
  }

  void _handleSessionUpdate() {
    _handleSessionCues();
    if (mounted) setState(() {});
  }

  void _handleSessionCues() {
    final wasCompleted = _sessionController.completionHold;
    if (wasCompleted) {
      _playCompletionCue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.of(context).accessibleNavigation || !_parallaxEnabled;
    final isLuminanceReduced = MediaQuery.of(context).highContrast;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final orbDiameter = VisualSpec.orbDiameter(size.width, size.height);
            final orbCenter = VisualSpec.orbCenter(size.width, size.height);
            final isCompletionHold = _sessionController.completionHold;
            final focus = (_sessionController.isRunning || isCompletionHold)
                ? 0.7
                : 0.0;
            final backgroundOpacity = VisualSpec.backgroundOpacity(focus);
            final orbBoost = VisualSpec.orbCoreBoost(focus);
            final parallaxOffset = (_parallaxEnabled && !reduceMotion)
                ? _parallaxOffset
                : Offset.zero;

            // Calculate stats
            final today = DateTime.now();
            final todayKey = DateHelpers.dayKey(today);
            final last7 = DateHelpers.last7Dates(today);
            final last7Completions = last7
                .map(_completionStore.isCompleted)
                .toList();
            final weekStart = DateHelpers.startOfLocalDay(
              today,
            ).subtract(Duration(days: today.weekday - 1));
            final weekToDate = DateHelpers.datesInRange(weekStart, today);
            final weeklyCompletions = weekToDate
                .map(_completionStore.isCompleted)
                .where((completed) => completed)
                .length;
            final weeklyTargetDays = weekToDate.length;
            final streakLength = _calculateStreak(today, last7Completions);
            final targetMinutes = _programModel.todayTargetMinutes(today);
            final programDayIndex = _programModel.dayIndexSinceStart(today);
            final phaseIndex = _programModel.currentPhaseIndex(today);
            final accentColor = VisualSpec.phaseAccent(
              phaseIndex,
              isLuminanceReduced: isLuminanceReduced,
            );
            final programProgress = _programModel.programProgress(today);

            // Status text
            final statusText = _buildStatusText();
            final showCompletedNotice = _sessionController.completedTodayNotice;
            final showCompletionCopy =
                isCompletionHold && !_sessionController.isRunning;

            // Check for day change
            if (_lastEvaluatedDayKey != todayKey) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _checkPhaseBoundaryMilestone(today);
              });
            }

            return MouseRegion(
              onExit: (_) => _resetParallax(),
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) => _updateParallax(
                  e.localPosition,
                  size,
                  orbCenter,
                  reduceMotion,
                ),
                onPointerMove: (e) => _updateParallax(
                  e.localPosition,
                  size,
                  orbCenter,
                  reduceMotion,
                ),
                onPointerHover: (e) => _updateParallax(
                  e.localPosition,
                  size,
                  orbCenter,
                  reduceMotion,
                ),
                onPointerUp: (_) => _resetParallax(),
                onPointerCancel: (_) => _resetParallax(),
                child: Stack(
                  children: [
                    // Background gradient
                    _buildBackgroundGradient(
                      orbCenter,
                      orbDiameter,
                      accentColor,
                      backgroundOpacity,
                    ),

                    // Film grain overlay
                    _buildFilmGrain(),

                    // Ambient glow
                    _buildAmbientGlow(
                      orbCenter,
                      orbDiameter,
                      accentColor,
                      backgroundOpacity,
                    ),

                    // Outer ring
                    _buildOuterRing(
                      orbCenter,
                      orbDiameter,
                      accentColor,
                      backgroundOpacity,
                    ),

                    // Top panel
                    _buildTopPanel(
                      orbCenter,
                      orbDiameter,
                      accentColor,
                      weeklyCompletions,
                      weeklyTargetDays,
                      streakLength,
                    ),

                    // Week dots arc
                    WeekDotsArcView(
                      last7Dates: last7,
                      last7Completions: last7Completions,
                      focus: focus,
                      today: today,
                      programProgress: programProgress,
                      programDayIndex: programDayIndex,
                      showProgramDay: _showProgramDayOverride,
                      accentColor: accentColor,
                      milestonePulse: _milestonePulseController.value,
                      isLuminanceReduced: isLuminanceReduced,
                    ),

                    // Orb section
                    Transform.scale(
                      scale: orbBoost,
                      child: OrbSection(
                        orbCenter: orbCenter,
                        orbDiameter: orbDiameter,
                        accentColor: accentColor,
                        isRunning: _sessionController.isRunning,
                        isCompletionHold: isCompletionHold,
                        progressToFinish: _sessionController.progressToFinish,
                        completionPulse: _sessionController.completionPulse,
                        reduceMotion: reduceMotion,
                        isLuminanceReduced: isLuminanceReduced,
                        parallaxOffset: parallaxOffset,
                        isPressed: _isPressed,
                        targetMinutes: targetMinutes,
                        remainingSeconds: _sessionController.remainingSeconds,
                        statusText: statusText,
                        showCompletedNotice: showCompletedNotice,
                        showCompletionCopy: showCompletionCopy,
                        onTap: _handleOrbTap,
                        onLongPress: _openMenu,
                        onTapDown: () => setState(() => _isPressed = true),
                        onTapUp: () => setState(() => _isPressed = false),
                        onTapCancel: () => setState(() => _isPressed = false),
                      ),
                    ),

                    // Onboarding overlay
                    if (!_hasSeenOnboarding)
                      OnboardingOverlay(
                        accentColor: accentColor,
                        onDismiss: () {
                          _settingsStore.hasSeenOnboarding = true;
                          setState(() => _hasSeenOnboarding = true);
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackgroundGradient(
    Offset orbCenter,
    double orbDiameter,
    Color accentColor,
    double opacity,
  ) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.25, -0.9),
            radius: 1.35,
            colors: [
              accentColor.withOpacity(0.18 * opacity),
              const Color(0xFF07090A),
              Colors.black,
            ],
            stops: const [0.0, 0.56, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildFilmGrain() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.06,
          child: CustomPaint(painter: FilmGrainPainter()),
        ),
      ),
    );
  }

  Widget _buildAmbientGlow(
    Offset orbCenter,
    double orbDiameter,
    Color accentColor,
    double opacity,
  ) {
    return Positioned(
      left: orbCenter.dx - orbDiameter * 0.75,
      top: orbCenter.dy - orbDiameter * 0.75,
      child: Opacity(
        opacity: 0.35 * opacity,
        child: Container(
          width: orbDiameter * 1.5,
          height: orbDiameter * 1.5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                accentColor.withOpacity(0.22),
                Colors.black.withOpacity(0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOuterRing(
    Offset orbCenter,
    double orbDiameter,
    Color accentColor,
    double opacity,
  ) {
    return Positioned(
      left: orbCenter.dx - orbDiameter * 0.825,
      top: orbCenter.dy - orbDiameter * 0.825,
      child: Opacity(
        opacity: 0.18 * opacity,
        child: SizedBox(
          width: orbDiameter * 1.65,
          height: orbDiameter * 1.65,
          child: CustomPaint(
            painter: RingGradientPainter(
              lineWidth: 1.0,
              accentColor: accentColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPanel(
    Offset orbCenter,
    double orbDiameter,
    Color accentColor,
    int weeklyCompletions,
    int weeklyTargetDays,
    int streakLength,
  ) {
    return Positioned(
      left: 0,
      right: 0,
      top: 6.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WeeklyProgressPill(
            weeklyCompletions: weeklyCompletions,
            weeklyTargetDays: weeklyTargetDays,
            streakLength: streakLength,
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          PhaseBadge(
            text: _phaseBadgeText,
            accentColor: accentColor,
            visible: _showPhaseBadge,
          ),
        ],
      ),
    );
  }

  String? _buildStatusText() {
    final showCompletedNotice = _sessionController.completedTodayNotice;
    final showCompletionCopy =
        _sessionController.completionHold && !_sessionController.isRunning;
    final showMenuHint =
        !_hasOpenedMenu &&
        _hasSeenOnboarding &&
        !_sessionController.isRunning &&
        !showCompletedNotice &&
        !showCompletionCopy;

    if (showCompletedNotice) return 'Completed today.';
    if (showCompletionCopy) return 'See you tomorrow.';
    if (showMenuHint) return 'Hold for menu.';
    return null;
  }

  // Actions

  void _handleOrbTap() {
    unawaited(SoundscapeService.instance.unlockForUserGesture());
    _playTapCue();
    _sessionController.toggleSession();
  }

  void _playTapCue() {
    HapticService.instance.buttonTap();
    if (_soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  void _playCompletionCue() {
    // Haptic handled by SessionController
    if (_soundEnabled) SystemSound.play(SystemSoundType.click);
  }

  void _playReminderCue() {
    HapticService.instance.reminder();
    if (_soundEnabled) SystemSound.play(SystemSoundType.alert);
  }

  // Menu

  Future<void> _openMenu() async {
    _settingsStore.hasOpenedMenu = true;
    setState(() => _hasOpenedMenu = true);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildEnhancedMenuSheet(),
    );
  }

  Widget _buildEnhancedMenuSheet() {
    final today = DateTime.now();
    final isCompleted = _completionStore.isCompleted(today);
    final isRestDay = _completionStore.isRestDay(today);
    final restDaysUsed = _completionStore.getRestDaysUsedThisWeek(today);
    final restDayAvailable =
        _restDaysEnabled && restDaysUsed < 1 && !isCompleted && !isRestDay;
    final canFreeze =
        _freezeStreaksRemaining > 0 && !_sessionController.isRunning;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          // Header
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 16),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Show Day
          _MenuItem(
            icon: Icons.calendar_today_outlined,
            title: 'Show Day',
            onTap: () {
              Navigator.pop(context);
              _revealProgramDay();
            },
          ),

          // Statistics
          _MenuItem(
            icon: Icons.bar_chart_outlined,
            title: 'Statistics',
            onTap: () {
              Navigator.pop(context);
              _showStatistics();
            },
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Reminders
          _MenuSwitchTile(
            icon: Icons.notifications_outlined,
            title: 'Daily Reminders',
            subtitle: 'At ${_formatTime(_reminderTime)}',
            value: _remindersEnabled,
            onChanged: (v) => _toggleReminders(v),
            onTap: _remindersEnabled
                ? _pickReminderTime
                : () => _toggleReminders(true),
          ),

          // Sound
          _MenuSwitchTile(
            icon: _soundEnabled
                ? Icons.volume_up_outlined
                : Icons.volume_off_outlined,
            title: 'Sound',
            value: _soundEnabled,
            onChanged: (v) {
              setState(() => _soundEnabled = v);
              _settingsStore.soundEnabled = v;
            },
          ),

          _MenuItem(
            icon: Icons.notifications_active_outlined,
            title: 'Test Sound',
            onTap: () {
              unawaited(SoundscapeService.instance.unlockForUserGesture());
              unawaited(SoundscapeService.instance.playCompletionBell());
            },
          ),

          // Haptics
          _MenuSwitchTile(
            icon: Icons.vibration_outlined,
            title: 'Haptics',
            value: _hapticsEnabled,
            onChanged: (v) {
              setState(() => _hapticsEnabled = v);
              _settingsStore.hapticsEnabled = v;
              HapticService.instance.enabled = v;
            },
          ),

          // Motion
          _MenuSwitchTile(
            icon: Icons.animation_outlined,
            title: 'Motion Effects',
            value: _parallaxEnabled,
            onChanged: (v) {
              setState(() {
                _parallaxEnabled = v;
                if (!v) _parallaxOffset = Offset.zero;
                _settingsStore.parallaxEnabled = v;
              });
            },
          ),

          // Rest Days Toggle
          _MenuSwitchTile(
            icon: Icons.hotel_outlined,
            title: 'Rest Days',
            subtitle: '$restDaysUsed/1 used this week',
            value: _restDaysEnabled,
            onChanged: (v) {
              setState(() {
                _restDaysEnabled = v;
                _settingsStore.restDaysEnabled = v;
              });
            },
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Soundscape Selection
          _MenuItem(
            icon: Icons.music_note_outlined,
            title: 'Soundscape',
            subtitle: SoundscapeService.soundscapes[_selectedSoundscape],
            onTap: () {
              Navigator.pop(context);
              _showSoundscapePicker();
            },
          ),

          // Use Rest Day
          if (restDayAvailable)
            _MenuItem(
              icon: Icons.weekend_outlined,
              title: 'Use Rest Day',
              subtitle: 'Take a break without breaking streak',
              iconColor: Colors.green.shade300,
              onTap: () {
                Navigator.pop(context);
                _useRestDay();
              },
            ),

          // Freeze Streak
          if (canFreeze)
            _MenuItem(
              icon: Icons.ac_unit,
              title: 'Freeze Streak',
              subtitle: '$_freezeStreaksRemaining remaining',
              iconColor: Colors.blue.shade300,
              onTap: () {
                Navigator.pop(context);
                _showFreezeStreakDialog();
              },
            ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // About
          _MenuItem(
            icon: Icons.help_outline,
            title: 'About / Help',
            onTap: () {
              Navigator.pop(context);
              _showAbout();
            },
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Reset
          _MenuItem(
            icon: Icons.restart_alt,
            title: 'Reset Program',
            textColor: Colors.red.shade300,
            iconColor: Colors.red.shade300,
            onTap: () {
              Navigator.pop(context);
              _confirmReset();
            },
          ),

          // Cancel
          _MenuItem(
            icon: Icons.close,
            title: 'Cancel',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showSoundscapePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Soundscape',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ...SoundscapeService.soundscapes.entries.map((entry) {
              final isSelected = entry.key == _selectedSoundscape;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? Colors.teal : Colors.white54,
                ),
                title: Text(entry.value),
                onTap: () {
                  setState(() {
                    _selectedSoundscape = entry.key;
                    _settingsStore.selectedSoundscape = entry.key;
                  });
                  SoundscapeService.instance.setSoundscape(entry.key);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _useRestDay() {
    final today = DateTime.now();
    _completionStore.setRestDay(today);
    HapticService.instance.restDayUsed();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rest day used. Your streak is protected.'),
        duration: Duration(seconds: 2),
      ),
    );

    setState(() {});

    LoggingService.instance.info(
      'Rest day used',
      tag: 'MainScreen',
      data: {'date': DateHelpers.dayKey(today)},
    );
  }

  Future<void> _showFreezeStreakDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        title: const Text('Freeze Streak?'),
        content: Text(
          'Freezing your streak protects it from breaking today. '
          'You have $_freezeStreaksRemaining freezes remaining.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Freeze'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final today = DateTime.now();
      _completionStore.freezeStreak(today);

      setState(() {
        _freezeStreaksRemaining--;
        _settingsStore.freezeStreaksUsed = _settingsStore.freezeStreaksUsed + 1;
      });

      HapticService.instance.streakFrozen();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Streak frozen! $_freezeStreaksRemaining freezes remaining.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      LoggingService.instance.info(
        'Streak frozen',
        tag: 'MainScreen',
        data: {
          'date': DateHelpers.dayKey(today),
          'remaining': _freezeStreaksRemaining,
        },
      );
    }
  }

  // Reminders

  Future<void> _toggleReminders(bool value) async {
    if (!value) {
      setState(() => _remindersEnabled = false);
      _settingsStore.remindersEnabled = false;
      await _syncReminderSchedule();
      return;
    }

    final granted = await _ensureReminderPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _remindersEnabled = false);
      _settingsStore.remindersEnabled = false;
      return;
    }

    await _pickReminderTime(enableIfPicked: true);
  }

  Future<void> _pickReminderTime({bool enableIfPicked = false}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (!mounted) return;
    if (picked == null) {
      if (enableIfPicked) {
        setState(() => _remindersEnabled = false);
        _settingsStore.remindersEnabled = false;
        await _syncReminderSchedule();
      }
      return;
    }

    setState(() {
      _reminderTime = picked;
      _remindersEnabled = true;
    });
    _settingsStore.remindersEnabled = true;
    _settingsStore.reminderTimeMinutes = _timeToMinutes(picked);
    await _syncReminderSchedule();
  }

  Future<void> _syncReminderSchedule() async {
    if (!_remindersEnabled) {
      _reminderTimer?.cancel();
      await NotificationsService.instance.cancelDailyReminder();
      return;
    }
    await NotificationsService.instance.scheduleDailyReminder(_reminderTime);
    _startReminderTimer();
  }

  void _startReminderTimer() {
    _reminderTimer?.cancel();
    if (!_remindersEnabled) return;
    _reminderTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkReminder();
    });
    _checkReminder();
  }

  void _checkReminder() {
    if (!mounted || !_remindersEnabled || _reminderDialogVisible) return;
    if (_sessionController.isRunning || _sessionController.completionHold)
      return;

    final now = DateTime.now();
    if (_completionStore.isCompleted(now)) {
      _settingsStore.lastReminderDay = DateHelpers.dayKey(now);
      return;
    }

    final minutesNow = now.hour * 60 + now.minute;
    if (minutesNow < _settingsStore.reminderTimeMinutes) return;

    final todayKey = DateHelpers.dayKey(now);
    if (_settingsStore.lastReminderDay == todayKey) return;

    _settingsStore.lastReminderDay = todayKey;
    _showReminderDialog();
  }

  Future<void> _showReminderDialog() async {
    if (!mounted) return;
    _reminderDialogVisible = true;
    _playReminderCue();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        title: const Text('Time for today\'s session'),
        content: const Text('Tap to start your session now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playTapCue();
              _sessionController.toggleSession();
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (mounted) _reminderDialogVisible = false;
  }

  Future<bool> _ensureReminderPermission() async {
    final granted = await NotificationsService.instance.requestPermissions();
    if (!granted && mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF101010),
          title: const Text('Enable Notifications'),
          content: const Text(
            'Allow notifications in Settings to receive daily reminders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    return granted;
  }

  // Phase milestones

  void _checkPhaseBoundaryMilestone(DateTime date) {
    final todayKey = DateHelpers.dayKey(date);
    if (_lastEvaluatedDayKey == todayKey) return;
    _lastEvaluatedDayKey = todayKey;

    final dayIndex = _programModel.dayIndexSinceStart(date);
    if (!ProgramModel.phaseDayCaps.contains(dayIndex)) return;
    if (_settingsStore.lastPhaseBadgeDay == dayIndex) return;

    _settingsStore.lastPhaseBadgeDay = dayIndex;
    final phaseIndex = _programModel.phaseIndexForDay(dayIndex) + 1;
    final minutes = _programModel.targetMinutesForDay(dayIndex);
    _showPhaseUnlockBadge('Phase $phaseIndex unlocked • $minutes min target');
    HapticService.instance.phaseMilestone();
  }

  void _showPhaseUnlockBadge(String text) {
    _phaseBadgeTimer?.cancel();
    setState(() {
      _phaseBadgeText = text;
      _showPhaseBadge = true;
    });

    _milestonePulseController.forward(from: 0).then((_) {
      if (mounted) _milestonePulseController.reverse();
    });

    _phaseBadgeTimer = Timer(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _showPhaseBadge = false);
    });
  }

  void _revealProgramDay() {
    _programDayTimer?.cancel();
    setState(() => _showProgramDayOverride = true);
    _programDayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showProgramDayOverride = false);
    });
  }

  // Program reset

  void _confirmReset() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        title: const Text('Reset Program?'),
        content: const Text('This clears completions and starts Day 1 today.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetProgramData();
            },
            child: const Text('Reset Program'),
          ),
        ],
      ),
    );
  }

  void _resetProgramData() {
    _sessionController.resetSessionState();
    _completionStore.clearAll();
    _programModel.programStartDate = DateTime.now();
    _settingsStore.lastReminderDay = null;
    _settingsStore.lastPhaseBadgeDay = null;
    _settingsStore.freezeStreaksUsed = 0;
    _freezeStreaksRemaining = _settingsStore.freezeStreaksAvailable;
    _lastEvaluatedDayKey = null;
    setState(() {});

    LoggingService.instance.info('Program reset', tag: 'MainScreen');
  }

  // Statistics

  void _showStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatisticsScreen(
          programModel: _programModel,
          completionStore: _completionStore,
        ),
      ),
    );
  }

  // About

  void _showAbout() {
    final today = DateTime.now();
    final dayIndex = _programModel.dayIndexSinceStart(today);
    final targetMinutes = _programModel.todayTargetMinutes(today);
    final phaseIndex = _programModel.currentPhaseIndex(today);
    final streak = _completionStore.getStreakLength(
      today,
      allowRestDays: _restDaysEnabled,
      allowFrozen: true,
    );

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        title: const Text('1000'),
        content: Text(
          'Build from 3 to 30 minutes in 1000 days.\n\n'
          'Day $dayIndex of 1000\n'
          'Phase ${phaseIndex + 1}\n'
          'Today: $targetMinutes minutes\n'
          'Current streak: $streak days\n\n'
          'Tap the orb to begin your session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Parallax

  void _updateParallax(
    Offset position,
    Size size,
    Offset orbCenter,
    bool reduceMotion,
  ) {
    if (!_parallaxEnabled || reduceMotion) {
      _resetParallax();
      return;
    }
    if (size.width == 0 || size.height == 0) return;

    final normalizedX = (position.dx - orbCenter.dx) / (size.width / 2);
    final normalizedY = (position.dy - orbCenter.dy) / (size.height / 2);
    final clamped = Offset(
      normalizedX.clamp(-1.0, 1.0).toDouble(),
      normalizedY.clamp(-1.0, 1.0).toDouble(),
    );
    final amplitude = VisualSpec.parallaxAmplitude(size.width, size.height);
    final next = Offset(clamped.dx * amplitude, clamped.dy * amplitude);

    if ((next - _parallaxOffset).distance >= 0.1) {
      setState(() => _parallaxOffset = next);
    }
  }

  void _resetParallax() {
    if (_parallaxOffset != Offset.zero) {
      setState(() => _parallaxOffset = Offset.zero);
    }
  }

  // Utilities

  int _calculateStreak(DateTime date, List<bool> last7Completions) {
    return _completionStore.getStreakLength(
      date,
      allowRestDays: _restDaysEnabled,
      allowFrozen: true,
    );
  }

  TimeOfDay _timeFromMinutes(int minutes) {
    final normalized = minutes % (24 * 60);
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  int _timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

// Menu widgets

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        size: 22,
        color: iconColor ?? Colors.white.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor ?? Colors.white.withOpacity(0.9),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

class _MenuSwitchTile extends StatelessWidget {
  const _MenuSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: Colors.white.withOpacity(0.7)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.5),
              ),
            )
          : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      onTap: onTap ?? (() => onChanged(!value)),
    );
  }
}
