class Note {
  final int? id;
  final String title;
  final String content;
  final String folder;
  final String tags;
  final DateTime createdAt;

  Note({
    this.id,
    required this.title,
    this.content = '',
    this.folder = 'ALL',
    this.tags = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'folder': folder,
    'tags': tags,
    'created_at': createdAt.toIso8601String(),
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'],
    title: map['title'],
    content: map['content'] ?? '',
    folder: map['folder'] ?? 'ALL',
    tags: map['tags'] ?? '',
    createdAt: DateTime.parse(map['created_at']),
  );

  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? folder,
    String? tags,
    DateTime? createdAt,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    folder: folder ?? this.folder,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
  );
}

class ShoppingItem {
  final int? id;
  final String name;
  final int quantity;
  final String category;
  final bool checked;

  ShoppingItem({
    this.id,
    required this.name,
    this.quantity = 1,
    this.category = 'General',
    this.checked = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'category': category,
    'checked': checked ? 1 : 0,
  };

  factory ShoppingItem.fromMap(Map<String, dynamic> map) => ShoppingItem(
    id: map['id'],
    name: map['name'],
    quantity: map['quantity'] ?? 1,
    category: map['category'] ?? 'General',
    checked: (map['checked'] ?? 0) == 1,
  );

  ShoppingItem copyWith({
    int? id,
    String? name,
    int? quantity,
    String? category,
    bool? checked,
  }) => ShoppingItem(
    id: id ?? this.id,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    category: category ?? this.category,
    checked: checked ?? this.checked,
  );
}

class JournalEntry {
  final int? id;
  final DateTime timestamp;
  final String title;
  final String content;
  final String? mood;

  JournalEntry({
    this.id,
    required this.timestamp,
    this.title = '',
    this.content = '',
    this.mood,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'title': title,
    'content': content,
    'mood': mood,
  };

  factory JournalEntry.fromMap(Map<String, dynamic> map) => JournalEntry(
    id: map['id'],
    timestamp: DateTime.parse(
      map['timestamp'] ?? map['date'] ?? DateTime.now().toIso8601String(),
    ),
    title: map['title'] ?? '',
    content: map['content'] ?? '',
    mood: map['mood'],
  );

  JournalEntry copyWith({
    int? id,
    DateTime? timestamp,
    String? title,
    String? content,
    String? mood,
  }) => JournalEntry(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    title: title ?? this.title,
    content: content ?? this.content,
    mood: mood ?? this.mood,
  );
}
