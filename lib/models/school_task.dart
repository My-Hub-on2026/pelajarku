enum TaskType { tugas, ujian, proyek, kegiatan }

enum TaskPriority { rendah, sedang, tinggi }

class SchoolTask {
  const SchoolTask({
    required this.id,
    required this.title,
    required this.type,
    required this.dueAt,
    required this.priority,
    this.courseId,
    this.reminderAt,
    this.notes = '',
    this.isDone = false,
  });

  final String id;
  final String title;
  final String? courseId;
  final TaskType type;
  final DateTime dueAt;
  final DateTime? reminderAt;
  final TaskPriority priority;
  final String notes;
  final bool isDone;

  int get notificationId {
    // FNV-1a 32-bit agar ID notifikasi konsisten setelah aplikasi dimulai ulang.
    int hash = 0x811C9DC5;
    for (final int byte in id.codeUnits) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash & 0x7FFFFFFF;
  }

  SchoolTask copyWith({
    String? id,
    String? title,
    String? courseId,
    bool clearCourseId = false,
    TaskType? type,
    DateTime? dueAt,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    TaskPriority? priority,
    String? notes,
    bool? isDone,
  }) {
    return SchoolTask(
      id: id ?? this.id,
      title: title ?? this.title,
      courseId: clearCourseId ? null : (courseId ?? this.courseId),
      type: type ?? this.type,
      dueAt: dueAt ?? this.dueAt,
      reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'course_id': courseId,
        'type': type.name,
        'due_at': dueAt.millisecondsSinceEpoch,
        'reminder_at': reminderAt?.millisecondsSinceEpoch,
        'priority': priority.name,
        'notes': notes,
        'is_done': isDone ? 1 : 0,
      };

  factory SchoolTask.fromMap(Map<String, Object?> map) {
    return SchoolTask(
      id: map['id']! as String,
      title: map['title']! as String,
      courseId: map['course_id'] as String?,
      type: TaskType.values.byName(map['type']! as String),
      dueAt: DateTime.fromMillisecondsSinceEpoch(map['due_at']! as int),
      reminderAt: map['reminder_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['reminder_at']! as int),
      priority: TaskPriority.values.byName(map['priority']! as String),
      notes: (map['notes'] as String?) ?? '',
      isDone: (map['is_done']! as int) == 1,
    );
  }
}
