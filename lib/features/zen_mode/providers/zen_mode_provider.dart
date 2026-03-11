import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/utils/database_helper.dart';
import '../models/focus_session.dart';

enum FocusStartResult { started, missingLinkedTask, linkedTaskUnavailable }

class ZenTimerState {
  static const _unset = Object();

  final Duration focusDuration;
  final Duration breakDuration;
  final Duration remaining;
  final FocusSessionPhase phase;
  final bool isRunning;
  final int completedFocusSessions;
  final int? activeSessionId;
  final int? linkedTaskId;
  final String? linkedTaskTitle;
  final DateTime? sessionStartedAt;

  const ZenTimerState({
    required this.focusDuration,
    required this.breakDuration,
    required this.remaining,
    required this.phase,
    required this.isRunning,
    required this.completedFocusSessions,
    this.activeSessionId,
    this.linkedTaskId,
    this.linkedTaskTitle,
    this.sessionStartedAt,
  });

  factory ZenTimerState.initial({
    Duration focusDuration = const Duration(minutes: 25),
    Duration breakDuration = const Duration(minutes: 5),
  }) {
    return ZenTimerState(
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      remaining: focusDuration,
      phase: FocusSessionPhase.focus,
      isRunning: false,
      completedFocusSessions: 0,
    );
  }

  ZenTimerState withDurations(Duration focusDuration, Duration breakDuration) {
    return ZenTimerState(
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      remaining: phase == FocusSessionPhase.focus
          ? focusDuration
          : breakDuration,
      phase: phase,
      isRunning: isRunning,
      completedFocusSessions: completedFocusSessions,
      activeSessionId: activeSessionId,
      linkedTaskId: linkedTaskId,
      linkedTaskTitle: linkedTaskTitle,
      sessionStartedAt: sessionStartedAt,
    );
  }

  bool get hasStarted {
    return completedFocusSessions > 0 ||
        phase != FocusSessionPhase.focus ||
        remaining != focusDuration;
  }

  bool get isIdle => !isRunning && !hasStarted;

  Duration get activePhaseDuration {
    return phase == FocusSessionPhase.focus ? focusDuration : breakDuration;
  }

  String get phaseLabel {
    return phase == FocusSessionPhase.focus ? 'FOCUS' : 'BREAK';
  }

  bool get hasLinkedTask =>
      linkedTaskId != null ||
      (linkedTaskTitle != null && linkedTaskTitle!.isNotEmpty);

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
    FocusSessionPhase? phase,
    bool? isRunning,
    int? completedFocusSessions,
    Object? activeSessionId = _unset,
    Object? linkedTaskId = _unset,
    Object? linkedTaskTitle = _unset,
    Object? sessionStartedAt = _unset,
  }) {
    return ZenTimerState(
      focusDuration: focusDuration ?? this.focusDuration,
      breakDuration: breakDuration ?? this.breakDuration,
      remaining: remaining ?? this.remaining,
      phase: phase ?? this.phase,
      isRunning: isRunning ?? this.isRunning,
      completedFocusSessions:
          completedFocusSessions ?? this.completedFocusSessions,
      activeSessionId: identical(activeSessionId, _unset)
          ? this.activeSessionId
          : activeSessionId as int?,
      linkedTaskId: identical(linkedTaskId, _unset)
          ? this.linkedTaskId
          : linkedTaskId as int?,
      linkedTaskTitle: identical(linkedTaskTitle, _unset)
          ? this.linkedTaskTitle
          : linkedTaskTitle as String?,
      sessionStartedAt: identical(sessionStartedAt, _unset)
          ? this.sessionStartedAt
          : sessionStartedAt as DateTime?,
    );
  }
}

final zenTimerProvider = NotifierProvider<ZenTimerNotifier, ZenTimerState>(
  ZenTimerNotifier.new,
);

class ZenTimerNotifier extends Notifier<ZenTimerState> {
  final _db = DatabaseHelper();
  final _notifications = NotificationService.instance;
  Timer? _ticker;

  @override
  ZenTimerState build() {
    ref.onDispose(_stopTicker);

    ref.listen<AsyncValue<UserSettings>>(settingsProvider, (_, next) {
      next.whenData(_syncDurationsFromSettings);
    });

    final settings = ref.read(settingsProvider);
    final initialState = settings.when(
      data: (userSettings) => ZenTimerState.initial(
        focusDuration: Duration(minutes: userSettings.focusDurationMinutes),
        breakDuration: Duration(minutes: userSettings.breakDurationMinutes),
      ),
      loading: () => ZenTimerState.initial(),
      error: (_, __) => ZenTimerState.initial(),
    );

    unawaited(_hydratePersistedSession());
    return initialState;
  }

  Future<FocusStartResult> startLinkedFocus() async {
    return _startFocusSession(requireLinkedTask: true);
  }

  Future<FocusStartResult> startQuickFocus() async {
    return _startFocusSession(requireLinkedTask: false);
  }

  Future<FocusStartResult> _startFocusSession({
    required bool requireLinkedTask,
  }) async {
    int? taskId;
    String? taskTitle;

    if (requireLinkedTask) {
      taskId = state.linkedTaskId;
      taskTitle = state.linkedTaskTitle;

      if (taskId == null) {
        if (state.hasLinkedTask) {
          state = state.copyWith(linkedTaskId: null, linkedTaskTitle: null);
        }
        return FocusStartResult.missingLinkedTask;
      }

      final task = await _db.getTaskById(taskId);
      if (task == null || task.completed) {
        state = state.copyWith(linkedTaskId: null, linkedTaskTitle: null);
        await _persistActiveSession();
        return FocusStartResult.linkedTaskUnavailable;
      }

      taskTitle = task.title;
    }

    _stopTicker();

    await _finalizeActiveSession();

    final now = DateTime.now();
    final session = FocusSession(
      taskId: taskId,
      taskTitleSnapshot: taskTitle,
      status: FocusSessionStatus.running,
      phase: FocusSessionPhase.focus,
      focusDuration: state.focusDuration,
      breakDuration: state.breakDuration,
      remaining: state.focusDuration,
      completedFocusSessions: 0,
      startedAt: now,
      updatedAt: now,
    );
    final sessionId = await _db.insertFocusSession(session);

    state = state.copyWith(
      phase: FocusSessionPhase.focus,
      remaining: state.focusDuration,
      isRunning: true,
      completedFocusSessions: 0,
      activeSessionId: sessionId,
      linkedTaskId: taskId,
      linkedTaskTitle: taskTitle,
      sessionStartedAt: now,
    );
    _startTicker();
    return FocusStartResult.started;
  }

  Future<void> pause() async {
    if (!state.isRunning) return;

    _stopTicker();
    state = state.copyWith(isRunning: false);
    await _persistActiveSession();
  }

  Future<void> setLinkedTask({int? taskId, String? taskTitle}) async {
    if (state.isRunning) return;

    if (state.linkedTaskId == taskId && state.linkedTaskTitle == taskTitle) {
      return;
    }

    state = state.copyWith(linkedTaskId: taskId, linkedTaskTitle: taskTitle);
    await _persistActiveSession();
  }

  Future<void> clearLinkedTask() async {
    await setLinkedTask(taskId: null, taskTitle: null);
  }

  Future<void> resume() async {
    if (state.isRunning || state.remaining <= Duration.zero) return;
    state = state.copyWith(isRunning: true);
    await _persistActiveSession();
    _startTicker();
  }

  Future<void> reset() async {
    _stopTicker();
    final linkedTaskId = state.linkedTaskId;
    final linkedTaskTitle = state.linkedTaskTitle;
    await _finalizeActiveSession();
    state = ZenTimerState.initial(
      focusDuration: state.focusDuration,
      breakDuration: state.breakDuration,
    ).copyWith(linkedTaskId: linkedTaskId, linkedTaskTitle: linkedTaskTitle);
  }

  Future<void> skipPhase() async {
    await _advancePhase(startRunning: true);
  }

  Future<void> updateFocusDuration(int minutes) async {
    final clamped = minutes.clamp(1, 60).toInt();
    state = state.copyWith(
      focusDuration: Duration(minutes: clamped),
      remaining: state.phase == FocusSessionPhase.focus && !state.isRunning
          ? Duration(minutes: clamped)
          : state.remaining,
    );
    await _persistActiveSession();
    unawaited(ref.read(settingsProvider.notifier).setFocusDuration(clamped));
  }

  Future<void> updateBreakDuration(int minutes) async {
    final clamped = minutes.clamp(1, 30).toInt();
    state = state.copyWith(
      breakDuration: Duration(minutes: clamped),
      remaining: state.phase == FocusSessionPhase.breakTime && !state.isRunning
          ? Duration(minutes: clamped)
          : state.remaining,
    );
    await _persistActiveSession();
    unawaited(ref.read(settingsProvider.notifier).setBreakDuration(clamped));
  }

  void _syncDurationsFromSettings(UserSettings settings) {
    if (state.activeSessionId != null) {
      return;
    }

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
        ((state.phase == FocusSessionPhase.focus &&
                state.remaining == state.focusDuration) ||
            (state.phase == FocusSessionPhase.breakTime &&
                state.remaining == state.breakDuration));

    state = state.copyWith(
      focusDuration: focusDuration,
      breakDuration: breakDuration,
      remaining: shouldResetRemaining
          ? (state.phase == FocusSessionPhase.focus
                ? focusDuration
                : breakDuration)
          : state.remaining,
    );
  }

  Future<void> _hydratePersistedSession() async {
    final session = await _db.getActiveFocusSession();
    if (session == null) {
      return;
    }

    final reconciledSession = _reconcileSession(session);
    if (reconciledSession.id != null) {
      await _db.updateFocusSession(reconciledSession);
    }

    state = _stateFromSession(reconciledSession);

    if (reconciledSession.status == FocusSessionStatus.running) {
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final nextRemaining = state.remaining - const Duration(seconds: 1);

      if (nextRemaining > Duration.zero) {
        state = state.copyWith(remaining: nextRemaining);
        if (nextRemaining.inSeconds % 5 == 0) {
          unawaited(_persistActiveSession());
        }
      } else {
        unawaited(_advancePhase(startRunning: true));
      }
    });
  }

  Future<void> _advancePhase({required bool startRunning}) async {
    _stopTicker();

    final previousPhase = state.phase;

    if (state.phase == FocusSessionPhase.focus) {
      state = state.copyWith(
        phase: FocusSessionPhase.breakTime,
        remaining: state.breakDuration,
        isRunning: startRunning,
        completedFocusSessions: state.completedFocusSessions + 1,
      );
    } else {
      state = state.copyWith(
        phase: FocusSessionPhase.focus,
        remaining: state.focusDuration,
        isRunning: startRunning,
      );
    }

    await _persistActiveSession();
    await _notifyPhaseTransition(
      from: previousPhase,
      to: state.phase,
      nextDuration: state.remaining,
      taskTitle: state.linkedTaskTitle,
    );

    if (startRunning) {
      _startTicker();
    }
  }

  Future<void> _notifyPhaseTransition({
    required FocusSessionPhase from,
    required FocusSessionPhase to,
    required Duration nextDuration,
    String? taskTitle,
  }) async {
    if (from == to) return;

    await _notifications.showFocusPhaseTransitionAlert(
      toBreak: to == FocusSessionPhase.breakTime,
      nextDuration: nextDuration,
      taskTitle: taskTitle,
    );
  }

  Future<void> _persistActiveSession() async {
    if (state.activeSessionId == null || state.sessionStartedAt == null) {
      return;
    }

    final session = FocusSession(
      id: state.activeSessionId,
      taskId: state.linkedTaskId,
      taskTitleSnapshot: state.linkedTaskTitle,
      status: state.isRunning
          ? FocusSessionStatus.running
          : FocusSessionStatus.paused,
      phase: state.phase,
      focusDuration: state.focusDuration,
      breakDuration: state.breakDuration,
      remaining: state.remaining,
      completedFocusSessions: state.completedFocusSessions,
      startedAt: state.sessionStartedAt!,
      updatedAt: DateTime.now(),
    );
    await _db.updateFocusSession(session);
  }

  Future<void> _finalizeActiveSession() async {
    if (state.activeSessionId == null || state.sessionStartedAt == null) {
      return;
    }

    final now = DateTime.now();
    final status = state.completedFocusSessions > 0
        ? FocusSessionStatus.completed
        : FocusSessionStatus.cancelled;

    await _db.updateFocusSession(
      FocusSession(
        id: state.activeSessionId,
        taskId: state.linkedTaskId,
        taskTitleSnapshot: state.linkedTaskTitle,
        status: status,
        phase: state.phase,
        focusDuration: state.focusDuration,
        breakDuration: state.breakDuration,
        remaining: state.remaining,
        completedFocusSessions: state.completedFocusSessions,
        startedAt: state.sessionStartedAt!,
        updatedAt: now,
        completedAt: now,
      ),
    );
  }

  FocusSession _reconcileSession(FocusSession session) {
    if (session.status != FocusSessionStatus.running) {
      return session;
    }

    var nextPhase = session.phase;
    var remainingSeconds = session.remaining.inSeconds;
    var completedFocusSessions = session.completedFocusSessions;
    final elapsedSeconds = DateTime.now()
        .difference(session.updatedAt)
        .inSeconds;

    remainingSeconds -= elapsedSeconds;

    while (remainingSeconds <= 0) {
      if (nextPhase == FocusSessionPhase.focus) {
        completedFocusSessions += 1;
        nextPhase = FocusSessionPhase.breakTime;
        remainingSeconds += session.breakDuration.inSeconds;
      } else {
        nextPhase = FocusSessionPhase.focus;
        remainingSeconds += session.focusDuration.inSeconds;
      }
    }

    return session.copyWith(
      phase: nextPhase,
      remaining: Duration(seconds: remainingSeconds),
      completedFocusSessions: completedFocusSessions,
      updatedAt: DateTime.now(),
    );
  }

  ZenTimerState _stateFromSession(FocusSession session) {
    return ZenTimerState(
      focusDuration: session.focusDuration,
      breakDuration: session.breakDuration,
      remaining: session.remaining,
      phase: session.phase,
      isRunning: session.status == FocusSessionStatus.running,
      completedFocusSessions: session.completedFocusSessions,
      activeSessionId: session.id,
      linkedTaskId: session.taskId,
      linkedTaskTitle: session.taskTitleSnapshot,
      sessionStartedAt: session.startedAt,
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
