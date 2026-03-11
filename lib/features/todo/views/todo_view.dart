import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../zen_mode/providers/focus_stats_provider.dart';
import '../models/task_model.dart';
import '../providers/todo_provider.dart';
import '../widgets/task_detail_dialog.dart';

class TodoView extends ConsumerWidget {
  const TodoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectListProvider);
    final tasksData = ref.watch(taskListProvider);
    final selectedProject = ref.watch(selectedProjectProvider);

    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: () => _showTaskEditor(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'ADD TASK',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Project chips
          SizedBox(
            height: 56,
            child: projects.when(
              data: (list) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  FilterChip(
                    label: const Text('ALL'),
                    selected: selectedProject == null,
                    onSelected: (selected) =>
                        ref.read(selectedProjectProvider.notifier).select(null),
                  ),
                  const SizedBox(width: 8),
                  ...list.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _ProjectChip(
                        project: p,
                        isSelected: selectedProject == p.id,
                        onSelected: (selected) => ref
                            .read(selectedProjectProvider.notifier)
                            .select(selected ? p.id : null),
                        onDeleted: () =>
                            _showDeleteProjectConfirm(context, ref, p),
                      ),
                    ),
                  ),
                  ActionChip(
                    label: const Text('+ CATEGORY'),
                    onPressed: () => _showAddProjectDialog(context, ref),
                  ),
                ],
              ),
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
            ),
          ),
          // Task list
          Expanded(
            child: tasksData.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'NO TASKS IN THIS PROJECT',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  );
                }

                int priorityScore(TaskPriority p) => switch (p) {
                  TaskPriority.high => 3,
                  TaskPriority.medium => 2,
                  TaskPriority.low => 1,
                };

                int compareTasks(Task a, Task b) {
                  // Keep pinned tasks at the top of the pending stack.
                  if (a.pinned && !b.pinned) return -1;
                  if (!a.pinned && b.pinned) return 1;

                  // 1. Put tasks with deadlines first
                  if (a.dueDate != null && b.dueDate == null) return -1;
                  if (a.dueDate == null && b.dueDate != null) return 1;

                  if (a.dueDate != null && b.dueDate != null) {
                    // 2. Compare only the Date (Y-M-D)
                    final dateA = DateTime(
                      a.dueDate!.year,
                      a.dueDate!.month,
                      a.dueDate!.day,
                    );
                    final dateB = DateTime(
                      b.dueDate!.year,
                      b.dueDate!.month,
                      b.dueDate!.day,
                    );
                    final dateComp = dateA.compareTo(dateB);
                    if (dateComp != 0) return dateComp;

                    // 3. Same day? Compare Priority (High > Med > Low)
                    final prioComp = priorityScore(
                      b.priority,
                    ).compareTo(priorityScore(a.priority));
                    if (prioComp != 0) return prioComp;

                    // 4. Same priority? Compare specific Time
                    return a.dueDate!.compareTo(b.dueDate!);
                  }

                  // No dates? Just compare priority
                  return priorityScore(
                    b.priority,
                  ).compareTo(priorityScore(a.priority));
                }

                final pending = list.where((t) => !t.completed).toList()
                  ..sort(compareTasks);
                final pinned = pending.where((t) => t.pinned).take(3).toList();

                final completed = list.where((t) => t.completed).toList()
                  ..sort(compareTasks);

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    if (pending.isNotEmpty) ...[
                      Card(
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOP 3 TODAY',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(letterSpacing: 1.2),
                              ),
                              const SizedBox(height: 10),
                              if (pinned.isEmpty)
                                Text(
                                  'Pin up to 3 tasks to stay focused on what matters most.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              else
                                ...pinned.map(
                                  (task) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.push_pin, size: 14),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ...pending.map((t) => _TaskTile(task: t)),
                    if (completed.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 24, bottom: 8, left: 8),
                        child: Text('COMPLETED'),
                      ),
                      ...completed.map((t) => _TaskTile(task: t)),
                    ],
                    const SizedBox(height: 16),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('ERROR // $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTaskEditor(
    BuildContext context,
    WidgetRef ref, [
    Task? task,
  ]) async {
    final selectedProject = ref.read(selectedProjectProvider);
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) =>
          TaskDetailDialog(task: task, initialProjectId: selectedProject),
    );

    if (result != null) {
      if (task == null) {
        ref.read(taskListProvider.notifier).addTask(result);
      } else {
        ref.read(taskListProvider.notifier).updateTask(result);
      }
    }
  }

  void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('NEW PROJECT'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'PROJECT NAME'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(projectListProvider.notifier)
                    .addProject(controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteProjectConfirm(
    BuildContext context,
    WidgetRef ref,
    Project project,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DELETE PROJECT?'),
        content: Text(
          'ARE YOU SURE YOU WANT TO DELETE "${project.name}"? THIS WILL ALSO DELETE ALL TASKS WITHIN IT.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              ref.read(projectListProvider.notifier).deleteProject(project.id!);
              Navigator.pop(ctx);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final Task task;
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusStats = task.id == null
        ? null
        : ref.watch(taskFocusStatsProvider(task.id!));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: task.completed
          ? Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          : Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () =>
            (context.findAncestorWidgetOfExactType<TodoView>() as TodoView)
                ._showTaskEditor(context, ref, task),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              // Checkbox - centered
              SizedBox(
                height: double.infinity,
                child: Center(
                  child: Checkbox(
                    value: task.completed,
                    onChanged: (v) =>
                        ref.read(taskListProvider.notifier).toggleTask(task),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Title and subtitle - expanded
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.completed
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (focusStats != null) ...[
                      const SizedBox(height: 4),
                      focusStats.when(
                        data: (stats) => Text(
                          'Today: ${stats.todayMinutes} min • This week: ${stats.weekCycles} cycles',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        loading: () => Text(
                          'Loading focus stats...',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        error: (_, __) => Text(
                          'Focus stats unavailable',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 13,
                            color:
                                task.dueDate!.isBefore(DateTime.now()) &&
                                    !task.completed
                                ? const Color(0xFFFB7185)
                                : const Color(0xFFFACC15),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${task.dueDate!.year}.${task.dueDate!.month.toString().padLeft(2, '0')}.${task.dueDate!.day.toString().padLeft(2, '0')} @ ${task.dueDate!.hour.toString().padLeft(2, '0')}:${task.dueDate!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color:
                                  task.dueDate!.isBefore(DateTime.now()) &&
                                      !task.completed
                                  ? const Color(0xFFFB7185)
                                  : const Color(0xFFFACC15),
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      if (task.reminderAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 13,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Reminder enabled',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Priority chip and icons - centered
              SizedBox(
                height: double.infinity,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PriorityChip(priority: task.priority),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 24,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: task.pinned ? 'UNPIN' : 'PIN TO TOP 3',
                            icon: Icon(
                              task.pinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              size: 18,
                              color: task.pinned
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: task.completed
                                ? null
                                : () async {
                                    final ok = await ref
                                        .read(taskListProvider.notifier)
                                        .setTaskPinned(task, !task.pinned);
                                    if (!ok && context.mounted) {
                                      showSnackBar(
                                        context,
                                        'You can pin up to 3 active tasks only.',
                                      );
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 24,
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => ref
                                .read(taskListProvider.notifier)
                                .deleteTask(task.id!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (priority) {
      TaskPriority.low => ('LOW', const Color(0xFF64748B)),
      TaskPriority.medium => ('MED', const Color(0xFF0EA5E9)),
      TaskPriority.high => ('HIGH', const Color(0xFFF43F5E)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ProjectChip extends StatefulWidget {
  final Project project;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onDeleted;

  const _ProjectChip({
    required this.project,
    required this.isSelected,
    required this.onSelected,
    required this.onDeleted,
  });

  @override
  State<_ProjectChip> createState() => _ProjectChipState();
}

class _ProjectChipState extends State<_ProjectChip> {
  bool _isHovered = false;
  bool _isLongPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onLongPress: () {
          setState(() => _isLongPressed = true);
          // Haptic feedback is usually expected with long press
          Feedback.forLongPress(context);
        },
        child: FilterChip(
          label: Text('${widget.project.name} (${widget.project.taskCount})'),
          selected: widget.isSelected,
          onSelected: (selected) {
            if (_isLongPressed) {
              setState(() => _isLongPressed = false);
            }
            widget.onSelected(selected);
          },
          onDeleted: (_isHovered || _isLongPressed)
              ? () {
                  setState(() => _isLongPressed = false);
                  widget.onDeleted();
                }
              : null,
          deleteIconColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
