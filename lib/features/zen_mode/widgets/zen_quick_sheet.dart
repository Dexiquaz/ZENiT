import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/module_state_view.dart';
import '../../todo/models/task_model.dart';
import '../../todo/providers/todo_provider.dart';
import '../providers/zen_mode_provider.dart';
import '../views/zen_ambient_view.dart';

void showZenQuickSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) {
      return const _ZenQuickSheet();
    },
  );
}

class _ZenQuickSheet extends ConsumerWidget {
  const _ZenQuickSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zenTimerProvider);
    final notifier = ref.read(zenTimerProvider.notifier);
    final taskState = ref.watch(allTaskListProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'ZEN MODE',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.isRunning
                  ? '${state.phaseLabel} session is active'
                  : state.isIdle
                  ? 'Ready for a fresh focus sprint'
                  : '${state.phaseLabel} session paused',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.hasLinkedTask) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.linkedTaskTitle ?? 'Linked task',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Text(
                        'Quick Focus (no linked task)',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Icon(
                          Icons.timelapse,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.phaseLabel,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          state.timeLabel,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: state.progress,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${state.completedFocusSessions} focus cycles completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!state.isRunning) ...[
              const SizedBox(height: 4),
              taskState.when(
                data: (tasks) {
                  final pendingTasks = tasks
                      .where((task) => !task.completed)
                      .toList();

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: pendingTasks.isEmpty
                            ? null
                            : () => _showTaskPicker(
                                context,
                                pendingTasks,
                                state.linkedTaskId,
                                notifier,
                              ),
                        icon: const Icon(Icons.playlist_add_check),
                        label: Text(
                          state.hasLinkedTask ? 'CHANGE TASK' : 'SELECT TASK',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: state.hasLinkedTask
                            ? () => notifier.clearLinkedTask()
                            : null,
                        icon: const Icon(Icons.close),
                        label: const Text('CLEAR'),
                      ),
                    ],
                  );
                },
                loading: () =>
                    const ModuleInlineLoadingState(label: 'Loading tasks'),
                error: (_, __) => ModuleInlineErrorState(
                  label: 'Could not load tasks right now.',
                  onRetry: () => ref.invalidate(allTaskListProvider),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (state.isRunning)
                  FilledButton.icon(
                    onPressed: () => notifier.pause(),
                    icon: const Icon(Icons.pause),
                    label: const Text('PAUSE'),
                  )
                else if (!state.isIdle)
                  FilledButton.icon(
                    onPressed: () => notifier.resume(),
                    icon: const Icon(Icons.play_circle),
                    label: const Text('RESUME'),
                  )
                else ...[
                  FilledButton.icon(
                    onPressed: state.linkedTaskId == null
                        ? null
                        : () => _startLinkedFocus(context, notifier),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('START WITH TASK'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _startQuickFocus(context, notifier),
                    icon: const Icon(Icons.flash_on),
                    label: const Text('QUICK FOCUS'),
                  ),
                ],
                OutlinedButton.icon(
                  onPressed: state.hasStarted ? () => notifier.reset() : null,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('RESET'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isRunning || state.hasStarted
                      ? () => notifier.skipPhase()
                      : null,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('SKIP'),
                ),
                if (state.activeSessionId != null)
                  OutlinedButton.icon(
                    onPressed: () => _openAmbientAfterSheetClose(context),
                    icon: const Icon(Icons.flip),
                    label: const Text('AMBIENT VIEW'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startLinkedFocus(
    BuildContext context,
    ZenTimerNotifier notifier,
  ) async {
    final result = await notifier.startLinkedFocus();
    if (!context.mounted) return;

    switch (result) {
      case FocusStartResult.started:
        await _openAmbientAfterSheetClose(context);
        return;
      case FocusStartResult.missingLinkedTask:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a task to begin linked focus.')),
        );
      case FocusStartResult.linkedTaskUnavailable:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Linked task is no longer available. Select another.',
            ),
          ),
        );
    }
  }

  Future<void> _startQuickFocus(
    BuildContext context,
    ZenTimerNotifier notifier,
  ) async {
    final result = await notifier.startQuickFocus();
    if (!context.mounted) {
      return;
    }

    if (result == FocusStartResult.started) {
      await _openAmbientAfterSheetClose(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to start quick focus right now.')),
    );
  }

  Future<void> _openAmbientAfterSheetClose(BuildContext context) async {
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final sheetNavigator = Navigator.of(context);

    if (sheetNavigator.canPop()) {
      sheetNavigator.pop();
    }

    await Future<void>.delayed(Duration.zero);
    await WidgetsBinding.instance.endOfFrame;
    if (!rootNavigator.mounted) {
      return;
    }

    await rootNavigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const ZenAmbientView(),
        settings: const RouteSettings(name: 'zen_ambient_focus'),
      ),
    );
  }

  Future<void> _showTaskPicker(
    BuildContext context,
    List<Task> tasks,
    int? selectedTaskId,
    ZenTimerNotifier notifier,
  ) async {
    final selectedTask = await showModalBottomSheet<Task>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                leading: Icon(
                  task.id == selectedTaskId
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                ),
                title: Text(task.title),
                subtitle: task.dueDate != null
                    ? Text(
                        'Due ${task.dueDate!.year}.${task.dueDate!.month.toString().padLeft(2, '0')}.${task.dueDate!.day.toString().padLeft(2, '0')}',
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(task),
              );
            },
          ),
        );
      },
    );

    if (selectedTask != null) {
      await notifier.setLinkedTask(
        taskId: selectedTask.id,
        taskTitle: selectedTask.title,
      );
    }
  }
}
