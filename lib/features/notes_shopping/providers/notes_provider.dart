import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../../../core/utils/database_helper.dart';

final noteListProvider = AsyncNotifierProvider<NoteNotifier, List<Note>>(
  NoteNotifier.new,
);

class NoteNotifier extends AsyncNotifier<List<Note>> {
  final _db = DatabaseHelper();
  @override
  Future<List<Note>> build() async => _db.getNotes();

  Future<void> addNote(Note n) async {
    await _db.insertNote(n);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateNote(Note n) async {
    await _db.updateNote(n);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteNote(int id) async {
    await _db.deleteNote(id);
    ref.invalidateSelf();
    await future;
  }
}

final shoppingListProvider =
    AsyncNotifierProvider<ShoppingNotifier, List<ShoppingItem>>(
      ShoppingNotifier.new,
    );

class ShoppingNotifier extends AsyncNotifier<List<ShoppingItem>> {
  final _db = DatabaseHelper();
  @override
  Future<List<ShoppingItem>> build() async => _db.getShoppingItems();

  Future<void> addItem(ShoppingItem s) async {
    await _db.insertShoppingItem(s);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggleItem(ShoppingItem s) async {
    await _db.updateShoppingItem(
      ShoppingItem(
        id: s.id,
        name: s.name,
        quantity: s.quantity,
        category: s.category,
        checked: !s.checked,
      ),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateQuantity(ShoppingItem s, int qty) async {
    await _db.updateShoppingItem(
      ShoppingItem(
        id: s.id,
        name: s.name,
        quantity: qty,
        category: s.category,
        checked: s.checked,
      ),
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteItem(int id) async {
    await _db.deleteShoppingItem(id);
    ref.invalidateSelf();
    await future;
  }
}

final journalProvider =
    AsyncNotifierProvider<JournalNotifier, List<JournalEntry>>(
      JournalNotifier.new,
    );

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();
  void select(DateTime date) => state = date;
}

class JournalNotifier extends AsyncNotifier<List<JournalEntry>> {
  final _db = DatabaseHelper();
  @override
  Future<List<JournalEntry>> build() async {
    final date = ref.watch(selectedDateProvider);
    return _db.getJournalEntriesForDate(date);
  }

  Future<void> addEntry(String title, String content, {String? mood}) async {
    final date = ref.read(selectedDateProvider);
    final timestamp = DateTime(
      date.year,
      date.month,
      date.day,
      DateTime.now().hour,
      DateTime.now().minute,
    );
    await _db.insertJournalEntry(
      JournalEntry(
        timestamp: timestamp,
        title: title,
        content: content,
        mood: mood,
      ),
    );
    ref.invalidateSelf();
    ref.invalidate(daysWithEntriesProvider);
    await future;
  }

  Future<void> deleteEntry(int id) async {
    await _db.deleteJournalEntry(id);
    ref.invalidateSelf();
    ref.invalidate(daysWithEntriesProvider);
    await future;
  }

  Future<void> updateEntry(JournalEntry entry) async {
    await _db.updateJournalEntry(entry);
    ref.invalidateSelf();
    ref.invalidate(daysWithEntriesProvider);
    await future;
  }
}

// Provider for getting days with journal entries in a month
final daysWithEntriesProvider = FutureProvider.family<Set<int>, DateTime>((
  ref,
  monthDate,
) async {
  final db = DatabaseHelper();
  final entries = await db.getJournalEntriesForMonth(
    monthDate.year,
    monthDate.month,
  );
  // Extract unique days from entries
  return entries.map((e) => e.timestamp.day).toSet();
});
