import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/zen_mode_provider.dart';

class ZenModeView extends ConsumerWidget {
  const ZenModeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(zenTimerProvider);
    final notifier = ref.read(zenTimerProvider.notifier);
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
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: state.isRunning
                      ? notifier.pause
                      : (state.isIdle ? notifier.startFocus : notifier.resume),
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
                  onPressed: state.hasStarted ? notifier.reset : null,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('RESET'),
                ),
                OutlinedButton.icon(
                  onPressed: state.isRunning || state.hasStarted
                      ? notifier.skipPhase
                      : null,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('SKIP'),
                ),
              ],
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
          ],
        ),
      ),
    );
  }
}
