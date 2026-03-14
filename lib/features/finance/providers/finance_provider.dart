import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bill_model.dart';
import '../models/transaction_model.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/database_helper.dart';

final transactionListProvider =
    AsyncNotifierProvider<TransactionNotifier, List<Transaction>>(
      TransactionNotifier.new,
    );

class TransactionNotifier extends AsyncNotifier<List<Transaction>> {
  final _db = DatabaseHelper();
  @override
  Future<List<Transaction>> build() async => _db.getTransactions();

  Future<void> addTransaction(Transaction t) async {
    await _db.insertTransaction(t);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    ref.invalidateSelf();
    await future;
  }
}

final billListProvider = AsyncNotifierProvider<BillNotifier, List<Bill>>(
  BillNotifier.new,
);

class BillNotifier extends AsyncNotifier<List<Bill>> {
  final _db = DatabaseHelper();
  final _notifications = NotificationService.instance;

  @override
  Future<List<Bill>> build() async {
    final bills = await _db.getBills();
    await _syncAllBillReminders(bills);
    return bills;
  }

  Future<void> resyncBillReminders() async {
    final bills = await _db.getBills();
    await _syncAllBillReminders(bills);
  }

  Future<void> addBill(Bill bill) async {
    final now = DateTime.now();
    final billToInsert = bill.copyWith(createdAt: now, updatedAt: now);
    final id = await _db.insertBill(billToInsert);
    await _syncBillReminder(billToInsert.copyWith(id: id));
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateBill(Bill bill) async {
    final updated = bill.copyWith(updatedAt: DateTime.now());
    await _db.updateBill(updated);
    await _syncBillReminder(updated);
    ref.invalidateSelf();
    await future;
  }

  Future<void> toggleBillPaid(Bill bill, bool paid) async {
    final updated = bill.copyWith(
      paid: paid,
      paidAt: paid ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    await _db.updateBill(updated);
    await _syncBillReminder(updated);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteBill(int id) async {
    await _notifications.cancelBillReminder(id);
    await _db.deleteBill(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> _syncAllBillReminders(List<Bill> bills) async {
    for (final bill in bills) {
      await _syncBillReminder(bill);
    }
  }

  Future<void> _syncBillReminder(Bill bill) async {
    if (bill.id == null) return;

    await _notifications.cancelBillReminder(bill.id!);

    if (!bill.reminderEnabled || bill.paid) {
      return;
    }

    final reminderAt = _nextReminderAt(bill, DateTime.now());
    if (reminderAt == null) {
      return;
    }

    await _notifications.scheduleBillReminder(
      billId: bill.id!,
      billTitle: bill.title,
      reminderAt: reminderAt,
    );
  }

  DateTime? _nextReminderAt(Bill bill, DateTime now) {
    final lead = Duration(minutes: bill.leadMinutes.clamp(0, 525600));

    if (bill.recurrence == BillRecurrence.oneTime) {
      final trigger = bill.dueDate.subtract(lead);
      return trigger.isAfter(now) ? trigger : null;
    }

    var year = now.year;
    var month = now.month;

    for (var i = 0; i < 24; i++) {
      final maxDay = _daysInMonth(year, month);
      final dueDay = bill.dueDate.day <= maxDay ? bill.dueDate.day : maxDay;
      final due = DateTime(
        year,
        month,
        dueDay,
        bill.dueDate.hour,
        bill.dueDate.minute,
      );
      final trigger = due.subtract(lead);
      if (trigger.isAfter(now)) {
        return trigger;
      }

      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
    }

    return null;
  }

  int _daysInMonth(int year, int month) {
    final nextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }
}
