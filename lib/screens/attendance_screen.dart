import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance_entry.dart';
import '../models/course.dart';
import '../state/app_store.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kehadiran')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            store.courses.isEmpty ? null : () => _openAttendanceDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
      body: store.courses.isEmpty
          ? const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Tambahkan mata pelajaran dahulu',
              message: 'Kehadiran dicatat per mata pelajaran.',
            )
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.fact_check_outlined, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text('Persentase hadir'),
                                Text(
                                  '${store.attendanceRate.toStringAsFixed(1)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  '${store.attendance.length} catatan kehadiran',
                                  style: const TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: store.attendance.isEmpty
                      ? EmptyState(
                          icon: Icons.how_to_reg_outlined,
                          title: 'Belum ada catatan kehadiran',
                          message: 'Catat hadir, izin, sakit, atau alpa.',
                          action: FilledButton.icon(
                            onPressed: () => _openAttendanceDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Catat kehadiran'),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                          itemCount: store.attendance.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            final AttendanceEntry entry = store.attendance[index];
                            final Course? course = store.courseById(entry.courseId);
                            final IconData icon = switch (entry.status) {
                              AttendanceStatus.hadir => Icons.check_circle_outline,
                              AttendanceStatus.izin => Icons.assignment_ind_outlined,
                              AttendanceStatus.sakit => Icons.medical_services_outlined,
                              AttendanceStatus.alpa => Icons.cancel_outlined,
                            };
                            return Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(child: Icon(icon)),
                                title: Text(
                                  course?.name ?? 'Mata pelajaran',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                subtitle: Text(
                                  '${formatShortDate(entry.date)} • ${titleCase(entry.status.name)}${entry.note.isEmpty ? '' : '\n${entry.note}'}',
                                ),
                                isThreeLine: entry.note.isNotEmpty,
                                trailing: IconButton(
                                  tooltip: 'Hapus',
                                  onPressed: () => _confirmDelete(context, entry),
                                  icon: const Icon(Icons.delete_outline),
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

  Future<void> _openAttendanceDialog(BuildContext context) async {
    final AppStore store = AppScope.of(context);
    String courseId = store.courses.first.id;
    AttendanceStatus status = AttendanceStatus.hadir;
    DateTime date = DateTime.now();
    final TextEditingController note = TextEditingController();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Catat Kehadiran'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 430,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DropdownButtonFormField<String>(
                        initialValue: courseId,
                        decoration: const InputDecoration(labelText: 'Mata pelajaran'),
                        items: store.courses
                            .map(
                              (Course course) => DropdownMenuItem<String>(
                                value: course.id,
                                child: Text(course.name),
                              ),
                            )
                            .toList(),
                        onChanged: (String? value) {
                          if (value != null) {
                            setDialogState(() => courseId = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AttendanceStatus>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: AttendanceStatus.values
                            .map(
                              (AttendanceStatus value) =>
                                  DropdownMenuItem<AttendanceStatus>(
                                value: value,
                                child: Text(titleCase(value.name)),
                              ),
                            )
                            .toList(),
                        onChanged: (AttendanceStatus? value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final DateTime? selected = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (selected != null) {
                            setDialogState(() => date = selected);
                          }
                        },
                        icon: const Icon(Icons.event),
                        label: Text('Tanggal: ${formatShortDate(date)}'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: note,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Catatan',
                          hintText: 'Contoh: surat izin sudah diserahkan',
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

    if (saved != true) return;
    await store.saveAttendance(
      AttendanceEntry(
        id: const Uuid().v4(),
        courseId: courseId,
        date: date,
        status: status,
        note: note.text.trim(),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AttendanceEntry entry,
  ) async {
    final AppStore store = AppScope.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Catatan kehadiran ini akan dihapus.'),
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
    if (confirmed == true) await store.deleteAttendance(entry);
  }
}
