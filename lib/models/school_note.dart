class SchoolNote {
  const SchoolNote({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    this.courseId,
  });

  final String id;
  final String title;
  final String body;
  final String? courseId;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'title': title,
        'body': body,
        'course_id': courseId,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory SchoolNote.fromMap(Map<String, Object?> map) {
    return SchoolNote(
      id: map['id']! as String,
      title: map['title']! as String,
      body: map['body']! as String,
      courseId: map['course_id'] as String?,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']! as int),
    );
  }
}
