import 'package:flutter_test/flutter_test.dart';
import 'package:pelajarku/models/grade_entry.dart';
import 'package:pelajarku/models/school_task.dart';

void main() {
  test('persentase nilai dihitung dari skor dan nilai maksimum', () {
    final GradeEntry grade = GradeEntry(
      id: 'g-1',
      courseId: 'c-1',
      category: 'Kuis',
      score: 80,
      maxScore: 100,
      weight: 1,
      date: DateTime(2026, 7, 20),
    );

    expect(grade.percentage, 80);
  });

  test('ID notifikasi stabil untuk tugas yang sama', () {
    final SchoolTask task = SchoolTask(
      id: 'tugas-matematika-1',
      title: 'Latihan persamaan',
      courseId: 'c-1',
      type: TaskType.tugas,
      dueAt: DateTime(2026, 7, 21, 7),
      reminderAt: DateTime(2026, 7, 20, 19),
      priority: TaskPriority.tinggi,
      notes: '',
      isDone: false,
    );

    expect(task.notificationId, task.notificationId);
    expect(task.notificationId, greaterThanOrEqualTo(0));
  });
}
