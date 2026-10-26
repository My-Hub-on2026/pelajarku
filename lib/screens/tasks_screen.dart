import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/course.dart';
import '../models/school_task.dart';
import '../state/app_store.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String filter = 'aktif';

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    final List<SchoolTask> visible = store.tasks.where((SchoolTask task) {
      return switch (filter) {
        'aktif' => !task.isDone,
        'ujian' => !task.isDone && task.type == TaskType.ujian,
        'selesai' => task.isDone,
        _ => true,
      };
    }).toList()
      ..sort((SchoolTask a, SchoolTask b) => a.dueAt.compareTo(b.dueAt));

    return Scaffold(
      appBar: AppBar(title: const Text('Tugas & Ujian')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                _filterChip('aktif', 'Aktif'),
                const SizedBox(width: 8),
                _filterChip('ujian', 'Ujian'),
                const SizedBox(width: 8),
                _filterChip('selesai', 'Selesai'),
                const SizedBox(width: 8),
                _filterChip('semua', 'Semua'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Tidak ada item',
                    message: 'Tambahkan tugas, ujian, proyek, atau kegiatan sekolah.',
                    action: FilledButton.icon(
                      onPressed: () => _openTaskDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah tugas'),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (BuildContext context, int index) {
                      final SchoolTask task = visible[index];
                      final Course? course = store.courseById(task.courseId);
                      final Color accent = switch (task.priority) {
                        TaskPriority.rendah => const Color(0xFF16A34A),
                        TaskPriority.sedang => const Color(0xFFEA580C),
                        TaskPriority.tinggi => const Color(0xFFDC2626),
                      };
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            onTap: () => _openTaskDialog(context, task: task),
                            leading: Checkbox(
                              value: task.isDone,
                              onChanged: (_) => store.toggleTask(task),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                '${course?.name ?? 'Umum'} • ${formatDateTime(task.dueAt)}\n${titleCase(task.type.name)} • Prioritas ${titleCase(task.priority.name)}',
                              ),
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: accent),
                              onSelected: (String value) async {
                                if (value == 'edit') {
                                  await _openTaskDialog(context, task: task);
                                } else if (value == 'delete') {
                                  await _confirmDelete(context, task);
                                }
                              },
                              itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Hapus')),
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

  Widget _filterChip(String value, String label) {
    return ChoiceChip(
      selected: filter == value,
      label: Text(label),
      onSelected: (_) => setState(() => filter = value),
    );
  }

  Future<void> _openTaskDialog(
    BuildContext context, {
    SchoolTask? task,
  }) async {
    final AppStore store = AppScope.of(context);
    final TextEditingController title = TextEditingController(text: task?.title);
    final TextEditingController notes = TextEditingController(text: task?.notes);
    String courseSelection = task?.courseId ?? '__none__';
    TaskType type = task?.type ?? TaskType.tugas;
    TaskPriority priority = task?.priority ?? TaskPriority.sedang;
    DateTime dueAt = task?.dueAt ?? DateTime.now().add(const Duration(days: 1));
    DateTime? reminderAt = task?.reminderAt ??
        dueAt.subtract(const Duration(hours: 6));
    bool useReminder = task?.reminderAt != null || task == null;

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(task == null ? 'Tambah Tugas/Ujian' : 'Edit Tugas/Ujian'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(labelText: 'Judul'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: courseSelection,
                        decoration: const InputDecoration(labelText: 'Mata pelajaran'),
                        items: <DropdownMenuItem<String>>[
                          const DropdownMenuItem<String>(
                            value: '__none__',
                            child: Text('Umum / tanpa mata pelajaran'),
                          ),
                          ...store.courses.map(
                            (Course course) => DropdownMenuItem<String>(
                              value: course.id,
                              child: Text(course.name),
                            ),
                          ),
                        ],
                        onChanged: (String? value) {
                          if (value != null) {
                            setDialogState(() => courseSelection = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: DropdownButtonFormField<TaskType>(
                              initialValue: type,
                              decoration: const InputDecoration(labelText: 'Jenis'),
                              items: TaskType.values
                                  .map(
                                    (TaskType value) => DropdownMenuItem<TaskType>(
                                      value: value,
                                      child: Text(titleCase(value.name)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (TaskType? value) {
                                if (value != null) {
                                  setDialogState(() => type = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<TaskPriority>(
                              initialValue: priority,
                              decoration: const InputDecoration(labelText: 'Prioritas'),
                              items: TaskPriority.values
                                  .map(
                                    (TaskPriority value) =>
                                        DropdownMenuItem<TaskPriority>(
                                      value: value,
                                      child: Text(titleCase(value.name)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (TaskPriority? value) {
                                if (value != null) {
                                  setDialogState(() => priority = value);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final DateTime? date = await showDatePicker(
                            context: context,
                            initialDate: dueAt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date == null || !context.mounted) return;
                          final TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(dueAt),
                          );
                          if (time == null) return;
                          setDialogState(() {
                            dueAt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            if (useReminder &&
                                (reminderAt == null || !reminderAt!.isBefore(dueAt))) {
                              reminderAt = dueAt.subtract(const Duration(hours: 6));
                            }
                          });
                        },
                        icon: const Icon(Icons.event),
                        label: Text('Tenggat: ${formatDateTime(dueAt)}'),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: useReminder,
                        title: const Text('Gunakan pengingat'),
                        onChanged: (bool value) {
                          setDialogState(() {
                            useReminder = value;
                            reminderAt ??= dueAt.subtract(const Duration(hours: 6));
                          });
                        },
                      ),
                      if (useReminder)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final DateTime initial = reminderAt ??
                                dueAt.subtract(const Duration(hours: 6));
                            final DateTime? date = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime(2020),
                              lastDate: dueAt,
                            );
                            if (date == null || !context.mounted) return;
                            final TimeOfDay? time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(initial),
                            );
                            if (time == null) return;
                            setDialogState(() {
                              reminderAt = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          },
                          icon: const Icon(Icons.notifications_active_outlined),
                          label: Text(
                            'Pengingat: ${formatDateTime(reminderAt ?? dueAt)}',
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notes,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Catatan tambahan',
                          alignLabelWithHint: true,
                        ),
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

    if (saved != true || title.text.trim().isEmpty) return;
    if (useReminder && reminderAt != null && !reminderAt!.isBefore(dueAt)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengingat harus sebelum waktu tenggat.')),
        );
      }
      return;
    }

    await store.saveTask(
      SchoolTask(
        id: task?.id ?? const Uuid().v4(),
        title: title.text.trim(),
        courseId: courseSelection == '__none__' ? null : courseSelection,
        type: type,
        dueAt: dueAt,
        reminderAt: useReminder ? reminderAt : null,
        priority: priority,
        notes: notes.text.trim(),
        isDone: task?.isDone ?? false,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SchoolTask task) async {
    final AppStore store = AppScope.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Hapus item?'),
        content: Text('“${task.title}” akan dihapus beserta pengingatnya.'),
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
    if (confirmed == true) await store.deleteTask(task);
  }
}
