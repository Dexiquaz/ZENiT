import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/module_state_view.dart';
import '../../habit_tracker/providers/habit_provider.dart';
import '../../habit_tracker/models/habit.dart';
import '../../todo/providers/todo_provider.dart';
import '../../todo/models/task_model.dart';
import '../../notes_shopping/providers/notes_provider.dart';
import '../../notes_shopping/models/models.dart';
import '../../zen_mode/providers/zen_mode_provider.dart';
import '../../zen_mode/widgets/zen_quick_sheet.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  bool _isLoadedAndEmpty<T>(AsyncValue<List<T>> state) {
    return state.when(
      data: (items) => items.isEmpty,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitState = ref.watch(habitListProvider);
    final taskState = ref.watch(taskListProvider);
    final journalState = ref.watch(journalProvider);
    final noteState = ref.watch(noteListProvider);
    final zenState = ref.watch(zenTimerProvider);

    final isFirstRunEmptyState =
        _isLoadedAndEmpty(habitState) &&
        _isLoadedAndEmpty(taskState) &&
        _isLoadedAndEmpty(journalState) &&
        _isLoadedAndEmpty(noteState);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR PRIVATE DAILY OS',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No account required. Your data stays on your device.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'FOCUS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _ModuleButton(
              title: 'ZEN MODE',
              icon: zenState.isRunning ? Icons.timer : Icons.timer_outlined,
              onTap: () => showZenQuickSheet(context),
              summaryValue: zenState.timeLabel,
              summarySubtitle: zenState.hasLinkedTask
                  ? '${zenState.phaseLabel} • linked'
                  : zenState.phaseLabel,
              details: Text(
                zenState.hasLinkedTask
                    ? '${zenState.linkedTaskTitle} • ${zenState.completedFocusSessions} cycles completed'
                    : zenState.isRunning
                    ? 'Focus engine active. Tap to control session flow.'
                    : zenState.isIdle
                    ? 'Start a 25-minute focus sprint.'
                    : 'Session paused. Resume when ready.',
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'MODULES',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 2.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (isFirstRunEmptyState)
              const _FirstRunModulesState()
            else
              _buildNavigationStack(
                context,
                habitState,
                taskState,
                journalState,
                noteState,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationStack(
    BuildContext context,
    AsyncValue<List<Habit>> habitState,
    AsyncValue<List<Task>> taskState,
    AsyncValue<List<JournalEntry>> journalState,
    AsyncValue<List<Note>> noteState,
  ) {
    return Column(
      children: [
        habitState.when(
          data: (habits) {
            final today = DateTime.now();
            final pending = habits.where((h) {
              return !h.completionDates.any((d) => isSameDay(d, today));
            }).toList();
            final completedTodayCount = habits.length - pending.length;
            final hasPending = pending.isNotEmpty;

            return _ModuleButton(
              title: 'HABITS',
              icon: Icons.track_changes_outlined,
              navigationPath: '/habits',
              summaryValue: '$completedTodayCount / ${habits.length}',
              summarySubtitle: 'today',
              details: habits.isEmpty
                  ? const Text('No habits yet. Add your first habit')
                  : hasPending
                  ? Text(
                      'Pending: ${pending.take(2).map((h) => h.title).join(', ')}${pending.length > 2 ? '...' : ''}',
                    )
                  : const Text('All daily habits completed.'),
            );
          },
          loading: () => const _ModuleButtonSkeleton(
            title: 'HABITS',
            icon: Icons.track_changes_outlined,
          ),
          error: (_, __) => _ModuleButton(
            title: 'HABITS',
            icon: Icons.error_outline,
            navigationPath: '/habits',
            summaryValue: 'ERR',
            summarySubtitle: 'issue',
            details: const Text('Could not load habits. Tap to open module.'),
          ),
        ),
        const SizedBox(height: 16),
        taskState.when(
          data: (tasks) {
            final pending = tasks.where((t) => !t.completed).toList();
            final pinned = pending.where((t) => t.pinned).take(3).toList();
            return _ModuleButton(
              title: 'TASKS',
              icon: Icons.checklist_rtl_outlined,
              navigationPath: '/tasks',
              summaryValue: '${pending.length}',
              summarySubtitle: pinned.isEmpty
                  ? 'pending'
                  : 'pending • top ${pinned.length}',
              details: pending.isEmpty
                  ? const Text('All tasks completed.')
                  : pinned.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pinned
                          .map(
                            (t) => Text(
                              'Top: ${t.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                          .toList(),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pending
                          .take(2)
                          .map(
                            (t) => Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 4,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
            );
          },
          loading: () => const _ModuleButtonSkeleton(
            title: 'TASKS',
            icon: Icons.checklist_rtl_outlined,
          ),
          error: (_, __) => _ModuleButton(
            title: 'TASKS',
            icon: Icons.error_outline,
            navigationPath: '/tasks',
            summaryValue: 'ERR',
            summarySubtitle: 'issue',
            details: const Text('Could not load tasks. Tap to open module.'),
          ),
        ),
        const SizedBox(height: 16),
        journalState.when(
          data: (entries) => _ModuleButton(
            title: 'CALENDAR',
            icon: Icons.calendar_month_outlined,
            navigationPath: '/calendar',
            summaryValue: entries.isNotEmpty ? '${entries.length}' : 'EMPTY',
            summarySubtitle: entries.isNotEmpty
                ? 'entries today'
                : 'no entries',
            details: entries.isNotEmpty
                ? Text(
                    '${entries.first.mood ?? ''} ${entries.first.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : const Text('No data entry for the current cycle.'),
          ),
          loading: () => const _ModuleButtonSkeleton(
            title: 'CALENDAR',
            icon: Icons.calendar_month_outlined,
          ),
          error: (_, __) => _ModuleButton(
            title: 'CALENDAR',
            icon: Icons.error_outline,
            navigationPath: '/calendar',
            summaryValue: 'ERR',
            summarySubtitle: 'issue',
            details: const Text('Could not load calendar. Tap to open module.'),
          ),
        ),
        const SizedBox(height: 16),
        noteState.when(
          data: (notes) {
            return _ModuleButton(
              title: 'NOTES',
              icon: Icons.sticky_note_2_outlined,
              navigationPath: '/notes',
              summaryValue: '${notes.length}',
              summarySubtitle: 'stored logs',
              details: notes.isEmpty
                  ? const Text('Brain archive is currently empty.')
                  : Text(
                      'Latest: ${notes.first.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            );
          },
          loading: () => const _ModuleButtonSkeleton(
            title: 'NOTES',
            icon: Icons.sticky_note_2_outlined,
          ),
          error: (_, __) => _ModuleButton(
            title: 'NOTES',
            icon: Icons.error_outline,
            navigationPath: '/notes',
            summaryValue: 'ERR',
            summarySubtitle: 'issue',
            details: const Text('Could not load notes. Tap to open module.'),
          ),
        ),
      ],
    );
  }
}

class _ModuleButtonSkeleton extends StatelessWidget {
  final String title;
  final IconData icon;

  const _ModuleButtonSkeleton({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.55,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Container(
              width: 1,
              height: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ModuleSkeletonBlock(width: 96, height: 22, radius: 8),
                  SizedBox(height: 10),
                  ModuleSkeletonBlock(height: 10, radius: 5),
                  SizedBox(height: 8),
                  ModuleSkeletonBlock(width: 150, height: 10, radius: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FirstRunModulesState extends StatelessWidget {
  const _FirstRunModulesState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.waving_hand_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Welcome to ZENiT',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Start by adding a task or creating a habit.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/tasks'),
                    icon: const Icon(Icons.add_task),
                    label: const Text('ADD TASK'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/habits'),
                    icon: const Icon(Icons.track_changes_outlined),
                    label: const Text('CREATE HABIT'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final String? navigationPath;
  final String? summaryValue;
  final String? summarySubtitle;
  final Widget? details;

  const _ModuleButton({
    required this.title,
    required this.icon,
    this.onTap,
    this.navigationPath,
    this.summaryValue,
    this.summarySubtitle,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap:
            onTap ??
            (navigationPath != null ? () => context.go(navigationPath!) : null),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 32, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        title.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 1,
                    height: 48,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (summaryValue != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                summaryValue!,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (summarySubtitle != null)
                                Flexible(
                                  child: Text(
                                    summarySubtitle!.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 8,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (details != null) ...[
                          const SizedBox(height: 8),
                          DefaultTextStyle(
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                            child: details!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
