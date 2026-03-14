enum FocusSessionStatus { running, paused, completed, cancelled }

enum FocusSessionPhase { focus, breakTime }

class FocusSession {
  static const _unset = Object();

  final int? id;
  final int? taskId;
  final String? taskTitleSnapshot;
  final FocusSessionStatus status;
  final FocusSessionPhase phase;
  final Duration focusDuration;
  final Duration breakDuration;
  final Duration remaining;
  final int completedFocusSessions;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const FocusSession({
    this.id,
    this.taskId,
    this.taskTitleSnapshot,
    required this.status,
    required this.phase,
    required this.focusDuration,
    required this.breakDuration,
    required this.remaining,
    required this.completedFocusSessions,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
  });

  bool get isActive =>
      status == FocusSessionStatus.running ||
      status == FocusSessionStatus.paused;

  Map<String, dynamic> toMap() => {
    'id': id,
    'task_id': taskId,
    'task_title_snapshot': taskTitleSnapshot,
    'status': status.index,
    'phase': phase.index,
    'focus_duration_seconds': focusDuration.inSeconds,
    'break_duration_seconds': breakDuration.inSeconds,
    'remaining_seconds': remaining.inSeconds,
    'completed_focus_sessions': completedFocusSessions,
    'started_at': startedAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };

  factory FocusSession.fromMap(Map<String, dynamic> map) => FocusSession(
    id: map['id'] as int?,
    taskId: map['task_id'] as int?,
    taskTitleSnapshot: map['task_title_snapshot'] as String?,
    status: FocusSessionStatus.values[(map['status'] as int?) ?? 0],
    phase: FocusSessionPhase.values[(map['phase'] as int?) ?? 0],
    focusDuration: Duration(
      seconds: (map['focus_duration_seconds'] as int?) ?? 0,
    ),
    breakDuration: Duration(
      seconds: (map['break_duration_seconds'] as int?) ?? 0,
    ),
    remaining: Duration(seconds: (map['remaining_seconds'] as int?) ?? 0),
    completedFocusSessions: (map['completed_focus_sessions'] as int?) ?? 0,
    startedAt: DateTime.parse(map['started_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    completedAt: map['completed_at'] != null
        ? DateTime.parse(map['completed_at'] as String)
        : null,
  );

  FocusSession copyWith({
    int? id,
    Object? taskId = _unset,
    Object? taskTitleSnapshot = _unset,
    FocusSessionStatus? status,
    FocusSessionPhase? phase,
    Duration? focusDuration,
    Duration? breakDuration,
    Duration? remaining,
    int? completedFocusSessions,
    DateTime? startedAt,
    DateTime? updatedAt,
    Object? completedAt = _unset,
  }) => FocusSession(
    id: id ?? this.id,
    taskId: identical(taskId, _unset) ? this.taskId : taskId as int?,
    taskTitleSnapshot: identical(taskTitleSnapshot, _unset)
        ? this.taskTitleSnapshot
        : taskTitleSnapshot as String?,
    status: status ?? this.status,
    phase: phase ?? this.phase,
    focusDuration: focusDuration ?? this.focusDuration,
    breakDuration: breakDuration ?? this.breakDuration,
    remaining: remaining ?? this.remaining,
    completedFocusSessions:
        completedFocusSessions ?? this.completedFocusSessions,
    startedAt: startedAt ?? this.startedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    completedAt: identical(completedAt, _unset)
        ? this.completedAt
        : completedAt as DateTime?,
  );
}
