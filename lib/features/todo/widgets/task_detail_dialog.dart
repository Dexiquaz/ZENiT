import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskDetailDialog extends StatefulWidget {
  final Task? task;
  final int? initialProjectId;

  const TaskDetailDialog({super.key, this.task, this.initialProjectId});

  @override
  State<TaskDetailDialog> createState() => _TaskDetailDialogState();
}

class _TaskDetailDialogState extends State<TaskDetailDialog> {
  late final TextEditingController _titleController;
  late TaskPriority _priority;
  DateTime? _dueDate;
  bool _remindAtDeadline = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _priority = widget.task?.priority ?? TaskPriority.low;
    _dueDate = widget.task?.dueDate;
    _remindAtDeadline = widget.task?.reminderAt != null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'NEW TASK' : 'EDIT TASK'),
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
              autofocus: widget.task == null,
            ),
            const SizedBox(height: 24),
            Text('PRIORITY', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: const [
                ButtonSegment(value: TaskPriority.low, label: Text('LOW')),
                ButtonSegment(value: TaskPriority.medium, label: Text('MED')),
                ButtonSegment(value: TaskPriority.high, label: Text('HIGH')),
              ],
              selected: {_priority},
              onSelectionChanged: (v) => setState(() => _priority = v.first),
            ),
            const SizedBox(height: 24),
            Text('DEADLINE', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() {
                          _dueDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            _dueDate?.hour ?? 0,
                            _dueDate?.minute ?? 0,
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _dueDate == null
                          ? 'SELECT DATE'
                          : '${_dueDate!.year}.${_dueDate!.month.toString().padLeft(2, '0')}.${_dueDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                if (_dueDate != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            _dueDate ?? DateTime.now(),
                          ),
                        );
                        if (time != null) {
                          setState(() {
                            _dueDate = DateTime(
                              _dueDate!.year,
                              _dueDate!.month,
                              _dueDate!.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        '${_dueDate!.hour.toString().padLeft(2, '0')}:${_dueDate!.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_dueDate != null)
              SwitchListTile.adaptive(
                value: _remindAtDeadline,
                title: const Text('REMIND AT DEADLINE'),
                subtitle: const Text('Send a local notification on due time'),
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _remindAtDeadline = v),
              ),
            if (_dueDate != null)
              TextButton.icon(
                onPressed: () => setState(() {
                  _dueDate = null;
                  _remindAtDeadline = false;
                }),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('CLEAR DEADLINE'),
              ),
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
              final result =
                  widget.task?.copyWith(
                    title: _titleController.text,
                    priority: _priority,
                    dueDate: _dueDate,
                    reminderAt: _remindAtDeadline ? _dueDate : null,
                  ) ??
                  Task(
                    title: _titleController.text,
                    priority: _priority,
                    dueDate: _dueDate,
                    reminderAt: _remindAtDeadline ? _dueDate : null,
                    projectId: widget.initialProjectId,
                    createdAt: DateTime.now(),
                  );
              Navigator.pop(context, result);
            }
          },
          child: Text(widget.task == null ? 'CREATE' : 'SAVE'),
        ),
      ],
    );
  }
}
