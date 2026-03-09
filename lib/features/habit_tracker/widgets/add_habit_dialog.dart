import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../../../shared/utils/time_picker_helper.dart';

class AddHabitDialog extends ConsumerStatefulWidget {
  const AddHabitDialog({super.key});

  @override
  ConsumerState<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends ConsumerState<AddHabitDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  HabitRecurrence _recurrence = HabitRecurrence.daily;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  int _weeklyReminderWeekday = DateTime.now().weekday;
  int _monthlyReminderDay = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('NEW HABIT'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'TITLE',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'DESCRIPTION',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Text('RECURRENCE', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<HabitRecurrence>(
                showSelectedIcon: false,
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(
                    Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
                segments: HabitRecurrence.values.map((r) {
                  return ButtonSegment<HabitRecurrence>(
                    value: r,
                    label: Text(
                      r.name.toUpperCase(),
                      softWrap: false,
                      overflow: TextOverflow.fade,
                    ),
                  );
                }).toList(),
                selected: {_recurrence},
                onSelectionChanged: (set) {
                  setState(() => _recurrence = set.first);
                },
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('ENABLE REMINDER'),
              subtitle: const Text('Schedule notifications for this habit'),
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final selected = await _showReminderTimePicker(context);
                  if (selected != null) {
                    setState(() => _reminderTime = selected);
                  }
                },
                icon: const Icon(Icons.access_time_outlined, size: 18),
                label: Text('TIME ${_formatTime(_reminderTime)}'),
              ),
              if (_recurrence == HabitRecurrence.weekly) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _weeklyReminderWeekday,
                  decoration: const InputDecoration(
                    labelText: 'WEEKDAY',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(7, (i) => i + 1).map((weekday) {
                    return DropdownMenuItem<int>(
                      value: weekday,
                      child: Text(_weekdayLabel(weekday)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _weeklyReminderWeekday = value);
                    }
                  },
                ),
              ],
              if (_recurrence == HabitRecurrence.monthly) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _monthlyReminderDay,
                  decoration: const InputDecoration(
                    labelText: 'DAY OF MONTH',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(31, (i) => i + 1).map((day) {
                    return DropdownMenuItem<int>(
                      value: day,
                      child: Text('DAY $day'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _monthlyReminderDay = value);
                    }
                  },
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              final newHabit = Habit(
                title: _titleController.text,
                description: _descController.text,
                recurrence: _recurrence,
                reminderEnabled: _reminderEnabled,
                reminderHour: _reminderEnabled ? _reminderTime.hour : null,
                reminderMinute: _reminderEnabled ? _reminderTime.minute : null,
                reminderWeekday: _recurrence == HabitRecurrence.weekly
                    ? _weeklyReminderWeekday
                    : null,
                reminderDayOfMonth: _recurrence == HabitRecurrence.monthly
                    ? _monthlyReminderDay
                    : null,
                createdAt: DateTime.now(),
              );
              ref.read(habitListProvider.notifier).addHabit(newHabit);
              Navigator.pop(context);
            }
          },
          child: const Text('CREATE'),
        ),
      ],
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _weekdayLabel(int weekday) {
    const labels = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return labels[weekday - 1];
  }

  Future<TimeOfDay?> _showReminderTimePicker(BuildContext context) async {
    // Close any active text field keyboard to avoid constrained picker layouts.
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return null;

    return showZenitTimePicker(context: context, initialTime: _reminderTime);
  }
}
