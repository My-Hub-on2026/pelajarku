import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/course.dart';
import '../state/app_store.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  int selectedDay = DateTime.now().weekday.clamp(1, 6).toInt();

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    final List<Course> courses = store.coursesForDay(selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Pelajaran'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCourseDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 54,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemBuilder: (BuildContext context, int index) {
                final int day = index + 1;
                return ChoiceChip(
                  selected: selectedDay == day,
                  label: Text(dayNames[day]),
                  onSelected: (_) => setState(() => selectedDay = day),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: 6,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: courses.isEmpty
                ? EmptyState(
                    icon: Icons.calendar_view_week_outlined,
                    title: 'Belum ada jadwal ${dayNames[selectedDay]}',
                    message: 'Tambahkan mata pelajaran, jam, guru, dan ruangan.',
                    action: FilledButton.icon(
                      onPressed: () => _openCourseDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah pelajaran'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final Course course = courses[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openCourseDialog(context, course: course),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  width: 6,
                                  height: 74,
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
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${minutesToClock(course.startMinutes)}–${minutesToClock(course.endMinutes)}',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${course.teacher}${course.room.isEmpty ? '' : ' • ${course.room}'}',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (String value) async {
                                    if (value == 'edit') {
                                      await _openCourseDialog(
                                        context,
                                        course: course,
                                      );
                                    } else if (value == 'delete') {
                                      await _confirmDelete(context, course);
                                    }
                                  },
                                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Hapus'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCourseDialog(
    BuildContext context, {
    Course? course,
  }) async {
    final AppStore store = AppScope.of(context);
    final TextEditingController name = TextEditingController(text: course?.name);
    final TextEditingController teacher =
        TextEditingController(text: course?.teacher);
    final TextEditingController room = TextEditingController(text: course?.room);
    int day = course?.dayOfWeek ?? selectedDay;
    TimeOfDay start = course == null
        ? const TimeOfDay(hour: 7, minute: 0)
        : TimeOfDay(
            hour: course.startMinutes ~/ 60,
            minute: course.startMinutes % 60,
          );
    TimeOfDay end = course == null
        ? const TimeOfDay(hour: 8, minute: 30)
        : TimeOfDay(
            hour: course.endMinutes ~/ 60,
            minute: course.endMinutes % 60,
          );
    int colorValue = course?.colorValue ?? 0xFF2563EB;
    final List<int> colors = <int>[
      0xFF2563EB,
      0xFF16A34A,
      0xFFEA580C,
      0xFF7C3AED,
      0xFFDB2777,
      0xFF0891B2,
    ];

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(course == null ? 'Tambah Pelajaran' : 'Edit Pelajaran'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Nama mata pelajaran',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: teacher,
                        decoration: const InputDecoration(labelText: 'Guru'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: room,
                        decoration: const InputDecoration(labelText: 'Ruangan'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: day,
                        decoration: const InputDecoration(labelText: 'Hari'),
                        items: <DropdownMenuItem<int>>[
                          for (int value = 1; value <= 6; value++)
                            DropdownMenuItem<int>(
                              value: value,
                              child: Text(dayNames[value]),
                            ),
                        ],
                        onChanged: (int? value) {
                          if (value != null) setDialogState(() => day = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final TimeOfDay? value = await showTimePicker(
                                  context: context,
                                  initialTime: start,
                                );
                                if (value != null) {
                                  setDialogState(() => start = value);
                                }
                              },
                              icon: const Icon(Icons.schedule),
                              label: Text('Mulai ${start.format(context)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final TimeOfDay? value = await showTimePicker(
                                  context: context,
                                  initialTime: end,
                                );
                                if (value != null) {
                                  setDialogState(() => end = value);
                                }
                              },
                              icon: const Icon(Icons.schedule),
                              label: Text('Selesai ${end.format(context)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Warna',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: colors
                            .map(
                              (int value) => GestureDetector(
                                onTap: () =>
                                    setDialogState(() => colorValue = value),
                                child: CircleAvatar(
                                  radius: 17,
                                  backgroundColor: Color(value),
                                  child: colorValue == value
                                      ? const Icon(
                                          Icons.check,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || name.text.trim().isEmpty) return;
    final int startMinutes = timeOfDayToMinutes(start.hour, start.minute);
    final int endMinutes = timeOfDayToMinutes(end.hour, end.minute);
    if (endMinutes <= startMinutes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jam selesai harus setelah jam mulai.')),
        );
      }
      return;
    }

    await store.saveCourse(
      Course(
        id: course?.id ?? const Uuid().v4(),
        name: name.text.trim(),
        teacher: teacher.text.trim(),
        room: room.text.trim(),
        colorValue: colorValue,
        dayOfWeek: day,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      ),
    );
    if (mounted) setState(() => selectedDay = day);
  }

  Future<void> _confirmDelete(BuildContext context, Course course) async {
    final AppStore store = AppScope.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Hapus pelajaran?'),
        content: Text(
          'Nilai dan kehadiran untuk ${course.name} juga akan dihapus. Tugas tetap tersimpan sebagai tugas umum.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) await store.deleteCourse(course);
  }
}
