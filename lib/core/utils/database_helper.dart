import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import '../../features/habit_tracker/models/habit.dart';
import '../../features/todo/models/task_model.dart';
import '../../features/finance/models/transaction_model.dart';
import '../../features/notes_shopping/models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'personal_organizer.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT,
        recurrence INTEGER, category TEXT, reminder_enabled INTEGER DEFAULT 0,
        reminder_hour INTEGER, reminder_minute INTEGER, reminder_weekday INTEGER,
        reminder_day_of_month INTEGER, created_at TEXT, completion_dates TEXT
      )''');
    await db.execute('''
      CREATE TABLE projects(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT
      )''');
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, project_id INTEGER,
        parent_id INTEGER, priority INTEGER, due_date TEXT, reminder_at TEXT,
        is_pinned INTEGER DEFAULT 0, completed INTEGER,
        created_at TEXT, FOREIGN KEY(project_id) REFERENCES projects(id)
      )''');
    await db.execute('''
      CREATE TABLE transactions_log(
        id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT, amount REAL,
        category TEXT, is_income INTEGER, date TEXT
      )''');
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT,
        folder TEXT, tags TEXT, created_at TEXT
      )''');
    await db.execute('''
      CREATE TABLE shopping_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, quantity INTEGER,
        category TEXT, checked INTEGER
      )''');
    await db.execute('''
      CREATE TABLE journal_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        title TEXT,
        content TEXT,
        mood TEXT
      )''');
    // Seed default project
    await db.insert('projects', {'name': 'PERSONAL'});
    await db.insert('projects', {'name': 'WORK OPS'});
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'CREATE TABLE IF NOT EXISTS projects(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)',
      );
      await db.execute(
        'CREATE TABLE IF NOT EXISTS tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, project_id INTEGER, parent_id INTEGER, priority INTEGER, due_date TEXT, completed INTEGER, created_at TEXT)',
      );
      await db.execute(
        'CREATE TABLE IF NOT EXISTS transactions_log(id INTEGER PRIMARY KEY AUTOINCREMENT, description TEXT, amount REAL, category TEXT, is_income INTEGER, date TEXT)',
      );
      await db.execute(
        'CREATE TABLE IF NOT EXISTS notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT, folder TEXT, tags TEXT, created_at TEXT)',
      );
      await db.execute(
        'CREATE TABLE IF NOT EXISTS shopping_items(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, quantity INTEGER, category TEXT, checked INTEGER)',
      );
      await db.execute(
        'CREATE TABLE IF NOT EXISTS journal_entries(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT UNIQUE, content TEXT)',
      );
      await db.insert('projects', {
        'name': 'PERSONAL',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('projects', {
        'name': 'WORK OPS',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    if (oldVersion < 3) {
      final taskColumns = await db.rawQuery('PRAGMA table_info(tasks)');
      final hasPinnedColumn = taskColumns.any((c) => c['name'] == 'is_pinned');
      if (!hasPinnedColumn) {
        await db.execute(
          'ALTER TABLE tasks ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0',
        );
      }
    }

    if (oldVersion < 4) {
      final taskColumns = await db.rawQuery('PRAGMA table_info(tasks)');
      final hasReminderColumn = taskColumns.any(
        (c) => c['name'] == 'reminder_at',
      );
      if (!hasReminderColumn) {
        await db.execute('ALTER TABLE tasks ADD COLUMN reminder_at TEXT');
      }
    }

    if (oldVersion < 5) {
      final habitColumns = await db.rawQuery('PRAGMA table_info(habits)');
      final hasReminderEnabled = habitColumns.any(
        (c) => c['name'] == 'reminder_enabled',
      );
      final hasReminderHour = habitColumns.any(
        (c) => c['name'] == 'reminder_hour',
      );
      final hasReminderMinute = habitColumns.any(
        (c) => c['name'] == 'reminder_minute',
      );
      final hasReminderWeekday = habitColumns.any(
        (c) => c['name'] == 'reminder_weekday',
      );
      final hasReminderDayOfMonth = habitColumns.any(
        (c) => c['name'] == 'reminder_day_of_month',
      );

      if (!hasReminderEnabled) {
        await db.execute(
          'ALTER TABLE habits ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!hasReminderHour) {
        await db.execute('ALTER TABLE habits ADD COLUMN reminder_hour INTEGER');
      }
      if (!hasReminderMinute) {
        await db.execute(
          'ALTER TABLE habits ADD COLUMN reminder_minute INTEGER',
        );
      }
      if (!hasReminderWeekday) {
        await db.execute(
          'ALTER TABLE habits ADD COLUMN reminder_weekday INTEGER',
        );
      }
      if (!hasReminderDayOfMonth) {
        await db.execute(
          'ALTER TABLE habits ADD COLUMN reminder_day_of_month INTEGER',
        );
      }
    }

    if (oldVersion < 6) {
      // Update journal_entries table schema for multiple entries per day
      try {
        await db.execute('DROP TABLE IF EXISTS journal_entries');
      } catch (_) {}
      await db.execute('''CREATE TABLE IF NOT EXISTS journal_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        title TEXT,
        content TEXT,
        mood TEXT
      )''');
    }
  }

  // ── Habits ──
  Future<int> insertHabit(Habit habit) async =>
      (await database).insert('habits', habit.toMap());
  Future<List<Habit>> getHabits() async =>
      (await (await database).query('habits')).map(Habit.fromMap).toList();
  Future<int> updateHabit(Habit habit) async => (await database).update(
    'habits',
    habit.toMap(),
    where: 'id = ?',
    whereArgs: [habit.id],
  );
  Future<int> deleteHabit(int id) async =>
      (await database).delete('habits', where: 'id = ?', whereArgs: [id]);

  // ── Projects ──
  Future<int> insertProject(String name) async =>
      (await database).insert('projects', {'name': name});
  Future<List<Project>> getProjects() async {
    final db = await database;
    final projects = await db.query('projects');
    final result = <Project>[];
    for (final p in projects) {
      final count =
          Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM tasks WHERE project_id = ?',
              [p['id']],
            ),
          ) ??
          0;
      result.add(
        Project(
          id: p['id'] as int,
          name: p['name'] as String,
          taskCount: count,
        ),
      );
    }
    return result;
  }

  Future<int> deleteProject(int id) async {
    final db = await database;
    // Delete all tasks associated with this project first
    await db.delete('tasks', where: 'project_id = ?', whereArgs: [id]);
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<int>> getTaskIdsForProject(int projectId) async {
    final db = await database;
    final maps = await db.query(
      'tasks',
      columns: ['id'],
      where: 'project_id = ?',
      whereArgs: [projectId],
    );
    return maps
        .map((row) => row['id'])
        .whereType<int>()
        .toList(growable: false);
  }

  // ── Tasks ──
  Future<int> insertTask(Task task) async =>
      (await database).insert('tasks', task.toMap());
  Future<List<Task>> getTasks({int? projectId}) async {
    final db = await database;
    final maps = projectId != null
        ? await db.query(
            'tasks',
            where: 'project_id = ?',
            whereArgs: [projectId],
          )
        : await db.query('tasks');
    return maps.map(Task.fromMap).toList();
  }

  Future<int> updateTask(Task task) async => (await database).update(
    'tasks',
    task.toMap(),
    where: 'id = ?',
    whereArgs: [task.id],
  );
  Future<int> deleteTask(int id) async =>
      (await database).delete('tasks', where: 'id = ?', whereArgs: [id]);

  Future<void> deleteAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('habits');
      await txn.delete('tasks');
      await txn.delete('projects');
      await txn.delete('transactions_log');
      await txn.delete('notes');
      await txn.delete('shopping_items');
      await txn.delete('journal_entries');

      await txn.insert('projects', {'name': 'PERSONAL'});
      await txn.insert('projects', {'name': 'WORK OPS'});
    });
  }

  // ── Transactions ──
  Future<int> insertTransaction(Transaction t) async =>
      (await database).insert('transactions_log', t.toMap());
  Future<List<Transaction>> getTransactions() async =>
      (await (await database).query(
        'transactions_log',
        orderBy: 'date DESC',
      )).map(Transaction.fromMap).toList();
  Future<int> deleteTransaction(int id) async => (await database).delete(
    'transactions_log',
    where: 'id = ?',
    whereArgs: [id],
  );

  // ── Notes ──
  Future<int> insertNote(Note n) async =>
      (await database).insert('notes', n.toMap());
  Future<List<Note>> getNotes() async => (await (await database).query(
    'notes',
    orderBy: 'created_at DESC',
  )).map(Note.fromMap).toList();
  Future<int> updateNote(Note n) async => (await database).update(
    'notes',
    n.toMap(),
    where: 'id = ?',
    whereArgs: [n.id],
  );
  Future<int> deleteNote(int id) async =>
      (await database).delete('notes', where: 'id = ?', whereArgs: [id]);

  // ── Shopping ──
  Future<int> insertShoppingItem(ShoppingItem s) async =>
      (await database).insert('shopping_items', s.toMap());
  Future<List<ShoppingItem>> getShoppingItems() async =>
      (await (await database).query(
        'shopping_items',
      )).map(ShoppingItem.fromMap).toList();
  Future<int> updateShoppingItem(ShoppingItem s) async => (await database)
      .update('shopping_items', s.toMap(), where: 'id = ?', whereArgs: [s.id]);
  Future<int> deleteShoppingItem(int id) async => (await database).delete(
    'shopping_items',
    where: 'id = ?',
    whereArgs: [id],
  );

  // ── Journal ──
  Future<void> insertJournalEntry(JournalEntry j) async {
    final db = await database;
    await db.insert('journal_entries', j.toMap());
  }

  Future<List<JournalEntry>> getJournalEntriesForDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final maps = await db.query(
      'journal_entries',
      where: "timestamp LIKE ?",
      whereArgs: ['$dateStr%'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => JournalEntry.fromMap(m)).toList();
  }

  Future<void> deleteJournalEntry(int id) async {
    final db = await database;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateJournalEntry(JournalEntry j) async {
    final db = await database;
    await db.update(
      'journal_entries',
      j.toMap(),
      where: 'id = ?',
      whereArgs: [j.id],
    );
  }

  Future<void> upsertJournalEntry(JournalEntry j) async {
    final db = await database;
    final dateStr = j.timestamp.toIso8601String().split('T')[0];
    final existing = await db.query(
      'journal_entries',
      where: "timestamp LIKE ? AND title = ?",
      whereArgs: ['$dateStr%', j.title],
    );
    if (existing.isEmpty) {
      await db.insert('journal_entries', j.toMap());
    } else {
      await db.update(
        'journal_entries',
        j.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<JournalEntry?> getJournalEntry(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final maps = await db.query(
      'journal_entries',
      where: "timestamp LIKE ?",
      whereArgs: ['$dateStr%'],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return JournalEntry.fromMap(maps.first);
  }

  Future<List<JournalEntry>> getJournalEntriesForMonth(
    int year,
    int month,
  ) async {
    final db = await database;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    final startStr = firstDay.toIso8601String().split('T')[0];
    final endStr = lastDay.toIso8601String().split('T')[0];
    final maps = await db.query(
      'journal_entries',
      where: "timestamp >= ? AND timestamp <= ?",
      whereArgs: [startStr, '$endStr 23:59:59'],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => JournalEntry.fromMap(m)).toList();
  }
}
