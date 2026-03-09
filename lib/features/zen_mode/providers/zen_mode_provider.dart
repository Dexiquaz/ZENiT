import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';

enum ZenSessionPhase { focus, breakTime }

class ZenTimerState {
  final Duration focusDuration;
  final Duration breakDuration;
  final Duration remaining;
  final ZenSessionPhase phase;
  final bool isRunning;
  final int completedFocusSessions;

  const ZenTimerState({
    required this.focusDuration,
    required this.breakDuration,
    required this.remaining,
    required this.phase,
    required this.isRunning,
    required this.completedFocusSessions,
  });

  factory ZenTimerState.initial({
    Duration focusDuration = const Duration(minutes: 25),
    Duration breakDuration = const Duration(minutes: 5),
  }) {
    return ZenTimerState(
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      remaining: focusDuration,
      phase: ZenSessionPhase.focus,
      isRunning: false,
      completedFocusSessions: 0,
    );
  }

  ZenTimerState withDurations(Duration focusDuration, Duration breakDuration) {
    return ZenTimerState(
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      remaining: phase == ZenSessionPhase.focus ? focusDuration : breakDuration,
      phase: phase,
      isRunning: isRunning,
      completedFocusSessions: completedFocusSessions,
    );
  }

  bool get hasStarted {
    return completedFocusSessions > 0 ||
        phase != ZenSessionPhase.focus ||
        remaining != focusDuration;
  }

  bool get isIdle => !isRunning && !hasStarted;

  Duration get activePhaseDuration {
    return phase == ZenSessionPhase.focus ? focusDuration : breakDuration;
  }

  String get phaseLabel {
    return phase == ZenSessionPhase.focus ? 'FOCUS' : 'BREAK';
  }

  String get timeLabel {
    final totalSeconds = remaining.inSeconds.clamp(0, 359999);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progress {
    final total = activePhaseDuration.inSeconds;
    if (total == 0) return 0;

    final ratio = 1 - (remaining.inSeconds / total);
    return ratio.clamp(0, 1).toDouble();
  }

  ZenTimerState copyWith({
    Duration? focusDuration,
    Duration? breakDuration,
    Duration? remaining,
    ZenSessionPhase? phase,
    bool? isRunning,
    int? completedFocusSessions,
  }) {
    return ZenTimerState(
      focusDuration: focusDuration ?? this.focusDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      remaining: remaining ?? this.remaining,
      phase: phase ?? this.phase,
      isRunning: isRunning ?? this.isRunning,
      completedFocusSessions:
          completedFocusSessions ?? this.completedFocusSessions,
    );
  }
}

final zenTimerProvider = NotifierProvider<ZenTimerNotifier, ZenTimerState>(
  ZenTimerNotifier.new,
);

class ZenTimerNotifier extends Notifier<ZenTimerState> {
  Timer? _ticker;

  @override
  ZenTimerState build() {
    ref.onDispose(_stopTicker);

    ref.listen<AsyncValue<UserSettings>>(settingsProvider, (_, next) {
      next.whenData(_syncDurationsFromSettings);
    });

    final settings = ref.read(settingsProvider);
    return settings.when(
      data: (userSettings) => ZenTimerState.initial(
        focusDuration: Duration(minutes: userSettings.focusDurationMinutes),
        breakDuration: Duration(minutes: userSettings.breakDurationMinutes),
      ),
      loading: () => ZenTimerState.initial(),
      error: (_, __) => ZenTimerState.initial(),
    );
  }

  void startFocus() {
    _stopTicker();
    state = state.copyWith(
      phase: ZenSessionPhase.focus,
      remaining: state.focusDuration,
      isRunning: true,
    );
    _startTicker();
  }

  void pause() {
    if (!state.isRunning) return;

    _stopTicker();
    state = state.copyWith(isRunning: false);
  }

  void resume() {
    if (state.isRunning || state.remaining <= Duration.zero) return;

    state = state.copyWith(isRunning: true);
    _startTicker();
  }

  void reset() {
    _stopTicker();
    state = ZenTimerState.initial(
      focusDuration: state.focusDuration,
      breakDuration: state.breakDuration,
    );
  }

  void skipPhase() {
    _advancePhase(startRunning: true);
  }

  void updateFocusDuration(int minutes) {
    final clamped = minutes.clamp(1, 60).toInt();
    state = state.copyWith(
      focusDuration: Duration(minutes: clamped),
      remaining: state.phase == ZenSessionPhase.focus && !state.isRunning
          ? Duration(minutes: clamped)
          : state.remaining,
    );
    unawaited(ref.read(settingsProvider.notifier).setFocusDuration(clamped));
  }

  void updateBreakDuration(int minutes) {
    final clamped = minutes.clamp(1, 30).toInt();
    state = state.copyWith(
      breakDuration: Duration(minutes: clamped),
      remaining: state.phase == ZenSessionPhase.breakTime && !state.isRunning
          ? Duration(minutes: clamped)
          : state.remaining,
    );
    unawaited(ref.read(settingsProvider.notifier).setBreakDuration(clamped));
  }

  void _syncDurationsFromSettings(UserSettings settings) {
    final focusMinutes = settings.focusDurationMinutes.clamp(1, 60).toInt();
    final breakMinutes = settings.breakDurationMinutes.clamp(1, 30).toInt();

    final focusDuration = Duration(minutes: focusMinutes);
    final breakDuration = Duration(minutes: breakMinutes);

    if (focusDuration == state.focusDuration &&
        breakDuration == state.breakDuration) {
      return;
    }

    final shouldResetRemaining =
        !state.isRunning &&
        ((state.phase == ZenSessionPhase.focus &&
                state.remaining == state.focusDuration) ||
            (state.phase == ZenSessionPhase.breakTime &&
                state.remaining == state.breakDuration));

    state = state.copyWith(
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      remaining: shouldResetRemaining
          ? (state.phase == ZenSessionPhase.focus
                ? focusDuration
                : breakDuration)
          : state.remaining,
    );
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final nextRemaining = state.remaining - const Duration(seconds: 1);

      if (nextRemaining > Duration.zero) {
        state = state.copyWith(remaining: nextRemaining);
      } else {
        _advancePhase(startRunning: true);
      }
    });
  }

  void _advancePhase({required bool startRunning}) {
    _stopTicker();

    if (state.phase == ZenSessionPhase.focus) {
      state = state.copyWith(
        phase: ZenSessionPhase.breakTime,
        remaining: state.breakDuration,
        isRunning: startRunning,
        completedFocusSessions: state.completedFocusSessions + 1,
      );
    } else {
      state = state.copyWith(
        phase: ZenSessionPhase.focus,
        remaining: state.focusDuration,
        isRunning: startRunning,
      );
    }

    if (startRunning) {
      _startTicker();
    }
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
