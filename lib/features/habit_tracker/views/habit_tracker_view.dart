import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/module_state_view.dart';
import '../providers/habit_provider.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/edit_habit_sheet.dart';
import '../widgets/power_grid.dart';
import '../models/habit.dart';

class HabitTrackerView extends ConsumerWidget {
  const HabitTrackerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitState = ref.watch(habitListProvider);

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: MediaQuery.of(context).size.width - 48,
        height: 50,
        child: FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => const AddHabitDialog(),
            );
          },
          label: const Text('NEW HABIT'),
          icon: const Icon(Icons.add),
        ),
      ),
      body: habitState.when(
        data: (habits) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 104),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryHeader(context, habits),
              const SizedBox(height: 32),
              Text(
                'YOUR HABITS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              if (habits.isEmpty)
                ModuleEmptyState(
                  icon: Icons.track_changes_outlined,
                  title: 'No habits tracked yet',
                  subtitle: 'Create your first habit and start a streak.',
                  actionLabel: 'NEW HABIT',
                  onAction: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) => const AddHabitDialog(),
                    );
                  },
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) =>
                      _HabitCard(habit: habits[index]),
                ),
            ],
          ),
        ),
        loading: () => const ModuleLoadingState(
          title: 'Loading habits',
          subtitle: 'Building your habit board.',
        ),
        error: (_, __) => ModuleErrorState(
          title: 'Could not load habits',
          subtitle: 'Please try refreshing your habits.',
          onRetry: () => ref.invalidate(habitListProvider),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, List<Habit> habits) {
    final today = DateTime.now();
    int completedToday = habits.where((h) {
      return h.completionDates.any(
        (d) =>
            d.year == today.year &&
            d.month == today.month &&
            d.day == today.day,
      );
    }).length;

    double efficiency = habits.isEmpty
        ? 0
        : (completedToday / habits.length) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'COMPLETED TODAY',
              value: '$completedToday/${habits.length}',
            ),
            _StatItem(label: 'EFFICIENCY', value: '${efficiency.toInt()}%'),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends ConsumerStatefulWidget {
  final Habit habit;
  const _HabitCard({required this.habit});

  @override
  ConsumerState<_HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends ConsumerState<_HabitCard> {
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isCompletedToday = widget.habit.completionDates.any(
      (d) =>
          d.year == today.year && d.month == today.month && d.day == today.day,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.habit.category.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isCompletedToday,
                  onChanged: (v) {
                    ref
                        .read(habitListProvider.notifier)
                        .toggleHabitCompletion(widget.habit, DateTime.now());
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.habit.description.isNotEmpty) ...[
              Text(
                widget.habit.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
            ],
            PowerGrid(completionDates: widget.habit.completionDates),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.habit.recurrence.name.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) {
                            return EditHabitSheet(habit: widget.habit);
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => ref
                          .read(habitListProvider.notifier)
                          .deleteHabit(widget.habit.id!),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
