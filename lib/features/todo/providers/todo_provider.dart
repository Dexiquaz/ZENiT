import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/database_helper.dart';

final selectedProjectProvider = NotifierProvider<SelectedProjectNotifier, int?>(
  SelectedProjectNotifier.new,
);

class SelectedProjectNotifier extends Notifier<int?> {
  @override
  int? build() => null;
  void select(int? id) => state = id;
}

final projectListProvider =
    AsyncNotifierProvider<ProjectNotifier, List<Project>>(ProjectNotifier.new);

class ProjectNotifier extends AsyncNotifier<List<Project>> {
  final _db = DatabaseHelper();
  final _notifications = NotificationService.instance;
  @override
  Future<List<Project>> build() async => _db.getProjects();

  Future<void> addProject(String name) async {
    await _db.insertProject(name);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteProject(int id) async {
    final taskIds = await _db.getTaskIdsForProject(id);
    for (final taskId in taskIds) {
      await _notifications.cancelTaskReminder(taskId);
    }

    await _db.unlinkFocusSessionsForTasks(taskIds);

    await _db.deleteProject(id);
    // If the deleted project was selected, reset selection to null (All)
    if (ref.read(selectedProjectProvider) == id) {
      ref.read(selectedProjectProvider.notifier).select(null);
    }
    ref.invalidateSelf();
    ref.read(taskListProvider.notifier).build(); // Refresh tasks
    await future;
  }
}

final taskListProvider = AsyncNotifierProvider<TaskNotifier, List<Task>>(
  TaskNotifier.new,
);

final allTaskListProvider = FutureProvider<List<Task>>((ref) async {
  // Re-evaluate whenever the filtered task provider changes.
  ref.watch(taskListProvider);
  return DatabaseHelper().getTasks();
});

class TaskNotifier extends AsyncNotifier<List<Task>> {
  final _db = DatabaseHelper();
  final _notifications = NotificationService.instance;

  @override
  Future<List<Task>> build() async {
    final projectId = ref.watch(selectedProjectProvider);
    return _db.getTasks(projectId: projectId);
  }

  Future<void> addTask(Task task) async {
    final id = await _db.insertTask(task);
    await _syncTaskReminder(task.copyWith(id: id));
    ref.invalidateSelf();
    ref.invalidate(projectListProvider);
    await future;
  }

  Future<void> toggleTask(Task task) async {
    final nextCompleted = !task.completed;
    await _db.updateTask(
      task.copyWith(
        completed: nextCompleted,
        pinned: nextCompleted ? false : task.pinned,
      ),
    );
    if (nextCompleted) {
      if (task.id != null) {
        await _notifications.cancelTaskReminder(task.id!);
      }
    } else {
      await _syncTaskReminder(task.copyWith(completed: false));
    }
    ref.invalidateSelf();
    await future;
  }

  Future<bool> setTaskPinned(Task task, bool pinned) async {
    if (pinned && !task.completed) {
      final tasks = await future;
      final pinnedCount = tasks
          .where((t) => t.pinned && !t.completed && t.id != task.id)
          .length;
      if (pinnedCount >= 3) {
        return false;
      }
    }

    await _db.updateTask(task.copyWith(pinned: pinned));
    ref.invalidateSelf();
    await future;
    return true;
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    await _syncTaskReminder(task);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteTask(int id) async {
    await _notifications.cancelTaskReminder(id);
    await _db.unlinkFocusSessionsForTask(id);
    await _db.deleteTask(id);
    ref.invalidateSelf();
    ref.invalidate(projectListProvider);
    await future;
  }

  Future<void> _syncTaskReminder(Task task) async {
    if (task.id == null) return;

    await _notifications.cancelTaskReminder(task.id!);

    if (task.completed || task.reminderAt == null) {
      return;
    }

    await _notifications.scheduleTaskReminder(
      taskId: task.id!,
      taskTitle: task.title,
      reminderAt: task.reminderAt!,
    );
  }
}
