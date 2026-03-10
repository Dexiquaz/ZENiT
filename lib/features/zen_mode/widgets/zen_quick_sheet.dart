import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/zen_mode_provider.dart';

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
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: state.isRunning
                      ? () => notifier.pause()
                      : (state.isIdle
                            ? () => notifier.startFocus(
                                taskId: state.linkedTaskId,
                                taskTitle: state.linkedTaskTitle,
                              )
                            : () => notifier.resume()),
                  icon: Icon(
                    state.isRunning
                        ? Icons.pause
                        : (state.isIdle ? Icons.play_arrow : Icons.play_circle),
                  ),
                  label: Text(
                    state.isRunning
                        ? 'PAUSE'
                        : (state.isIdle ? 'START FOCUS' : 'RESUME'),
                  ),
                ),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
