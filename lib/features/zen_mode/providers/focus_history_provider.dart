import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/database_helper.dart';
import '../models/focus_session.dart';
import 'zen_mode_provider.dart';

final recentFocusSessionsProvider = FutureProvider<List<FocusSession>>((
  ref,
) async {
  // Refresh when active session milestones change.
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

  final sessions = await DatabaseHelper().getFocusSessions();
  return sessions.take(7).toList(growable: false);
});
