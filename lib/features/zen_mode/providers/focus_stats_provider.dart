import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/database_helper.dart';
import 'zen_mode_provider.dart';

class TaskFocusStats {
  final int todayMinutes;
  final int weekCycles;

  const TaskFocusStats({required this.todayMinutes, required this.weekCycles});
}

final taskFocusStatsProvider = FutureProvider.family<TaskFocusStats, int>((
  ref,
  taskId,
) async {
  // Refresh stats when session-level milestones change.
  ref.watch(
    zenTimerProvider.select(
      (state) => (
        state.activeSessionId,
        state.completedFocusSessions,
        state.isRunning,
        state.phase,
      ),
    ),
  );

  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfTomorrow = startOfToday.add(const Duration(days: 1));
  final startOfWeek = startOfToday.subtract(
    Duration(days: startOfToday.weekday - DateTime.monday),
  );
  final endOfWeek = startOfWeek.add(const Duration(days: 7));

  final db = DatabaseHelper();
  final todayStats = await db.getTaskFocusStatsInRange(
    taskId,
    startInclusive: startOfToday,
    endExclusive: startOfTomorrow,
  );
  final weekStats = await db.getTaskFocusStatsInRange(
    taskId,
    startInclusive: startOfWeek,
    endExclusive: endOfWeek,
  );

  final todayMinutes = (todayStats['totalSeconds'] ?? 0) ~/ 60;
  final weekCycles = weekStats['totalCycles'] ?? 0;

  return TaskFocusStats(todayMinutes: todayMinutes, weekCycles: weekCycles);
});
