import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../providers/zen_mode_provider.dart';

Future<void> openZenAmbientView(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<void>(
      builder: (_) => const ZenAmbientView(),
      settings: const RouteSettings(name: 'zen_ambient_focus'),
    ),
  );
}

class ZenAmbientView extends ConsumerStatefulWidget {
  const ZenAmbientView({super.key});

  @override
  ConsumerState<ZenAmbientView> createState() => _ZenAmbientViewState();
}

class _ZenAmbientViewState extends ConsumerState<ZenAmbientView> {
  static const _driftOffsets = <Offset>[
    Offset(0, 0),
    Offset(8, -5),
    Offset(-6, 6),
    Offset(6, 7),
    Offset(-8, -3),
    Offset(4, -6),
  ];

  Timer? _hideControlsTimer;
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    _enterAmbientPresentation();
    _showControlsTemporarily();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    unawaited(_exitAmbientPresentation());
    super.dispose();
  }

  Future<void> _enterAmbientPresentation() async {
    await WakelockPlus.enable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _exitAmbientPresentation() async {
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  void _showControlsTemporarily() {
    if (!mounted) return;

    setState(() => _controlsVisible = true);
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideControlsTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showControlsTemporarily();
    }
  }

  Offset _currentDriftOffset(ZenTimerState state) {
    final startedAt = state.sessionStartedAt;
    if (startedAt == null) {
      return _driftOffsets.first;
    }

    final minuteIndex = DateTime.now().difference(startedAt).inMinutes;
    return _driftOffsets[minuteIndex % _driftOffsets.length];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(zenTimerProvider);
    final notifier = ref.read(zenTimerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final aodBackground = colorScheme.scrim.withValues(alpha: 1);
    final mutedPrimary = colorScheme.primary.withValues(alpha: 0.78);
    final strongText = colorScheme.onSurface.withValues(alpha: 0.9);
    final softText = colorScheme.onSurface.withValues(alpha: 0.62);
    final timeParts = state.timeLabel.split(':');
    final minuteLabel = timeParts.isNotEmpty ? timeParts.first : '00';
    final secondLabel = timeParts.length > 1 ? timeParts.last : '00';

    if (state.activeSessionId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    final drift = _currentDriftOffset(state);

    return Scaffold(
      backgroundColor: aodBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggleControls,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  transform: Matrix4.translationValues(drift.dx, drift.dy, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.phaseLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: mutedPrimary,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ClockPanel(value: minuteLabel),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              ':',
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    color: strongText.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                          _ClockPanel(value: secondLabel),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        state.isRunning
                            ? 'Focus session active'
                            : '${state.phaseLabel} paused',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: softText),
                      ),
                      if (state.hasLinkedTask) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 280,
                          child: Text(
                            state.linkedTaskTitle ?? 'Linked task',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: strongText,
                                ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 240,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            value: state.progress,
                            backgroundColor: colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              mutedPrimary.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_controlsVisible,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (state.isRunning)
                            FilledButton.icon(
                              onPressed: () {
                                notifier.pause();
                                _showControlsTemporarily();
                              },
                              icon: const Icon(Icons.pause),
                              label: const Text('PAUSE'),
                            )
                          else
                            FilledButton.icon(
                              onPressed: state.hasStarted
                                  ? () {
                                      notifier.resume();
                                      _showControlsTemporarily();
                                    }
                                  : null,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('RESUME'),
                            ),
                          OutlinedButton.icon(
                            onPressed: state.hasStarted
                                ? () {
                                    notifier.skipPhase();
                                    _showControlsTemporarily();
                                  }
                                : null,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('SKIP'),
                          ),
                          OutlinedButton.icon(
                            onPressed: state.hasStarted
                                ? () async {
                                    final navigator = Navigator.of(context);
                                    await notifier.reset();
                                    if (!mounted) return;
                                    if (navigator.canPop()) {
                                      navigator.pop();
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('END'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(
                              Icons.dashboard_customize_outlined,
                            ),
                            label: const Text('DETAILS'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClockPanel extends StatelessWidget {
  final String value;

  const _ClockPanel({required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 150,
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: colorScheme.onSurface.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
