enum AttendanceStatus { hadir, izin, sakit, alpa }

class AttendanceEntry {
  const AttendanceEntry({
    required this.id,
    required this.courseId,
    required this.date,
    required this.status,
    this.note = '',
  });

  final String id;
  final String courseId;
  final DateTime date;
  final AttendanceStatus status;
  final String note;

  Map<String, Object?> toMap() => <String, Object?>{
        'id': id,
        'course_id': courseId,
        'date': date.millisecondsSinceEpoch,
        'status': status.name,
        'note': note,
      };

  factory AttendanceEntry.fromMap(Map<String, Object?> map) {
    return AttendanceEntry(
      id: map['id']! as String,
      courseId: map['course_id']! as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date']! as int),
      status: AttendanceStatus.values.byName(map['status']! as String),
      note: (map['note'] as String?) ?? '',
    );
  }
}
