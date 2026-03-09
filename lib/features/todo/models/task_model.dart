enum TaskPriority { low, medium, high }

class Task {
  static const _unset = Object();

  final int? id;
  final String title;
  final int? projectId;
  final int? parentId;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final bool pinned;
  final bool completed;
  final DateTime createdAt;

  Task({
    this.id,
    required this.title,
    this.projectId,
    this.parentId,
    this.priority = TaskPriority.low,
    this.dueDate,
    this.reminderAt,
    this.pinned = false,
    this.completed = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'project_id': projectId,
    'parent_id': parentId,
    'priority': priority.index,
    'due_date': dueDate?.toIso8601String(),
    'reminder_at': reminderAt?.toIso8601String(),
    'is_pinned': pinned ? 1 : 0,
    'completed': completed ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'],
    title: map['title'],
    projectId: map['project_id'],
    parentId: map['parent_id'],
    priority: TaskPriority.values[map['priority'] ?? 0],
    dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
    reminderAt: map['reminder_at'] != null
        ? DateTime.parse(map['reminder_at'])
        : null,
    pinned: (map['is_pinned'] ?? 0) == 1,
    completed: (map['completed'] ?? 0) == 1,
    createdAt: DateTime.parse(map['created_at']),
  );

  Task copyWith({
    int? id,
    String? title,
    int? projectId,
    int? parentId,
    TaskPriority? priority,
    Object? dueDate = _unset,
    Object? reminderAt = _unset,
    bool? pinned,
    bool? completed,
    DateTime? createdAt,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    projectId: projectId ?? this.projectId,
    parentId: parentId ?? this.parentId,
    priority: priority ?? this.priority,
    dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
    reminderAt: identical(reminderAt, _unset)
        ? this.reminderAt
        : reminderAt as DateTime?,
    pinned: pinned ?? this.pinned,
    completed: completed ?? this.completed,
    createdAt: createdAt ?? this.createdAt,
  );
}

class Project {
  final int? id;
  final String name;
  final int taskCount;

  Project({this.id, required this.name, this.taskCount = 0});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  factory Project.fromMap(Map<String, dynamic> map) => Project(
    id: map['id'],
    name: map['name'],
    taskCount: map['task_count'] ?? 0,
  );
}
