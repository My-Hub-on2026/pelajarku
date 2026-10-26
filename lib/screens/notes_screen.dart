import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/course.dart';
import '../models/school_note.dart';
import '../state/app_store.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Catatan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: store.notes.isEmpty
          ? EmptyState(
              icon: Icons.note_alt_outlined,
              title: 'Belum ada catatan',
              message: 'Simpan ringkasan pelajaran, rumus, atau ide tugas.',
              action: FilledButton.icon(
                onPressed: () => _openNoteDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Buat catatan'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              itemCount: store.notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (BuildContext context, int index) {
                final SchoolNote note = store.notes[index];
                final Course? course = store.courseById(note.courseId);
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openNoteDialog(context, note: note),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  note.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (String value) async {
                                  if (value == 'edit') {
                                    await _openNoteDialog(context, note: note);
                                  } else if (value == 'delete') {
                                    await _confirmDelete(context, note);
                                  }
                                },
                                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note.body,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${course?.name ?? 'Umum'} • Diperbarui ${formatShortDate(note.updatedAt)}',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openNoteDialog(
    BuildContext context, {
    SchoolNote? note,
  }) async {
    final AppStore store = AppScope.of(context);
    final TextEditingController title = TextEditingController(text: note?.title);
    final TextEditingController body = TextEditingController(text: note?.body);
    String courseSelection = note?.courseId ?? '__none__';

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(note == null ? 'Buat Catatan' : 'Edit Catatan'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 470,
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
                            child: Text('Umum'),
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
                      TextField(
                        controller: body,
                        minLines: 8,
                        maxLines: 12,
                        decoration: const InputDecoration(
                          labelText: 'Isi catatan',
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

    if (saved != true || title.text.trim().isEmpty || body.text.trim().isEmpty) {
      return;
    }

    await store.saveNote(
      SchoolNote(
        id: note?.id ?? const Uuid().v4(),
        title: title.text.trim(),
        body: body.text.trim(),
        courseId: courseSelection == '__none__' ? null : courseSelection,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SchoolNote note) async {
    final AppStore store = AppScope.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('“${note.title}” akan dihapus.'),
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
    if (confirmed == true) await store.deleteNote(note);
  }
}
