import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/database_helper.dart';

final habitListProvider = AsyncNotifierProvider<HabitNotifier, List<Habit>>(
  HabitNotifier.new,
);

class HabitNotifier extends AsyncNotifier<List<Habit>> {
  final _dbHelper = DatabaseHelper();
  final _notifications = NotificationService.instance;

  @override
  Future<List<Habit>> build() async {
    final habits = await _dbHelper.getHabits();
    await _syncAllHabitReminders(habits);
    return habits;
  }

  Future<void> resyncHabitReminders() async {
    final habits = await _dbHelper.getHabits();
    await _syncAllHabitReminders(habits);
  }

  Future<void> addHabit(Habit habit) async {
    final id = await _dbHelper.insertHabit(habit);
    await _syncHabitReminder(habit.copyWith(id: id));
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateHabit(Habit habit) async {
    await _dbHelper.updateHabit(habit);
    await _syncHabitReminder(habit);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggleHabitCompletion(Habit habit, DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final List<DateTime> newCompletionDates = List.from(habit.completionDates);

    final index = newCompletionDates.indexWhere(
      (d) =>
          d.year == dateOnly.year &&
          d.month == dateOnly.month &&
          d.day == dateOnly.day,
    );

    if (index != -1) {
      newCompletionDates.removeAt(index);
    } else {
      newCompletionDates.add(dateOnly);
    }

    final updatedHabit = habit.copyWith(completionDates: newCompletionDates);
    await _dbHelper.updateHabit(updatedHabit);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteHabit(int id) async {
    await _notifications.cancelHabitReminder(id);
    await _dbHelper.deleteHabit(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> _syncAllHabitReminders(List<Habit> habits) async {
    for (final habit in habits) {
      await _syncHabitReminder(habit);
    }
  }

  Future<void> _syncHabitReminder(Habit habit) async {
    if (habit.id == null) return;

    await _notifications.cancelHabitReminder(habit.id!);

    if (!habit.reminderEnabled ||
        habit.reminderHour == null ||
        habit.reminderMinute == null) {
      return;
    }

    await _notifications.scheduleHabitReminder(
      habitId: habit.id!,
      habitTitle: habit.title,
      recurrence: _toReminderRecurrence(habit.recurrence),
      reminderTime: TimeOfDay(
        hour: habit.reminderHour!,
        minute: habit.reminderMinute!,
      ),
      weekday: habit.reminderWeekday,
      dayOfMonth: habit.reminderDayOfMonth,
    );
  }

  ReminderRecurrenceType _toReminderRecurrence(HabitRecurrence recurrence) {
    switch (recurrence) {
      case HabitRecurrence.daily:
        return ReminderRecurrenceType.daily;
      case HabitRecurrence.weekly:
        return ReminderRecurrenceType.weekly;
      case HabitRecurrence.monthly:
        return ReminderRecurrenceType.monthly;
    }
  }
}
