import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum NotificationPermissionStatus { granted, denied, unknown, unsupported }

enum ReminderRecurrenceType { daily, weekly, monthly }

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  // Bump channel IDs to force Android to create fresh channels on existing installs.
  static const String _taskChannelId = 'zenit_task_reminders_v2';
  static const String _taskChannelName = 'Task reminders';
  static const String _taskChannelDescription =
      'Deadline reminders for tasks in ZENiT';
  static const String _habitChannelId = 'zenit_habit_reminders_v2';
  static const String _habitChannelName = 'Habit reminders';
  static const String _habitChannelDescription =
      'Recurring reminders for habits in ZENiT';
  static const String _journalChannelId = 'zenit_journal_prompts_v2';
  static const String _journalChannelName = 'Journal prompts';
  static const String _journalChannelDescription =
      'Daily reflection prompts for ZENiT journal';
  static const String _billChannelId = 'zenit_bill_reminders_v1';
  static const String _billChannelName = 'Bill reminders';
  static const String _billChannelDescription =
      'Due date reminders for bills in ZENiT';
  static const String _focusChannelId = 'zenit_focus_transitions_v1';
  static const String _focusChannelName = 'Focus transitions';
  static const String _focusChannelDescription =
      'Alerts when focus sessions switch between focus and break phases';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (!_supportsNotifications()) return;
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);
    await _configureLocalTimezone();
    await _createNotificationChannels();
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskTitle,
    required DateTime reminderAt,
  }) async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }

    final scheduledDate = tz.TZDateTime.from(reminderAt, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    try {
      await _plugin.zonedSchedule(
        _taskNotificationId(taskId),
        'Task reminder',
        taskTitle,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _taskChannelId,
            _taskChannelName,
            channelDescription: _taskChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task:$taskId',
        matchDateTimeComponents: null,
      );
    } catch (e) {
      debugPrint('Error scheduling task reminder: $e');
      // Fallback to inexact if exact fails
      await _plugin.zonedSchedule(
        _taskNotificationId(taskId),
        'Task reminder',
        taskTitle,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _taskChannelId,
            _taskChannelName,
            channelDescription: _taskChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'task:$taskId',
        matchDateTimeComponents: null,
      );
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancel(_taskNotificationId(taskId));
  }

  Future<void> scheduleBillReminder({
    required int billId,
    required String billTitle,
    required DateTime reminderAt,
  }) async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }

    final scheduledDate = tz.TZDateTime.from(reminderAt, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    try {
      await _plugin.zonedSchedule(
        _billNotificationId(billId),
        'Bill reminder',
        billTitle,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _billChannelId,
            _billChannelName,
            channelDescription: _billChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'bill:$billId',
        matchDateTimeComponents: null,
      );
    } catch (e) {
      debugPrint('Error scheduling bill reminder: $e');
      await _plugin.zonedSchedule(
        _billNotificationId(billId),
        'Bill reminder',
        billTitle,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _billChannelId,
            _billChannelName,
            channelDescription: _billChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'bill:$billId',
        matchDateTimeComponents: null,
      );
    }
  }

  Future<void> cancelBillReminder(int billId) async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancel(_billNotificationId(billId));
  }

  Future<void> cancelAll() async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancelAll();
  }

  Future<void> showFocusPhaseTransitionAlert({
    required bool toBreak,
    required Duration nextDuration,
    String? taskTitle,
  }) async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }

    final minutes = nextDuration.inMinutes.clamp(1, 9999);
    final minutesLabel = minutes == 1 ? '1 minute' : '$minutes minutes';
    final linkedTaskSuffix = (taskTitle != null && taskTitle.trim().isNotEmpty)
        ? ' • ${taskTitle.trim()}'
        : '';

    final title = toBreak
        ? 'Focus complete. Break starts now.'
        : 'Break complete. Back to focus.';
    final body = toBreak
        ? 'Take a $minutesLabel break$linkedTaskSuffix.'
        : 'Start a $minutesLabel focus block$linkedTaskSuffix.';

    await _plugin.show(
      _focusTransitionNotificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _focusChannelId,
          _focusChannelName,
          channelDescription: _focusChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
      payload: 'focus:transition',
    );
  }

  Future<void> scheduleHabitReminder({
    required int habitId,
    required String habitTitle,
    required ReminderRecurrenceType recurrence,
    required TimeOfDay reminderTime,
    int? weekday,
    int? dayOfMonth,
  }) async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }

    final now = tz.TZDateTime.now(tz.local);
    late final tz.TZDateTime firstRun;
    late final DateTimeComponents components;

    if (recurrence == ReminderRecurrenceType.daily) {
      firstRun = _nextDailyTrigger(now, reminderTime);
      components = DateTimeComponents.time;
    } else if (recurrence == ReminderRecurrenceType.weekly) {
      final normalizedWeekday = (weekday ?? now.weekday).clamp(1, 7).toInt();
      firstRun = _nextWeeklyTrigger(now, reminderTime, normalizedWeekday);
      components = DateTimeComponents.dayOfWeekAndTime;
    } else {
      final normalizedDay = (dayOfMonth ?? now.day).clamp(1, 31).toInt();
      firstRun = _nextMonthlyTrigger(now, reminderTime, normalizedDay);
      components = DateTimeComponents.dayOfMonthAndTime;
    }

    await _plugin.zonedSchedule(
      _habitNotificationId(habitId),
      'Habit reminder',
      habitTitle,
      firstRun,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _habitChannelId,
          _habitChannelName,
          channelDescription: _habitChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'habit:$habitId',
      matchDateTimeComponents: components,
    );
  }

  Future<void> cancelHabitReminder(int habitId) async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancel(_habitNotificationId(habitId));
  }

  Future<void> scheduleJournalDailyPrompt({
    required TimeOfDay reminderTime,
  }) async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }

    final now = tz.TZDateTime.now(tz.local);
    final firstRun = _nextDailyTrigger(now, reminderTime);

    await _plugin.cancel(_journalNotificationId);

    await _plugin.zonedSchedule(
      _journalNotificationId,
      'Journal prompt',
      'Take a minute to reflect on your day in ZENiT.',
      firstRun,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _journalChannelId,
          _journalChannelName,
          channelDescription: _journalChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'journal:daily',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelJournalDailyPrompt() async {
    if (!_supportsNotifications()) return;
    if (!_initialized) {
      await initialize();
    }
    await _plugin.cancel(_journalNotificationId);
  }

  Future<NotificationPermissionStatus> getPermissionStatus() async {
    if (!_supportsNotifications()) {
      return NotificationPermissionStatus.unsupported;
    }

    if (!_initialized) {
      await initialize();
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final dynamic androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      try {
        final bool? enabled = await androidPlugin?.areNotificationsEnabled();
        if (enabled == null) {
          return NotificationPermissionStatus.unknown;
        }
        return enabled
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      } catch (_) {
        return NotificationPermissionStatus.unknown;
      }
    }

    return NotificationPermissionStatus.unknown;
  }

  Future<NotificationPermissionStatus> requestPermissions() async {
    if (!_supportsNotifications()) {
      return NotificationPermissionStatus.unsupported;
    }
    if (!_initialized) {
      await initialize();
    }
    await _requestPermissions();
    return getPermissionStatus();
  }

  /// Check if the app can schedule exact alarms (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true; // Other platforms don't have this restriction
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return false;

    try {
      final bool? canSchedule = await androidPlugin
          .canScheduleExactNotifications();
      return canSchedule ?? false;
    } catch (e) {
      debugPrint('Error checking exact alarm permission: $e');
      return false;
    }
  }

  /// Request permission to schedule exact alarms (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return false;

    try {
      final bool? result = await androidPlugin.requestExactAlarmsPermission();
      return result ?? false;
    } catch (e) {
      debugPrint('Error requesting exact alarm permission: $e');
      return false;
    }
  }

  int _taskNotificationId(int taskId) => 100000 + taskId;
  int _habitNotificationId(int habitId) => 200000 + habitId;
  static const int _journalNotificationId = 300000;
  static const int _focusTransitionNotificationId = 400000;
  int _billNotificationId(int billId) => 500000 + billId;

  bool _supportsNotifications() {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _configureLocalTimezone() async {
    tz.initializeTimeZones();

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone));
    } catch (_) {
      // Fall back to UTC if timezone lookup fails on a given device.
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    // Create task reminders channel
    const taskChannel = AndroidNotificationChannel(
      _taskChannelId,
      _taskChannelName,
      description: _taskChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create habit reminders channel
    const habitChannel = AndroidNotificationChannel(
      _habitChannelId,
      _habitChannelName,
      description: _habitChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create journal prompts channel
    const journalChannel = AndroidNotificationChannel(
      _journalChannelId,
      _journalChannelName,
      description: _journalChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create bill reminders channel
    const billChannel = AndroidNotificationChannel(
      _billChannelId,
      _billChannelName,
      description: _billChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create focus transition channel
    const focusChannel = AndroidNotificationChannel(
      _focusChannelId,
      _focusChannelName,
      description: _focusChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(taskChannel);
    await androidPlugin.createNotificationChannel(habitChannel);
    await androidPlugin.createNotificationChannel(journalChannel);
    await androidPlugin.createNotificationChannel(billChannel);
    await androidPlugin.createNotificationChannel(focusChannel);
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS is not a current release target but this keeps the API safe.
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  tz.TZDateTime _nextDailyTrigger(tz.TZDateTime now, TimeOfDay time) {
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  tz.TZDateTime _nextWeeklyTrigger(
    tz.TZDateTime now,
    TimeOfDay time,
    int weekday,
  ) {
    final normalizedWeekday = weekday.clamp(1, 7).toInt();
    final daysUntil = (normalizedWeekday - now.weekday + 7) % 7;
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntil,
      time.hour,
      time.minute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 7));
    }
    return next;
  }

  tz.TZDateTime _nextMonthlyTrigger(
    tz.TZDateTime now,
    TimeOfDay time,
    int dayOfMonth,
  ) {
    final safeDay = dayOfMonth.clamp(1, 31).toInt();
    var year = now.year;
    var month = now.month;

    var day = safeDay <= _daysInMonth(year, month)
        ? safeDay
        : _daysInMonth(year, month);
    var next = tz.TZDateTime(
      tz.local,
      year,
      month,
      day,
      time.hour,
      time.minute,
    );

    if (!next.isAfter(now)) {
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      day = safeDay <= _daysInMonth(year, month)
          ? safeDay
          : _daysInMonth(year, month);
      next = tz.TZDateTime(tz.local, year, month, day, time.hour, time.minute);
    }

    return next;
  }

  int _daysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }
}
