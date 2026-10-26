import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/attendance_entry.dart';
import '../models/course.dart';
import '../models/grade_entry.dart';
import '../models/school_note.dart';
import '../models/school_task.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final String path = p.join(await getDatabasesPath(), 'pelajarku.db');
    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createSchema,
    );
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        teacher TEXT NOT NULL DEFAULT '',
        room TEXT NOT NULL DEFAULT '',
        color_value INTEGER NOT NULL,
        day_of_week INTEGER NOT NULL,
        start_minutes INTEGER NOT NULL,
        end_minutes INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        course_id TEXT,
        type TEXT NOT NULL,
        due_at INTEGER NOT NULL,
        reminder_at INTEGER,
        priority TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        is_done INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE grades (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        category TEXT NOT NULL,
        score REAL NOT NULL,
        max_score REAL NOT NULL,
        weight REAL NOT NULL,
        date INTEGER NOT NULL,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance (
        id TEXT PRIMARY KEY,
        course_id TEXT NOT NULL,
        date INTEGER NOT NULL,
        status TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        course_id TEXT,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(course_id) REFERENCES courses(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_tasks_due_at ON tasks(due_at)');
    await db.execute('CREATE INDEX idx_courses_day ON courses(day_of_week)');
    await db.execute('CREATE INDEX idx_grades_course ON grades(course_id)');
    await db.execute('CREATE INDEX idx_attendance_date ON attendance(date)');

    final Batch batch = db.batch();
    final List<Course> seedCourses = <Course>[
      const Course(
        id: 'seed-matematika',
        name: 'Matematika',
        teacher: 'Ibu Rina',
        room: 'Kelas 10A',
        colorValue: 0xFF2563EB,
        dayOfWeek: DateTime.monday,
        startMinutes: 7 * 60,
        endMinutes: 8 * 60 + 30,
      ),
      const Course(
        id: 'seed-bahasa-indonesia',
        name: 'Bahasa Indonesia',
        teacher: 'Pak Dedi',
        room: 'Kelas 10A',
        colorValue: 0xFF16A34A,
        dayOfWeek: DateTime.monday,
        startMinutes: 8 * 60 + 45,
        endMinutes: 10 * 60 + 15,
      ),
      const Course(
        id: 'seed-ipa',
        name: 'IPA',
        teacher: 'Ibu Sari',
        room: 'Lab IPA',
        colorValue: 0xFFEA580C,
        dayOfWeek: DateTime.tuesday,
        startMinutes: 7 * 60,
        endMinutes: 8 * 60 + 30,
      ),
    ];
    for (final Course course in seedCourses) {
      batch.insert('courses', course.toMap());
    }
    batch.insert('settings', <String, Object?>{
      'setting_key': 'student_name',
      'setting_value': 'Pelajar Indonesia',
    });
    batch.insert('settings', <String, Object?>{
      'setting_key': 'school_name',
      'setting_value': 'Sekolah Saya',
    });
    batch.insert('settings', <String, Object?>{
      'setting_key': 'class_name',
      'setting_value': 'Kelas 10',
    });
    batch.insert('settings', <String, Object?>{
      'setting_key': 'semester',
      'setting_value': 'Ganjil',
    });
    batch.insert('settings', <String, Object?>{
      'setting_key': 'kkm',
      'setting_value': '75',
    });
    batch.insert('settings', <String, Object?>{
      'setting_key': 'timezone',
      'setting_value': 'Asia/Jakarta',
    });
    await batch.commit(noResult: true);
  }

  Future<void> _upsertById(
    Database db,
    String table,
    Map<String, Object?> values,
  ) async {
    final Object? id = values['id'];
    if (id == null) {
      throw ArgumentError('Kolom id wajib diisi untuk upsert tabel $table.');
    }
    final int updated = await db.update(
      table,
      values,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    if (updated == 0) {
      await db.insert(table, values);
    }
  }

  Future<List<Course>> getCourses() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'courses',
      orderBy: 'day_of_week ASC, start_minutes ASC',
    );
    return rows.map(Course.fromMap).toList();
  }

  Future<void> upsertCourse(Course course) async {
    final Database db = await database;
    await _upsertById(db, 'courses', course.toMap());
  }

  Future<void> deleteCourse(String id) async {
    final Database db = await database;
    await db.delete('courses', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<SchoolTask>> getTasks() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'tasks',
      orderBy: 'is_done ASC, due_at ASC',
    );
    return rows.map(SchoolTask.fromMap).toList();
  }

  Future<void> upsertTask(SchoolTask task) async {
    final Database db = await database;
    await _upsertById(db, 'tasks', task.toMap());
  }

  Future<void> deleteTask(String id) async {
    final Database db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<GradeEntry>> getGrades() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'grades',
      orderBy: 'date DESC',
    );
    return rows.map(GradeEntry.fromMap).toList();
  }

  Future<void> upsertGrade(GradeEntry grade) async {
    final Database db = await database;
    await _upsertById(db, 'grades', grade.toMap());
  }

  Future<void> deleteGrade(String id) async {
    final Database db = await database;
    await db.delete('grades', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<AttendanceEntry>> getAttendance() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'attendance',
      orderBy: 'date DESC',
    );
    return rows.map(AttendanceEntry.fromMap).toList();
  }

  Future<void> upsertAttendance(AttendanceEntry entry) async {
    final Database db = await database;
    await _upsertById(db, 'attendance', entry.toMap());
  }

  Future<void> deleteAttendance(String id) async {
    final Database db = await database;
    await db.delete('attendance', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<SchoolNote>> getNotes() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query(
      'notes',
      orderBy: 'updated_at DESC',
    );
    return rows.map(SchoolNote.fromMap).toList();
  }

  Future<void> upsertNote(SchoolNote note) async {
    final Database db = await database;
    await _upsertById(db, 'notes', note.toMap());
  }

  Future<void> deleteNote(String id) async {
    final Database db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<Map<String, String>> getSettings() async {
    final Database db = await database;
    final List<Map<String, Object?>> rows = await db.query('settings');
    return <String, String>{
      for (final Map<String, Object?> row in rows)
        row['setting_key']! as String: row['setting_value']! as String,
    };
  }

  Future<void> setSetting(String key, String value) async {
    final Database db = await database;
    await db.insert(
      'settings',
      <String, Object?>{'setting_key': key, 'setting_value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
