class Transaction {
  final int? id;
  final String description;
  final double amount;
  final String category;
  final bool isIncome;
  final DateTime date;

  Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.isIncome,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'amount': amount,
    'category': category,
    'is_income': isIncome ? 1 : 0,
    'date': date.toIso8601String(),
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    description: map['description'],
    amount: (map['amount'] as num).toDouble(),
    category: map['category'],
    isIncome: (map['is_income'] ?? 0) == 1,
    date: DateTime.parse(map['date']),
  );
  static const List<String> categories = [
    'FOOD',
    'TRANSPORT',
    'RENT',
    'WORK',
    'HEALTH',
    'SHOPPING',
    'FUN',
    'MISC',
  ];
}
