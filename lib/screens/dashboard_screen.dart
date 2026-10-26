import 'package:flutter/material.dart';

import '../models/course.dart';
import '../models/school_task.dart';
import '../state/app_store.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/metric_card.dart';
import '../widgets/section_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    final DateTime now = DateTime.now();
    final List<Course> todayCourses = store.coursesForDay(now.weekday);
    final List<SchoolTask> upcoming = store.upcomingTasks.take(4).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: store.reload,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: <Widget>[
            Text(
              'Halo, ${store.settings['student_name'] ?? 'Pelajar'}!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '${store.settings['school_name'] ?? 'Sekolah Saya'} • ${store.settings['class_name'] ?? ''}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: <Widget>[
                MetricCard(
                  icon: Icons.assignment_outlined,
                  label: 'Belum selesai',
                  value: store.tasks
                      .where((SchoolTask task) => !task.isDone)
                      .length
                      .toString(),
                ),
                MetricCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'Pelajaran hari ini',
                  value: todayCourses.length.toString(),
                ),
                MetricCard(
                  icon: Icons.auto_graph_outlined,
                  label: 'Rata-rata nilai',
                  value: store.grades.isEmpty
                      ? '-'
                      : store.weightedAverage.toStringAsFixed(1),
                ),
                MetricCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Kehadiran',
                  value: '${store.attendanceRate.toStringAsFixed(0)}%',
                ),
              ],
            ),
            const SizedBox(height: 28),
            const SectionHeader(title: 'Jadwal hari ini'),
            const SizedBox(height: 12),
            if (todayCourses.isEmpty)
              const Card(
                child: SizedBox(
                  height: 170,
                  child: EmptyState(
                    icon: Icons.free_breakfast_outlined,
                    title: 'Tidak ada pelajaran',
                    message: 'Nikmati waktu belajar mandiri atau istirahat.',
                  ),
                ),
              )
            else
              ...todayCourses.map(
                (Course course) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 5,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Color(course.colorValue),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  course.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${minutesToClock(course.startMinutes)}–${minutesToClock(course.endMinutes)} • ${course.room}',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Tenggat terdekat'),
            const SizedBox(height: 12),
            if (upcoming.isEmpty)
              const Card(
                child: SizedBox(
                  height: 170,
                  child: EmptyState(
                    icon: Icons.task_alt,
                    title: 'Semua terkendali',
                    message: 'Belum ada tugas atau ujian yang mendekati tenggat.',
                  ),
                ),
              )
            else
              ...upcoming.map(
                (SchoolTask task) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        child: Icon(
                          task.type == TaskType.ujian
                              ? Icons.quiz_outlined
                              : Icons.assignment_outlined,
                        ),
                      ),
                      title: Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${store.courseById(task.courseId)?.name ?? 'Umum'} • ${formatDateTime(task.dueAt)}',
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
