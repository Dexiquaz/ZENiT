import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/secure_storage_helper.dart';
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
  final bool hasCompletedOnboarding;

  UserSettings({
    this.currency = r'$',
    this.journalPromptEnabled = true,
    this.journalReminderHour = 21,
    this.journalReminderMinute = 0,
    this.reminderTimeFormat = ReminderTimeFormat.system,
    this.focusDurationMinutes = 25,
    this.breakDurationMinutes = 5,
    this.silentFocusNotifications = true,
    this.hasCompletedOnboarding = false,
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
    bool? hasCompletedOnboarding,
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
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
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
      'hasCompletedOnboarding': hasCompletedOnboarding,
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
    final hasCompletedOnboarding =
        (map['hasCompletedOnboarding'] as bool?) ?? false;

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
      hasCompletedOnboarding: hasCompletedOnboarding,
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
  static const _hasCompletedOnboardingKey = 'setting_has_completed_onboarding';

  final _notifications = NotificationService.instance;

  @override
  Future<UserSettings> build() async {
    final currency = await SecureStorageHelper.getString(_currencyKey) ?? r'$';
    final journalPromptEnabled =
        await SecureStorageHelper.getBool(_journalPromptEnabledKey) ?? true;
    final journalReminderHour =
        await SecureStorageHelper.getInt(_journalReminderHourKey) ?? 21;
    final journalReminderMinute =
        await SecureStorageHelper.getInt(_journalReminderMinuteKey) ?? 0;
    final reminderTimeFormat = _parseTimeFormat(
      await SecureStorageHelper.getString(_reminderTimeFormatKey),
    );
    final focusDurationMinutes =
        await SecureStorageHelper.getInt(_focusDurationMinutesKey) ?? 25;
    final breakDurationMinutes =
        await SecureStorageHelper.getInt(_breakDurationMinutesKey) ?? 5;
    final silentFocusNotifications =
        await SecureStorageHelper.getBool(_silentFocusNotificationsKey) ?? true;
    final hasCompletedOnboarding =
        await SecureStorageHelper.getBool(_hasCompletedOnboardingKey) ?? false;

    final settings = UserSettings(
      currency: currency,
      journalPromptEnabled: journalPromptEnabled,
      journalReminderHour: journalReminderHour,
      journalReminderMinute: journalReminderMinute,
      reminderTimeFormat: reminderTimeFormat,
      focusDurationMinutes: focusDurationMinutes,
      breakDurationMinutes: breakDurationMinutes,
      silentFocusNotifications: silentFocusNotifications,
      hasCompletedOnboarding: hasCompletedOnboarding,
    );
    await _syncJournalPrompt(settings);

    return settings;
  }

  Future<void> setCurrency(String c) async {
    await SecureStorageHelper.setString(_currencyKey, c);
    if (state.hasValue) {
      state = AsyncData(state.value!.copyWith(currency: c));
    }
  }

  Future<void> setJournalPromptEnabled(bool enabled) async {
    await SecureStorageHelper.setBool(_journalPromptEnabledKey, enabled);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(journalPromptEnabled: enabled);
    state = AsyncData(updated);
    await _syncJournalPrompt(updated);
  }

  Future<void> setJournalReminderTime(TimeOfDay time) async {
    await SecureStorageHelper.setInt(_journalReminderHourKey, time.hour);
    await SecureStorageHelper.setInt(_journalReminderMinuteKey, time.minute);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(
      journalReminderHour: time.hour,
      journalReminderMinute: time.minute,
    );
    state = AsyncData(updated);
    await _syncJournalPrompt(updated);
  }

  Future<void> setReminderTimeFormat(ReminderTimeFormat format) async {
    await SecureStorageHelper.setString(_reminderTimeFormatKey, format.name);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(reminderTimeFormat: format);
    state = AsyncData(updated);
  }

  Future<void> setFocusDuration(int minutes) async {
    final clamped = minutes.clamp(1, 60).toInt();
    await SecureStorageHelper.setInt(_focusDurationMinutesKey, clamped);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(focusDurationMinutes: clamped);
    state = AsyncData(updated);
  }

  Future<void> setBreakDuration(int minutes) async {
    final clamped = minutes.clamp(1, 30).toInt();
    await SecureStorageHelper.setInt(_breakDurationMinutesKey, clamped);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(breakDurationMinutes: clamped);
    state = AsyncData(updated);
  }

  Future<void> setSilentFocusNotifications(bool enabled) async {
    await SecureStorageHelper.setBool(_silentFocusNotificationsKey, enabled);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(silentFocusNotifications: enabled);
    state = AsyncData(updated);
  }

  Future<void> setHasCompletedOnboarding(bool completed) async {
    await SecureStorageHelper.setBool(_hasCompletedOnboardingKey, completed);

    final current = state.hasValue ? state.value! : UserSettings();
    final updated = current.copyWith(hasCompletedOnboarding: completed);
    state = AsyncData(updated);
  }

  Future<void> resyncJournalPrompt() async {
    final current = state.hasValue ? state.value! : await future;
    await _syncJournalPrompt(current);
  }

  Future<void> resetToDefaults() async {
    await SecureStorageHelper.remove(_currencyKey);
    await SecureStorageHelper.remove(_journalPromptEnabledKey);
    await SecureStorageHelper.remove(_journalReminderHourKey);
    await SecureStorageHelper.remove(_journalReminderMinuteKey);
    await SecureStorageHelper.remove(_reminderTimeFormatKey);
    await SecureStorageHelper.remove(_focusDurationMinutesKey);
    await SecureStorageHelper.remove(_breakDurationMinutesKey);
    await SecureStorageHelper.remove(_silentFocusNotificationsKey);
    await SecureStorageHelper.remove(_hasCompletedOnboardingKey);

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

    await SecureStorageHelper.setString(_currencyKey, restored.currency);
    await SecureStorageHelper.setBool(
      _journalPromptEnabledKey,
      restored.journalPromptEnabled,
    );
    await SecureStorageHelper.setInt(
      _journalReminderHourKey,
      restored.journalReminderHour,
    );
    await SecureStorageHelper.setInt(
      _journalReminderMinuteKey,
      restored.journalReminderMinute,
    );
    await SecureStorageHelper.setString(
      _reminderTimeFormatKey,
      restored.reminderTimeFormat.name,
    );
    await SecureStorageHelper.setInt(
      _focusDurationMinutesKey,
      restored.focusDurationMinutes,
    );
    await SecureStorageHelper.setInt(
      _breakDurationMinutesKey,
      restored.breakDurationMinutes,
    );
    await SecureStorageHelper.setBool(
      _silentFocusNotificationsKey,
      restored.silentFocusNotifications,
    );
    await SecureStorageHelper.setBool(
      _hasCompletedOnboardingKey,
      restored.hasCompletedOnboarding,
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
