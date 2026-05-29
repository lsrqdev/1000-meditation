import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Manages local push notifications for daily meditation reminders.
///
/// Uses a singleton pattern to ensure consistent notification handling
/// across the app lifecycle.
class NotificationsService {
  NotificationsService._();

  /// The singleton instance.
  static final NotificationsService instance = NotificationsService._();

  static const int _dailyReminderId = 1001;
  static const String _dailyChannelId = 'daily_reminders';
  static const String _dailyChannelName = 'Daily Reminders';
  static const String _dailyChannelDescription = 'Daily practice reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initializes the notification service.
  ///
  /// Sets up timezone data and notification channels. Safe to call multiple times.
  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    try {
      tz.initializeTimeZones();
      try {
        final localName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(localName));
      } catch (_) {
        developer.log(
          'Failed to get local timezone, using UTC',
          name: 'NotificationsService',
        );
        tz.setLocalLocation(tz.UTC);
      }

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      final iosSettings = DarwinInitializationSettings(
        requestSoundPermission: false,
        requestAlertPermission: false,
        requestBadgePermission: false,
      );
      final settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      );

      await _plugin.initialize(settings);
      _initialized = true;
      developer.log(
        'Notifications service initialized',
        name: 'NotificationsService',
      );
    } catch (e) {
      developer.log(
        'Error initializing notifications: $e',
        name: 'NotificationsService',
      );
    }
  }

  /// Requests notification permissions from the user.
  ///
  /// Returns true if all permissions are granted, false otherwise.
  /// On web, always returns true.
  Future<bool> requestPermissions() async {
    await initialize();

    if (kIsWeb) return true;

    try {
      var granted = true;

      // iOS
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final iosGranted =
          await iosPlugin?.requestPermissions(
            alert: true,
            sound: true,
            badge: false,
          ) ??
          true;

      // macOS
      final macosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      final macosGranted =
          await macosPlugin?.requestPermissions(
            alert: true,
            sound: true,
            badge: false,
          ) ??
          true;

      // Android 13+
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final androidGranted =
          await androidPlugin?.requestNotificationsPermission() ?? true;

      granted = iosGranted && macosGranted && androidGranted;
      developer.log(
        'Notification permissions granted: $granted',
        name: 'NotificationsService',
      );
      return granted;
    } catch (e) {
      developer.log(
        'Error requesting permissions: $e',
        name: 'NotificationsService',
      );
      return false;
    }
  }

  /// Schedules a daily reminder notification.
  ///
  /// The notification will appear at the specified [time] every day.
  /// If a notification is already scheduled, it will be replaced.
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await initialize();

    if (kIsWeb) return;

    try {
      final scheduled = _nextInstanceOfTime(time);
      await _plugin.zonedSchedule(
        _dailyReminderId,
        'Time for today\'s session',
        'Tap to start your session.',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _dailyChannelId,
            _dailyChannelName,
            channelDescription: _dailyChannelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      developer.log(
        'Daily reminder scheduled for ${time.hour}:${time.minute}',
        name: 'NotificationsService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling reminder: $e',
        name: 'NotificationsService',
      );
    }
  }

  /// Cancels the daily reminder notification.
  Future<void> cancelDailyReminder() async {
    await initialize();

    if (kIsWeb) return;

    try {
      await _plugin.cancel(_dailyReminderId);
      developer.log('Daily reminder cancelled', name: 'NotificationsService');
    } catch (e) {
      developer.log(
        'Error cancelling reminder: $e',
        name: 'NotificationsService',
      );
    }
  }

  /// Checks if daily reminders are currently scheduled.
  Future<bool> isDailyReminderScheduled() async {
    await initialize();

    if (kIsWeb) return false;

    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.any((r) => r.id == _dailyReminderId);
    } catch (e) {
      developer.log(
        'Error checking scheduled reminders: $e',
        name: 'NotificationsService',
      );
      return false;
    }
  }

  /// Cancels all notifications.
  Future<void> cancelAll() async {
    await initialize();

    if (kIsWeb) return;

    try {
      await _plugin.cancelAll();
      developer.log(
        'All notifications cancelled',
        name: 'NotificationsService',
      );
    } catch (e) {
      developer.log(
        'Error cancelling all notifications: $e',
        name: 'NotificationsService',
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
