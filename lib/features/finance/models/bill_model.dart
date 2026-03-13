enum BillRecurrence { oneTime, monthly }

class Bill {
  final int? id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final BillRecurrence recurrence;
  final bool reminderEnabled;
  final int leadMinutes;
  final bool paid;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bill({
    this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.recurrence,
    required this.reminderEnabled,
    required this.leadMinutes,
    required this.paid,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
  });

  Bill copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    BillRecurrence? recurrence,
    bool? reminderEnabled,
    int? leadMinutes,
    bool? paid,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      leadMinutes: leadMinutes ?? this.leadMinutes,
      paid: paid ?? this.paid,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'due_date': dueDate.toIso8601String(),
    'recurrence': recurrence.index,
    'reminder_enabled': reminderEnabled ? 1 : 0,
    'lead_minutes': leadMinutes,
    'paid': paid ? 1 : 0,
    'paid_at': paidAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.parse(map['due_date'] as String),
      recurrence:
          BillRecurrence.values[(map['recurrence'] as int?)?.clamp(
                0,
                BillRecurrence.values.length - 1,
              ) ??
              0],
      reminderEnabled: (map['reminder_enabled'] as int? ?? 0) == 1,
      leadMinutes: (map['lead_minutes'] as int? ?? 0).clamp(0, 525600),
      paid: (map['paid'] as int? ?? 0) == 1,
      paidAt: (map['paid_at'] as String?) == null
          ? null
          : DateTime.parse(map['paid_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  bool isOverdue({DateTime? now}) {
    final reference = now ?? DateTime.now();
    return !paid &&
        recurrence == BillRecurrence.oneTime &&
        dueDate.isBefore(reference);
  }

  DateTime? nextDueDate({DateTime? from}) {
    final reference = from ?? DateTime.now();
    if (recurrence == BillRecurrence.oneTime) {
      return dueDate.isAfter(reference) ? dueDate : null;
    }

    var year = reference.year;
    var month = reference.month;

    var day = dueDate.day <= _daysInMonth(year, month)
        ? dueDate.day
        : _daysInMonth(year, month);

    var next = DateTime(year, month, day, dueDate.hour, dueDate.minute);

    if (!next.isAfter(reference)) {
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      day = dueDate.day <= _daysInMonth(year, month)
          ? dueDate.day
          : _daysInMonth(year, month);
      next = DateTime(year, month, day, dueDate.hour, dueDate.minute);
    }

    return next;
  }

  static int _daysInMonth(int year, int month) {
    final nextMonth = month == 12
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return nextMonth.subtract(const Duration(days: 1)).day;
  }
}
