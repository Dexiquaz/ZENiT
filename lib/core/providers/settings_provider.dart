import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

enum ReminderTimeFormat { system, h12, h24 }

class UserSettings {
  final String currency;
  final bool journalPromptEnabled;
  final int journalReminderHour;
  final int journalReminderMinute;
  final ReminderTimeFormat reminderTimeFormat;
  final int focusDurationMinutes;
  final int breakDurationMinutes;
  final bool silentFocusNotifications;

  UserSettings({
    this.currency = r'$',
    this.journalPromptEnabled = true,
    this.journalReminderHour = 21,
    this.journalReminderMinute = 0,
    this.reminderTimeFormat = ReminderTimeFormat.system,
    this.focusDurationMinutes = 25,
    this.breakDurationMinutes = 5,
    this.silentFocusNotifications = true,
  });

  TimeOfDay get journalReminderTime =>
      TimeOfDay(hour: journalReminderHour, minute: journalReminderMinute);

  UserSettings copyWith({
    String? currency,
    bool? journalPromptEnabled,
    int? journalReminderHour,
    int? journalReminderMinute,
    ReminderTimeFormat? reminderTimeFormat,
    int? focusDurationMinutes,
    int? breakDurationMinutes,
    bool? silentFocusNotifications,
  }) {
    return UserSettings(
      currency: currency ?? this.currency,
      journalPromptEnabled: journalPromptEnabled ?? this.journalPromptEnabled,
      journalReminderHour: journalReminderHour ?? this.journalReminderHour,
      journalReminderMinute:
          journalReminderMinute ?? this.journalReminderMinute,
      reminderTimeFormat: reminderTimeFormat ?? this.reminderTimeFormat,
      focusDurationMinutes: focusDurationMinutes ?? this.focusDurationMinutes,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      silentFocusNotifications:
          silentFocusNotifications ?? this.silentFocusNotifications,
    );
  }

  Map<String, dynamic> toBackupMap() {
    return {
      'currency': currency,
      'journalPromptEnabled': journalPromptEnabled,
      'journalReminderHour': journalReminderHour,
      'journalReminderMinute': journalReminderMinute,
      'reminderTimeFormat': reminderTimeFormat.name,
      'focusDurationMinutes': focusDurationMinutes,
      'breakDurationMinutes': breakDurationMinutes,
      'silentFocusNotifications': silentFocusNotifications,
    };
  }

  factory UserSettings.fromBackupMap(Map<String, dynamic> map) {
    final formatRaw = map['reminderTimeFormat']?.toString();
    final reminderTimeFormat = switch (formatRaw) {
      'h12' => ReminderTimeFormat.h12,
      'h24' => ReminderTimeFormat.h24,
      _ => ReminderTimeFormat.system,
    };

    final focus = (map['focusDurationMinutes'] as num?)?.toInt() ?? 25;
    final rest = (map['breakDurationMinutes'] as num?)?.toInt() ?? 5;
    final silentFocusNotifications =
        (map['silentFocusNotifications'] as bool?) ?? true;

    return UserSettings(
      currency: (map['currency'] as String?) ?? r'$',
      journalPromptEnabled: (map['journalPromptEnabled'] as bool?) ?? true,
      journalReminderHour: (map['journalReminderHour'] as num?)?.toInt() ?? 21,
      journalReminderMinute:
          (map['journalReminderMinute'] as num?)?.toInt() ?? 0,
      reminderTimeFormat: reminderTimeFormat,
      focusDurationMinutes: focus.clamp(1, 60).toInt(),
      breakDurationMinutes: rest.clamp(1, 30).toInt(),
      silentFocusNotifications: silentFocusNotifications,
    );
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, UserSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<UserSettings> {
  static const _currencyKey = 'setting_currency';
  static const _journalPromptEnabledKey = 'setting_journal_prompt_enabled';
  static const _journalReminderHourKey = 'setting_journal_reminder_hour';
  static const _journalReminderMinuteKey = 'setting_journal_reminder_minute';
  static const _reminderTimeFormatKey = 'setting_reminder_time_format';
  static const _focusDurationMinutesKey = 'setting_focus_duration_minutes';
  static const _breakDurationMinutesKey = 'setting_break_duration_minutes';
  static const _silentFocusNotificationsKey =
      'setting_silent_focus_notifications';

  final _notifications = NotificationService.instance;

  @override
  Future<UserSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final currency = prefs.getString(_currencyKey) ?? r'$';
    final journalPromptEnabled =
        prefs.getBool(_journalPromptEnabledKey) ?? true;
    final journalReminderHour = prefs.getInt(_journalReminderHourKey) ?? 21;
    final journalReminderMinute = prefs.getInt(_journalReminderMinuteKey) ?? 0;
    final reminderTimeFormat = _parseTimeFormat(
      prefs.getString(_reminderTimeFormatKey),
    );
    final focusDurationMinutes = prefs.getInt(_focusDurationMinutesKey) ?? 25;
    final breakDurationMinutes = prefs.getInt(_breakDurationMinutesKey) ?? 5;
    final silentFocusNotifications =
        prefs.getBool(_silentFocusNotificationsKey) ?? true;

    final settings = UserSettings(
      currency: currency,
      journalPromptEnabled: journalPromptEnabled,
      journalReminderHour: journalReminderHour,
      journalReminderMinute: journalReminderMinute,
      reminderTimeFormat: reminderTimeFormat,
      focusDurationMinutes: focusDurationMinutes,
      breakDurationMinutes: breakDurationMinutes,
      silentFocusNotifications: silentFocusNotifications,
    );
    await _syncJournalPrompt(settings);

    return settings;
  }

  Future<void> setCurrency(String c) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, c);
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(currency: c));
    }
  }

  Future<void> setJournalPromptEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_journalPromptEnabledKey, enabled);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(journalPromptEnabled: enabled);
    state = AsyncData(updated);
    await _syncJournalPrompt(updated);
  }

  Future<void> setJournalReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_journalReminderHourKey, time.hour);
    await prefs.setInt(_journalReminderMinuteKey, time.minute);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(
      journalReminderHour: time.hour,
      journalReminderMinute: time.minute,
    );
    state = AsyncData(updated);
    await _syncJournalPrompt(updated);
  }

  Future<void> setReminderTimeFormat(ReminderTimeFormat format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderTimeFormatKey, format.name);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(reminderTimeFormat: format);
    state = AsyncData(updated);
  }

  Future<void> setFocusDuration(int minutes) async {
    final clamped = minutes.clamp(1, 60).toInt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_focusDurationMinutesKey, clamped);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(focusDurationMinutes: clamped);
    state = AsyncData(updated);
  }

  Future<void> setBreakDuration(int minutes) async {
    final clamped = minutes.clamp(1, 30).toInt();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_breakDurationMinutesKey, clamped);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(breakDurationMinutes: clamped);
    state = AsyncData(updated);
  }

  Future<void> setSilentFocusNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_silentFocusNotificationsKey, enabled);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(silentFocusNotifications: enabled);
    state = AsyncData(updated);
  }

  Future<void> resyncJournalPrompt() async {
    final current = state.hasValue ? state.value! : await future;
    await _syncJournalPrompt(current);
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currencyKey);
    await prefs.remove(_journalPromptEnabledKey);
    await prefs.remove(_journalReminderHourKey);
    await prefs.remove(_journalReminderMinuteKey);
    await prefs.remove(_reminderTimeFormatKey);
    await prefs.remove(_focusDurationMinutesKey);
    await prefs.remove(_breakDurationMinutesKey);
    await prefs.remove(_silentFocusNotificationsKey);

    final defaults = UserSettings();
    state = AsyncData(defaults);
    await _syncJournalPrompt(defaults);
  }

  Future<Map<String, dynamic>> exportBackupMap() async {
    final current = state.hasValue ? state.value! : await future;
    return current.toBackupMap();
  }

  Future<void> applyBackupMap(Map<String, dynamic> map) async {
    final restored = UserSettings.fromBackupMap(map);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_currencyKey, restored.currency);
    await prefs.setBool(
      _journalPromptEnabledKey,
      restored.journalPromptEnabled,
    );
    await prefs.setInt(_journalReminderHourKey, restored.journalReminderHour);
    await prefs.setInt(
      _journalReminderMinuteKey,
      restored.journalReminderMinute,
    );
    await prefs.setString(
      _reminderTimeFormatKey,
      restored.reminderTimeFormat.name,
    );
    await prefs.setInt(_focusDurationMinutesKey, restored.focusDurationMinutes);
    await prefs.setInt(_breakDurationMinutesKey, restored.breakDurationMinutes);
    await prefs.setBool(
      _silentFocusNotificationsKey,
      restored.silentFocusNotifications,
    );

    state = AsyncData(restored);
    await _syncJournalPrompt(restored);
  }

  ReminderTimeFormat _parseTimeFormat(String? raw) {
    switch (raw) {
      case 'h12':
        return ReminderTimeFormat.h12;
      case 'h24':
        return ReminderTimeFormat.h24;
      default:
        return ReminderTimeFormat.system;
    }
  }

  Future<void> _syncJournalPrompt(UserSettings settings) async {
    if (!settings.journalPromptEnabled) {
      await _notifications.cancelJournalDailyPrompt();
      return;
    }

    await _notifications.scheduleJournalDailyPrompt(
      reminderTime: settings.journalReminderTime,
    );
  }
}
