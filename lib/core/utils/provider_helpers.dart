import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/habit_tracker/providers/habit_provider.dart';
import '../../features/todo/providers/todo_provider.dart';
import '../../features/finance/providers/finance_provider.dart';
import '../../features/notes_shopping/providers/notes_provider.dart';
import '../../features/zen_mode/providers/zen_mode_provider.dart';

/// Invalidates all data providers to force a refresh
void invalidateAllProviders(WidgetRef ref) {
  ref.invalidate(habitListProvider);
  ref.invalidate(projectListProvider);
  ref.invalidate(taskListProvider);
  ref.invalidate(transactionListProvider);
  ref.invalidate(noteListProvider);
  ref.invalidate(shoppingListProvider);
  ref.invalidate(journalProvider);
  ref.invalidate(zenTimerProvider);
}
