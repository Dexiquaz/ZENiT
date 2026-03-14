import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/database_helper.dart';
import '../../features/habit_tracker/models/habit.dart';
import '../../features/todo/models/task_model.dart';
import '../../features/finance/models/transaction_model.dart';
import '../../features/notes_shopping/models/models.dart';
import '../../features/zen_mode/models/focus_session.dart';

class DataImportResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? settings;

  const DataImportResult({
    required this.success,
    required this.message,
    this.settings,
  });
}

/// Service for exporting and importing all user data.
class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  final _db = DatabaseHelper();

  /// Export all data to a JSON file.
  /// If [customDirectoryPath] is provided, saves to that directory.
  /// Otherwise, saves to the default Documents directory.
  /// Returns the file path on success, null on error.
  Future<String?> exportToJson({
    Map<String, dynamic>? settings,
    String? customDirectoryPath,
  }) async {
    try {
      // Gather all data
      final habits = await _db.getHabits();
      final tasks = await _db.getTasks();
      final projects = await _db.getProjects();
      final transactions = await _db.getTransactions();
      final notes = await _db.getNotes();
      final shoppingItems = await _db.getShoppingItems();
      final journalEntries = await _db.getAllJournalEntries();
      final focusSessions = await _db.getFocusSessions();

      // Create export object
      final exportData = {
        'version': '1.2',
        'exportedAt': DateTime.now().toIso8601String(),
        'settings': settings ?? <String, dynamic>{},
        'data': {
          'habits': habits.map((h) => h.toMap()).toList(),
          'tasks': tasks.map((t) => t.toMap()).toList(),
          'projects': projects
              .map((p) => {'id': p.id, 'name': p.name})
              .toList(),
          'transactions': transactions.map((t) => t.toMap()).toList(),
          'notes': notes.map((n) => n.toMap()).toList(),
          'shoppingItems': shoppingItems.map((s) => s.toMap()).toList(),
          'journalEntries': journalEntries.map((j) => j.toMap()).toList(),
          'focusSessions': focusSessions
              .map((session) => session.toMap())
              .toList(),
        },
      };

      // Determine target directory
      late Directory targetDirectory;
      if (customDirectoryPath != null && customDirectoryPath.isNotEmpty) {
        targetDirectory = Directory(customDirectoryPath);
        // Ensure directory exists
        if (!await targetDirectory.exists()) {
          await targetDirectory.create(recursive: true);
        }
      } else {
        targetDirectory = await getApplicationDocumentsDirectory();
      }

      // Write to file with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File('${targetDirectory.path}/zenit_export_$timestamp.json');

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(exportData),
      );

      return file.path;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  /// Export all data to CSV format (multiple files in a directory).
  /// Returns the directory path on success, null on error.
  Future<String?> exportToCsv() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final exportDir = Directory(
        '${directory.path}/zenit_csv_export_$timestamp',
      );

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Export habits
      final habits = await _db.getHabits();
      await _writeCsvFile(
        '${exportDir.path}/habits.csv',
        [
          'id',
          'title',
          'description',
          'recurrence',
          'category',
          'reminder_enabled',
          'reminder_hour',
          'reminder_minute',
          'reminder_weekday',
          'reminder_day_of_month',
          'created_at',
          'completion_dates',
        ],
        habits
            .map(
              (h) => [
                h.id?.toString() ?? '',
                _escapeCsv(h.title),
                _escapeCsv(h.description),
                h.recurrence.index.toString(),
                _escapeCsv(h.category),
                h.reminderEnabled ? '1' : '0',
                h.reminderHour?.toString() ?? '',
                h.reminderMinute?.toString() ?? '',
                h.reminderWeekday?.toString() ?? '',
                h.reminderDayOfMonth?.toString() ?? '',
                h.createdAt.toIso8601String(),
                _escapeCsv(h.completionDates.join(',')),
              ],
            )
            .toList(),
      );

      // Export tasks
      final tasks = await _db.getTasks();
      await _writeCsvFile(
        '${exportDir.path}/tasks.csv',
        [
          'id',
          'title',
          'project_id',
          'parent_id',
          'priority',
          'due_date',
          'reminder_at',
          'is_pinned',
          'completed',
          'created_at',
        ],
        tasks
            .map(
              (t) => [
                t.id?.toString() ?? '',
                _escapeCsv(t.title),
                t.projectId?.toString() ?? '',
                t.parentId?.toString() ?? '',
                t.priority.toString(),
                t.dueDate?.toIso8601String() ?? '',
                t.reminderAt?.toIso8601String() ?? '',
                t.pinned ? '1' : '0',
                t.completed ? '1' : '0',
                t.createdAt.toIso8601String(),
              ],
            )
            .toList(),
      );

      final focusSessions = await _db.getFocusSessions();
      await _writeCsvFile(
        '${exportDir.path}/focus_sessions.csv',
        [
          'id',
          'task_id',
          'task_title_snapshot',
          'status',
          'phase',
          'focus_duration_seconds',
          'break_duration_seconds',
          'remaining_seconds',
          'completed_focus_sessions',
          'started_at',
          'updated_at',
          'completed_at',
        ],
        focusSessions
            .map(
              (session) => [
                session.id?.toString() ?? '',
                session.taskId?.toString() ?? '',
                _escapeCsv(session.taskTitleSnapshot ?? ''),
                session.status.name,
                session.phase.name,
                session.focusDuration.inSeconds.toString(),
                session.breakDuration.inSeconds.toString(),
                session.remaining.inSeconds.toString(),
                session.completedFocusSessions.toString(),
                session.startedAt.toIso8601String(),
                session.updatedAt.toIso8601String(),
                session.completedAt?.toIso8601String() ?? '',
              ],
            )
            .toList(),
      );

      // Export projects
      final projects = await _db.getProjects();
      await _writeCsvFile(
        '${exportDir.path}/projects.csv',
        ['id', 'name'],
        projects.map((p) => [p.id.toString(), _escapeCsv(p.name)]).toList(),
      );

      // Export transactions
      final transactions = await _db.getTransactions();
      await _writeCsvFile(
        '${exportDir.path}/transactions.csv',
        ['id', 'description', 'amount', 'category', 'is_income', 'date'],
        transactions
            .map(
              (t) => [
                t.id?.toString() ?? '',
                _escapeCsv(t.description),
                t.amount.toString(),
                _escapeCsv(t.category),
                t.isIncome ? '1' : '0',
                t.date.toIso8601String(),
              ],
            )
            .toList(),
      );

      // Export notes
      final notes = await _db.getNotes();
      await _writeCsvFile(
        '${exportDir.path}/notes.csv',
        ['id', 'title', 'content', 'folder', 'tags', 'created_at'],
        notes
            .map(
              (n) => [
                n.id?.toString() ?? '',
                _escapeCsv(n.title),
                _escapeCsv(n.content),
                _escapeCsv(n.folder),
                _escapeCsv(n.tags),
                n.createdAt.toIso8601String(),
              ],
            )
            .toList(),
      );

      // Export shopping items
      final shoppingItems = await _db.getShoppingItems();
      await _writeCsvFile(
        '${exportDir.path}/shopping_items.csv',
        ['id', 'name', 'quantity', 'category', 'checked'],
        shoppingItems
            .map(
              (s) => [
                s.id?.toString() ?? '',
                _escapeCsv(s.name),
                s.quantity.toString(),
                _escapeCsv(s.category),
                s.checked ? '1' : '0',
              ],
            )
            .toList(),
      );

      // Export journal entries
      final now = DateTime.now();
      final journalEntries = <JournalEntry>[];
      for (int i = 0; i < 12; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final entries = await _db.getJournalEntriesForMonth(
          date.year,
          date.month,
        );
        journalEntries.addAll(entries);
      }
      await _writeCsvFile(
        '${exportDir.path}/journal_entries.csv',
        ['id', 'timestamp', 'title', 'content', 'mood'],
        journalEntries
            .map(
              (j) => [
                j.id?.toString() ?? '',
                j.timestamp.toIso8601String(),
                _escapeCsv(j.title),
                _escapeCsv(j.content),
                _escapeCsv(j.mood ?? ''),
              ],
            )
            .toList(),
      );

      return exportDir.path;
    } catch (e) {
      debugPrint('CSV export error: $e');
      return null;
    }
  }

  /// Import data from a JSON file.
  /// Returns true on success, false on error.
  Future<bool> importFromJson(String filePath) async {
    final result = await importFromJsonDetailed(filePath);
    return result.success;
  }

  Future<DataImportResult> importFromJsonDetailed(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const DataImportResult(
          success: false,
          message: 'Selected backup file was not found.',
        );
      }

      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        return const DataImportResult(
          success: false,
          message: 'Backup file format is invalid.',
        );
      }

      final data = decoded;

      // Validate version
      final version = data['version']?.toString();
      if (version != '1.0' && version != '1.1' && version != '1.2') {
        debugPrint('Unsupported export version: ${data['version']}');
        return DataImportResult(
          success: false,
          message: 'Unsupported backup version: ${data['version']}.',
        );
      }

      if (data['data'] is! Map<String, dynamic>) {
        return const DataImportResult(
          success: false,
          message: 'Backup file is missing required data payload.',
        );
      }

      final importData = data['data'] as Map<String, dynamic>;
      final backupSettings = data['settings'] is Map<String, dynamic>
          ? data['settings'] as Map<String, dynamic>
          : null;

      // Clear existing data
      await _db.deleteAllData();

      // Import projects first (they're referenced by tasks)
      final projectsData = importData['projects'] as List<dynamic>? ?? [];
      final projectIdMap = <int, int>{}; // old ID -> new ID

      final currentProjects = await _db.getProjects();
      final existingByName = <String, int>{
        for (final p in currentProjects)
          if (p.id != null) p.name.toLowerCase(): p.id!,
      };

      for (final p in projectsData) {
        if (p is! Map<String, dynamic>) continue;
        final oldId = (p['id'] as num?)?.toInt();
        final name = p['name']?.toString();
        if (oldId == null || name == null || name.isEmpty) continue;

        final existingId = existingByName[name.toLowerCase()];
        final newId = existingId ?? await _db.insertProject(name);
        existingByName[name.toLowerCase()] = newId;
        projectIdMap[oldId] = newId;
      }

      // Import habits
      final habitsData = importData['habits'] as List<dynamic>? ?? [];
      for (final h in habitsData) {
        if (h is! Map<String, dynamic>) continue;
        final habit = Habit.fromMap(h);
        await _db.insertHabit(habit.copyWith(id: null)); // Clear ID for insert
      }

      // Import tasks
      final tasksData = importData['tasks'] as List<dynamic>? ?? [];
      final taskIdMap = <int, int>{};
      for (final t in tasksData) {
        if (t is! Map<String, dynamic>) continue;
        final task = Task.fromMap(t);
        final oldTaskId = task.id;
        // Remap project ID
        final newProjectId = task.projectId != null
            ? projectIdMap[task.projectId]
            : null;
        final newTaskId = await _db.insertTask(
          task.copyWith(
            id: null, // Clear ID for insert
            projectId: newProjectId,
          ),
        );
        if (oldTaskId != null) {
          taskIdMap[oldTaskId] = newTaskId;
        }
      }

      // Import transactions
      final transactionsData =
          importData['transactions'] as List<dynamic>? ?? [];
      for (final t in transactionsData) {
        if (t is! Map<String, dynamic>) continue;
        final transaction = Transaction.fromMap(t);
        await _db.insertTransaction(
          Transaction(
            description: transaction.description,
            amount: transaction.amount,
            category: transaction.category,
            isIncome: transaction.isIncome,
            date: transaction.date,
          ),
        );
      }

      // Import notes
      final notesData = importData['notes'] as List<dynamic>? ?? [];
      for (final n in notesData) {
        if (n is! Map<String, dynamic>) continue;
        final note = Note.fromMap(n);
        await _db.insertNote(note.copyWith(id: null));
      }

      // Import shopping items
      final shoppingData = importData['shoppingItems'] as List<dynamic>? ?? [];
      for (final s in shoppingData) {
        if (s is! Map<String, dynamic>) continue;
        final item = ShoppingItem.fromMap(s);
        await _db.insertShoppingItem(item.copyWith(id: null));
      }

      // Import journal entries
      final journalData = importData['journalEntries'] as List<dynamic>? ?? [];
      for (final j in journalData) {
        if (j is! Map<String, dynamic>) continue;
        final entry = JournalEntry.fromMap(j);
        await _db.insertJournalEntry(entry.copyWith(id: null));
      }

      final focusSessionsData =
          importData['focusSessions'] as List<dynamic>? ?? [];
      for (final sessionMap in focusSessionsData) {
        if (sessionMap is! Map<String, dynamic>) continue;
        final focusSession = FocusSession.fromMap(sessionMap);
        final remappedTaskId = focusSession.taskId != null
            ? taskIdMap[focusSession.taskId!]
            : null;
        final normalizedStatus = focusSession.isActive
            ? (focusSession.completedFocusSessions > 0
                  ? FocusSessionStatus.completed
                  : FocusSessionStatus.cancelled)
            : focusSession.status;
        final normalizedCompletedAt = focusSession.isActive
            ? DateTime.now()
            : focusSession.completedAt;

        await _db.insertFocusSession(
          focusSession.copyWith(
            id: null,
            taskId: remappedTaskId,
            status: normalizedStatus,
            updatedAt: normalizedCompletedAt ?? focusSession.updatedAt,
            completedAt: normalizedCompletedAt,
          ),
        );
      }

      return DataImportResult(
        success: true,
        message: 'Backup restored successfully.',
        settings: backupSettings,
      );
    } on FormatException {
      return const DataImportResult(
        success: false,
        message: 'Backup file is not valid JSON.',
      );
    } catch (e) {
      debugPrint('Import error: $e');
      return const DataImportResult(
        success: false,
        message: 'Import failed due to unexpected data or format issues.',
      );
    }
  }

  // Helper methods

  String _escapeCsv(String value) {
    if (value.isEmpty) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> _writeCsvFile(
    String path,
    List<String> headers,
    List<List<String>> rows,
  ) async {
    final file = File(path);
    final buffer = StringBuffer();

    // Write headers
    buffer.writeln(headers.join(','));

    // Write rows
    for (final row in rows) {
      buffer.writeln(row.join(','));
    }

    await file.writeAsString(buffer.toString());
  }
}
