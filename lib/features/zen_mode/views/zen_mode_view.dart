import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/settings_provider.dart';
import '../../../shared/widgets/module_state_view.dart';
import '../../todo/models/task_model.dart';
import '../../todo/providers/todo_provider.dart';
import '../models/focus_session.dart';
import '../providers/focus_history_provider.dart';
import '../providers/focus_stats_provider.dart';
import '../providers/zen_mode_provider.dart';
import 'zen_ambient_view.dart';

class ZenModeView extends ConsumerWidget {
  const ZenModeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zenTimerProvider);
    final notifier = ref.read(zenTimerProvider.notifier);
    final taskState = ref.watch(allTaskListProvider);
    final linkedTaskStats = state.linkedTaskId == null
        ? null
        : ref.watch(taskFocusStatsProvider(state.linkedTaskId!));
    final recentSessions = ref.watch(recentFocusSessionsProvider);
    final settingsState = ref.watch(settingsProvider);
    final focusMinutes = state.focusDuration.inMinutes.clamp(1, 60).toInt();
    final breakMinutes = state.breakDuration.inMinutes.clamp(1, 30).toInt();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              'FOCUS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timelapse,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          state.phaseLabel,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                        ),
                        const Spacer(),
                        Text(
                          state.timeLabel,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: state.progress,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                    if (state.hasLinkedTask) ...[
                      const SizedBox(height: 8),
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
                    ],
                    const SizedBox(height: 6),
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
            const SizedBox(height: 16),
            Text(
              'LINKED TASK',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: taskState.when(
                  data: (tasks) {
                    final pendingTasks = tasks
                        .where((task) => !task.completed)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.hasLinkedTask
                              ? (state.linkedTaskTitle ?? 'Linked task')
                              : 'No task selected',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isRunning
                              ? 'Task is locked while the timer is running.'
                              : 'Link a task for tracked work, or use Quick Focus anytime.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: state.isRunning || pendingTasks.isEmpty
                                  ? null
                                  : () => _showTaskPicker(
                                      context,
                                      pendingTasks,
                                      state.linkedTaskId,
                                      notifier,
                                    ),
                              icon: const Icon(Icons.playlist_add_check),
                              label: const Text('SELECT TASK'),
                            ),
                            OutlinedButton.icon(
                              onPressed: state.isRunning || !state.hasLinkedTask
                                  ? null
                                  : () => notifier.clearLinkedTask(),
                              icon: const Icon(Icons.close),
                              label: const Text('CLEAR'),
                            ),
                          ],
                        ),
                        if (pendingTasks.isEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            'No pending tasks available. Add a task first.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () => const ModuleLoadingState(
                    title: 'Loading tasks',
                    subtitle: 'Preparing linked task options.',
                  ),
                  error: (_, __) => ModuleErrorState(
                    title: 'Could not load tasks',
                    subtitle: 'Please try refreshing task data.',
                    onRetry: () => ref.invalidate(allTaskListProvider),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                    onPressed: () => openZenAmbientView(context),
                    icon: const Icon(Icons.flip),
                    label: const Text('AMBIENT VIEW'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: settingsState.when(
                data: (settings) => SwitchListTile.adaptive(
                  value: settings.silentFocusNotifications,
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setSilentFocusNotifications(value),
                  title: const Text('SILENT FOCUS'),
                  subtitle: const Text(
                    'Suppress ZENiT reminders while a focus session is active.',
                  ),
                ),
                loading: () => const ListTile(
                  title: Text('SILENT FOCUS'),
                  subtitle: Text('Loading preference...'),
                ),
                error: (_, __) => const ListTile(
                  title: Text('SILENT FOCUS'),
                  subtitle: Text('Preference unavailable right now.'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'RECENT SESSIONS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: recentSessions.when(
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return Text(
                        'No focus sessions yet. Start one to build momentum.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    }

                    return Column(
                      children: sessions
                          .map(
                            (session) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: Icon(
                                Icons.history,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(
                                session.taskTitleSnapshot?.isNotEmpty == true
                                    ? session.taskTitleSnapshot!
                                    : 'Quick Focus',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '${_formatSessionDate(session.startedAt)} • ${_sessionMinutesLabel(session)} • ${session.completedFocusSessions} cycles • ${_statusLabel(session.status)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                  loading: () => const ModuleLoadingState(
                    title: 'Loading session history',
                    subtitle: 'Fetching your recent focus runs.',
                  ),
                  error: (_, __) => ModuleErrorState(
                    title: 'Could not load session history',
                    subtitle: 'Please try again.',
                    onRetry: () => ref.invalidate(recentFocusSessionsProvider),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'SESSION TIMING',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Duration',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: focusMinutes.toDouble(),
                            min: 1,
                            max: 60,
                            divisions: 59,
                            label: '$focusMinutes min',
                            onChanged: state.isRunning
                                ? null
                                : (value) => notifier.updateFocusDuration(
                                    value.toInt(),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '$focusMinutes min',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Break Duration',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: breakMinutes.toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label: '$breakMinutes min',
                            onChanged: state.isRunning
                                ? null
                                : (value) => notifier.updateBreakDuration(
                                    value.toInt(),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 50,
                          child: Text(
                            '$breakMinutes min',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (linkedTaskStats != null) ...[
              const SizedBox(height: 4),
              linkedTaskStats.when(
                data: (stats) => Text(
                  'Today: ${stats.todayMinutes} min • This week: ${stats.weekCycles} cycles',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                loading: () => const ModuleInlineLoadingState(
                  label: 'Loading focus stats',
                ),
                error: (_, __) => const ModuleInlineErrorState(
                  label: 'Focus stats unavailable',
                ),
              ),
            ],
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
        await openZenAmbientView(context);
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
      await openZenAmbientView(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to start quick focus right now.')),
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

  String _statusLabel(FocusSessionStatus status) {
    switch (status) {
      case FocusSessionStatus.running:
        return 'running';
      case FocusSessionStatus.paused:
        return 'paused';
      case FocusSessionStatus.completed:
        return 'completed';
      case FocusSessionStatus.cancelled:
        return 'cancelled';
    }
  }

  String _sessionMinutesLabel(FocusSession session) {
    final minutes =
        (session.focusDuration.inSeconds * session.completedFocusSessions) ~/
        60;
    return '$minutes min';
  }

  String _formatSessionDate(DateTime timestamp) {
    final year = timestamp.year.toString();
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$year.$month.$day $hour:$minute';
  }
}
