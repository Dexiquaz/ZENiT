import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/time_picker_helper.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class EditHabitSheet extends ConsumerStatefulWidget {
  const EditHabitSheet({super.key, required this.habit});

  final Habit habit;

  @override
  ConsumerState<EditHabitSheet> createState() => _EditHabitSheetState();
}

class _EditHabitSheetState extends ConsumerState<EditHabitSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _categoryController;

  late HabitRecurrence _recurrence;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;
  late int _weeklyReminderWeekday;
  late int _monthlyReminderDay;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _titleController = TextEditingController(text: habit.title);
    _descController = TextEditingController(text: habit.description);
    _categoryController = TextEditingController(text: habit.category);

    _recurrence = habit.recurrence;
    _reminderEnabled = habit.reminderEnabled;
    _reminderTime = TimeOfDay(
      hour: habit.reminderHour ?? 21,
      minute: habit.reminderMinute ?? 0,
    );
    _weeklyReminderWeekday = (habit.reminderWeekday ?? DateTime.now().weekday)
        .clamp(1, 7)
        .toInt();
    _monthlyReminderDay = (habit.reminderDayOfMonth ?? DateTime.now().day)
        .clamp(1, 31)
        .toInt();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EDIT HABIT',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'CATEGORY',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'RECURRENCE',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
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
                  onChanged: (value) =>
                      setState(() => _reminderEnabled = value),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saveHabit,
                        child: const Text('SAVE CHANGES'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveHabit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final category = _categoryController.text.trim();
    final notifier = ref.read(habitListProvider.notifier);

    final updatedHabit = widget.habit.copyWith(
      title: title,
      description: _descController.text.trim(),
      category: category.isEmpty ? 'General' : category,
      recurrence: _recurrence,
      reminderEnabled: _reminderEnabled,
      reminderHour: _reminderEnabled ? _reminderTime.hour : null,
      reminderMinute: _reminderEnabled ? _reminderTime.minute : null,
      reminderWeekday: _reminderEnabled && _recurrence == HabitRecurrence.weekly
          ? _weeklyReminderWeekday
          : null,
      reminderDayOfMonth:
          _reminderEnabled && _recurrence == HabitRecurrence.monthly
          ? _monthlyReminderDay
          : null,
    );

    await notifier.updateHabit(updatedHabit);
    if (mounted) {
      Navigator.pop(context);
    }
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
    FocusScope.of(context).unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return null;

    return showZenitTimePicker(context: context, initialTime: _reminderTime);
  }
}
