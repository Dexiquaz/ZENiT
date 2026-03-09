import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
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
