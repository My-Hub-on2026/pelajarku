import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/school_task.dart';

/// Pengingat lokal. Channel v2 wajib berbeda karena Android menyimpan
/// pilihan suara/getaran channel lama sejak pertama kali dibuat.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  static const String channelId = 'pelajarku_pengingat_bersuara_v2';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const NotificationDetails details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      'Pengingat PelajarKu (Suara & Getar)',
      channelDescription: 'Pengingat tugas dan ujian dengan suara dan getaran.',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      ticker: 'Pengingat tugas PelajarKu',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> initialize({String timezoneName = 'Asia/Jakarta'}) async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    }
    if (_initialized) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            'Pengingat PelajarKu (Suara & Getar)',
            description: 'Pengingat tugas dan ujian dengan suara dan getaran.',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final bool? notif = await android?.requestNotificationsPermission();
    // SCHEDULE_EXACT_ALARM memerlukan izin terpisah pada Android 12+.
    // Pengguna dapat menolak; penjadwalan akan otomatis beralih ke inexact.
    await android?.requestExactAlarmsPermission();
    final bool? ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return (notif ?? ios ?? true);
  }

  Future<bool> notificationsEnabled() async {
    return await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        true;
  }

  Future<int> pendingCount() async =>
      (await _plugin.pendingNotificationRequests()).length;

  Future<void> showTest() async {
    if (!_initialized) return;
    await _plugin.show(
      id: 20261027,
      title: 'Tes Pengingat PelajarKu',
      body: 'Jika pengaturan perangkat mengizinkan, ini akan berbunyi dan bergetar.',
      notificationDetails: details,
    );
  }

  Future<void> scheduleTask(SchoolTask task, String courseName) async {
    if (!_initialized) return;
    // Selalu batalkan yang lama dahulu, termasuk saat pengingat dinonaktifkan.
    await cancelTask(task);
    if (task.reminderAt == null || task.isDone) return;
    if (!task.reminderAt!.isAfter(DateTime.now())) return;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final exact = await android?.canScheduleExactNotifications() ?? false;
    await _plugin.zonedSchedule(
      id: task.notificationId,
      title: 'Pengingat ${task.type.name}',
      body: '$courseName • ${task.title}',
      scheduledDate: tz.TZDateTime.from(task.reminderAt!, tz.local),
      notificationDetails: details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: task.id,
    );
  }

  Future<void> rescheduleAll(
    List<SchoolTask> tasks,
    String Function(String?) getCourseName,
  ) async {
    for (final task in tasks) {
      await scheduleTask(task, getCourseName(task.courseId));
    }
  }

  Future<void> cancelTask(SchoolTask task) async {
    if (!_initialized) return;
    await _plugin.cancel(id: task.notificationId);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
