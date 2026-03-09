import 'dart:convert';

enum HabitRecurrence { daily, weekly, monthly }

class Habit {
  final int? id;
  final String title;
  final String description;
  final HabitRecurrence recurrence;
  final String category;
  final bool reminderEnabled;
  final int? reminderHour;
  final int? reminderMinute;
  final int? reminderWeekday;
  final int? reminderDayOfMonth;
  final DateTime createdAt;
  final List<DateTime> completionDates;

  Habit({
    this.id,
    required this.title,
    this.description = '',
    this.recurrence = HabitRecurrence.daily,
    this.category = 'General',
    this.reminderEnabled = false,
    this.reminderHour,
    this.reminderMinute,
    this.reminderWeekday,
    this.reminderDayOfMonth,
    required this.createdAt,
    this.completionDates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'recurrence': recurrence.index,
      'category': category,
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'reminder_weekday': reminderWeekday,
      'reminder_day_of_month': reminderDayOfMonth,
      'created_at': createdAt.toIso8601String(),
      'completion_dates': jsonEncode(
        completionDates.map((d) => d.toIso8601String()).toList(),
      ),
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      recurrence: HabitRecurrence.values[map['recurrence'] ?? 0],
      category: map['category'] ?? 'General',
        reminderEnabled: (map['reminder_enabled'] ?? 0) == 1,
        reminderHour: map['reminder_hour'],
        reminderMinute: map['reminder_minute'],
        reminderWeekday: map['reminder_weekday'],
        reminderDayOfMonth: map['reminder_day_of_month'],
      createdAt: DateTime.parse(map['created_at']),
      completionDates: (jsonDecode(map['completion_dates'] ?? '[]') as List)
          .map((d) => DateTime.parse(d))
          .toList(),
    );
  }

  Habit copyWith({
    int? id,
    String? title,
    String? description,
    HabitRecurrence? recurrence,
    String? category,
    bool? reminderEnabled,
    Object? reminderHour = _unset,
    Object? reminderMinute = _unset,
    Object? reminderWeekday = _unset,
    Object? reminderDayOfMonth = _unset,
    DateTime? createdAt,
    List<DateTime>? completionDates,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      recurrence: recurrence ?? this.recurrence,
      category: category ?? this.category,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderHour: identical(reminderHour, _unset)
          ? this.reminderHour
          : reminderHour as int?,
        reminderMinute: identical(reminderMinute, _unset)
          ? this.reminderMinute
          : reminderMinute as int?,
        reminderWeekday: identical(reminderWeekday, _unset)
          ? this.reminderWeekday
          : reminderWeekday as int?,
        reminderDayOfMonth: identical(reminderDayOfMonth, _unset)
          ? this.reminderDayOfMonth
          : reminderDayOfMonth as int?,
      createdAt: createdAt ?? this.createdAt,
      completionDates: completionDates ?? this.completionDates,
    );
  }

      static const _unset = Object();
}
