enum NoteType { text, list }

class NoteListItem {
  final String text;
  final bool checked;

  NoteListItem({required this.text, this.checked = false});

  Map<String, dynamic> toMap() => {'text': text, 'checked': checked ? 1 : 0};

  factory NoteListItem.fromMap(Map<String, dynamic> map) =>
      NoteListItem(text: map['text'], checked: (map['checked'] ?? 0) == 1);

  NoteListItem copyWith({String? text, bool? checked}) {
    return NoteListItem(
      text: text ?? this.text,
      checked: checked ?? this.checked,
    );
  }
}

class Note {
  final int? id;
  final String title;
  final String content;
  final List<NoteListItem> listItems;
  final NoteType type;
  final String folder;
  final String tags;
  final DateTime createdAt;

  Note({
    this.id,
    required this.title,
    this.content = '',
    this.listItems = const [],
    this.type = NoteType.text,
    this.folder = 'ALL',
    this.tags = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'content': content,
    'list_items': listItems.isEmpty
        ? null
        : listItems.map((e) => e.toMap()).toList(),
    'type': type.name,
    'folder': folder,
    'tags': tags,
    'created_at': createdAt.toIso8601String(),
  };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
    id: map['id'],
    title: map['title'],
    content: map['content'] ?? '',
    listItems: map['list_items'] == null
        ? []
        : List<Map<String, dynamic>>.from(
            map['list_items'],
          ).map((e) => NoteListItem.fromMap(e)).toList(),
    type: map['type'] == 'list' ? NoteType.list : NoteType.text,
    folder: map['folder'] ?? 'ALL',
    tags: map['tags'] ?? '',
    createdAt: DateTime.parse(map['created_at']),
  );

  Note copyWith({
    int? id,
    String? title,
    String? content,
    List<NoteListItem>? listItems,
    NoteType? type,
    String? folder,
    String? tags,
    DateTime? createdAt,
  }) => Note(
    id: id ?? this.id,
    title: title ?? this.title,
    content: content ?? this.content,
    listItems: listItems ?? this.listItems,
    type: type ?? this.type,
    folder: folder ?? this.folder,
    tags: tags ?? this.tags,
    createdAt: createdAt ?? this.createdAt,
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
