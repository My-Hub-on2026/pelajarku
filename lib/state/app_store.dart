import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../data/app_database.dart';
import '../models/attendance_entry.dart';
import '../models/course.dart';
import '../models/grade_entry.dart';
import '../models/school_note.dart';
import '../models/school_task.dart';
import '../services/notification_service.dart';
import '../services/parent_email_service.dart';

class AppStore extends ChangeNotifier {
  AppStore({
    AppDatabase? database,
    NotificationService? notifications,
  })  : _database = database ?? AppDatabase.instance,
        _notifications = notifications ?? NotificationService.instance;

  final AppDatabase _database;
  final NotificationService _notifications;

  bool isLoading = true;
  String? errorMessage;
  List<Course> courses = <Course>[];
  List<SchoolTask> tasks = <SchoolTask>[];
  List<GradeEntry> grades = <GradeEntry>[];
  List<AttendanceEntry> attendance = <AttendanceEntry>[];
  List<SchoolNote> notes = <SchoolNote>[];
  Map<String, String> settings = <String, String>{};

  Future<void> initialize() async {
    isLoading = true;
    notifyListeners();
    try {
      settings = await _database.getSettings();
      await _notifications.initialize(
        timezoneName: settings['timezone'] ?? 'Asia/Jakarta',
      );
      await ParentEmailService.instance.initialize();
      await reload();
      await _notifications.rescheduleAll(tasks,
          (id) => courseById(id)?.name ?? 'Sekolah');
      errorMessage = null;
    } catch (error, stackTrace) {
      errorMessage = error.toString();
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    final List<Object> data = await Future.wait<Object>(<Future<Object>>[
      _database.getCourses(),
      _database.getTasks(),
      _database.getGrades(),
      _database.getAttendance(),
      _database.getNotes(),
      _database.getSettings(),
    ]);
    courses = data[0] as List<Course>;
    tasks = data[1] as List<SchoolTask>;
    grades = data[2] as List<GradeEntry>;
    attendance = data[3] as List<AttendanceEntry>;
    notes = data[4] as List<SchoolNote>;
    settings = data[5] as Map<String, String>;
    notifyListeners();
  }

  Course? courseById(String? id) {
    if (id == null) return null;
    for (final Course course in courses) {
      if (course.id == id) return course;
    }
    return null;
  }

  List<Course> coursesForDay(int dayOfWeek) => courses
      .where((Course course) => course.dayOfWeek == dayOfWeek)
      .toList()
    ..sort((Course a, Course b) => a.startMinutes.compareTo(b.startMinutes));

  List<SchoolTask> get upcomingTasks {
    final DateTime now = DateTime.now();
    final List<SchoolTask> result = tasks
        .where((SchoolTask task) => !task.isDone && task.dueAt.isAfter(now))
        .toList()
      ..sort((SchoolTask a, SchoolTask b) => a.dueAt.compareTo(b.dueAt));
    return result;
  }

  double get weightedAverage {
    if (grades.isEmpty) return 0;
    double total = 0;
    double totalWeight = 0;
    for (final GradeEntry grade in grades) {
      total += grade.percentage * grade.weight;
      totalWeight += grade.weight;
    }
    return totalWeight == 0 ? 0 : total / totalWeight;
  }

  double averageForCourse(String courseId) {
    final List<GradeEntry> entries = grades
        .where((GradeEntry grade) => grade.courseId == courseId)
        .toList();
    if (entries.isEmpty) return 0;
    double total = 0;
    double totalWeight = 0;
    for (final GradeEntry grade in entries) {
      total += grade.percentage * grade.weight;
      totalWeight += grade.weight;
    }
    return totalWeight == 0 ? 0 : total / totalWeight;
  }

  double get attendanceRate {
    if (attendance.isEmpty) return 100;
    final int present = attendance
        .where((AttendanceEntry entry) => entry.status == AttendanceStatus.hadir)
        .length;
    return present / attendance.length * 100;
  }

  Future<void> saveCourse(Course course) async {
    await _database.upsertCourse(course);
    ParentEmailService.instance.notifyChange(type: 'jadwal', action: 'diubah', summary: course.name);
    await reload();
  }

  Future<void> deleteCourse(Course course) async {
    await _database.deleteCourse(course.id);
    ParentEmailService.instance.notifyChange(type: 'jadwal', action: 'dihapus', summary: course.name);
    await reload();
  }

  Future<void> saveTask(SchoolTask task) async {
    await _database.upsertTask(task);
    ParentEmailService.instance.notifyChange(type: 'tugas', action: 'diubah', summary: task.title);
    await _notifications.scheduleTask(
      task,
      courseById(task.courseId)?.name ?? 'Sekolah',
    );
    await reload();
  }

  Future<void> toggleTask(SchoolTask task) async {
    final SchoolTask updated = task.copyWith(isDone: !task.isDone);
    await _database.upsertTask(updated);
    ParentEmailService.instance.notifyChange(type: 'tugas', action: updated.isDone ? 'diselesaikan' : 'diubah', summary: updated.title);
    if (updated.isDone) {
      await _notifications.cancelTask(updated);
    } else {
      await _notifications.scheduleTask(
        updated,
        courseById(updated.courseId)?.name ?? 'Sekolah',
      );
    }
    await reload();
  }

  Future<void> deleteTask(SchoolTask task) async {
    await _notifications.cancelTask(task);
    await _database.deleteTask(task.id);
    ParentEmailService.instance.notifyChange(type: 'tugas', action: 'dihapus', summary: task.title);
    await reload();
  }

  Future<void> saveGrade(GradeEntry grade) async {
    await _database.upsertGrade(grade);
    ParentEmailService.instance.notifyChange(type: 'nilai', action: 'diubah', summary: grade.category);
    await reload();
  }

  Future<void> deleteGrade(GradeEntry grade) async {
    await _database.deleteGrade(grade.id);
    ParentEmailService.instance.notifyChange(type: 'nilai', action: 'dihapus', summary: grade.category);
    await reload();
  }

  Future<void> saveAttendance(AttendanceEntry entry) async {
    await _database.upsertAttendance(entry);
    ParentEmailService.instance.notifyChange(type: 'kehadiran', action: 'diubah', summary: entry.status.name);
    await reload();
  }

  Future<void> deleteAttendance(AttendanceEntry entry) async {
    await _database.deleteAttendance(entry.id);
    ParentEmailService.instance.notifyChange(type: 'kehadiran', action: 'dihapus', summary: entry.status.name);
    await reload();
  }

  Future<void> saveNote(SchoolNote note) async {
    await _database.upsertNote(note);
    ParentEmailService.instance.notifyChange(type: 'catatan', action: 'diubah', summary: note.title);
    await reload();
  }

  Future<void> deleteNote(SchoolNote note) async {
    await _database.deleteNote(note.id);
    ParentEmailService.instance.notifyChange(type: 'catatan', action: 'dihapus', summary: note.title);
    await reload();
  }

  Future<void> setSetting(String key, String value) async {
    await _database.setSetting(key, value);
    if (key != 'parent_email') { ParentEmailService.instance.notifyChange(type: 'profil', action: 'diubah', summary: 'Pengaturan $key'); }
    settings[key] = value;
    notifyListeners();
  }

  Future<bool> requestNotificationPermission() async {
    final granted = await _notifications.requestPermissions();
    if (granted) {
      await _notifications.rescheduleAll(tasks,
          (id) => courseById(id)?.name ?? 'Sekolah');
    }
    return granted;
  }

  Future<void> testNotification() => _notifications.showTest();
  Future<int> pendingNotifications() => _notifications.pendingCount();
}

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({
    required AppStore store,
    required Widget child,
    Key? key,
  }) : super(key: key, notifier: store, child: child);

  static AppStore of(BuildContext context) {
    final AppScope? scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope tidak ditemukan pada widget tree.');
    return scope!.notifier!;
  }
}
