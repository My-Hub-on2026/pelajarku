import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/course.dart';
import '../models/grade_entry.dart';
import '../state/app_store.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';

class GradesScreen extends StatelessWidget {
  const GradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);
    final double kkm = double.tryParse(store.settings['kkm'] ?? '75') ?? 75;

    return Scaffold(
      appBar: AppBar(title: const Text('Nilai')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: store.courses.isEmpty ? null : () => _openGradeDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: store.courses.isEmpty
          ? const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Tambahkan mata pelajaran dahulu',
              message: 'Nilai harus dikaitkan dengan sebuah mata pelajaran.',
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.auto_graph, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('Rata-rata tertimbang'),
                              Text(
                                store.grades.isEmpty
                                    ? '-'
                                    : store.weightedAverage.toStringAsFixed(1),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              Text(
                                'KKM ${kkm.toStringAsFixed(0)} • Semester ${store.settings['semester'] ?? '-'}',
                                style: const TextStyle(color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...store.courses.map((Course course) {
                  final List<GradeEntry> entries = store.grades
                      .where((GradeEntry grade) => grade.courseId == course.id)
                      .toList();
                  final double average = store.averageForCourse(course.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ExpansionTile(
                        shape: const Border(),
                        leading: CircleAvatar(
                          backgroundColor: Color(course.colorValue),
                          child: Text(
                            course.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          course.name,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          entries.isEmpty
                              ? 'Belum ada nilai'
                              : 'Rata-rata ${average.toStringAsFixed(1)} • ${average >= kkm ? 'Tuntas' : 'Perlu ditingkatkan'}',
                        ),
                        children: entries.isEmpty
                            ? const <Widget>[
                                Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text('Belum ada penilaian untuk mata pelajaran ini.'),
                                ),
                              ]
                            : entries
                                .map(
                                  (GradeEntry grade) => ListTile(
                                    title: Text(grade.category),
                                    subtitle: Text(
                                      '${formatShortDate(grade.date)} • Bobot ${grade.weight.toStringAsFixed(0)}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          '${grade.score.toStringAsFixed(0)}/${grade.maxScore.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Hapus nilai',
                                          onPressed: () =>
                                              _confirmDelete(context, grade),
                                          icon: const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  );
                }),
                if (store.grades.isEmpty)
                  const SizedBox(
                    height: 220,
                    child: EmptyState(
                      icon: Icons.grade_outlined,
                      title: 'Belum ada nilai',
                      message: 'Catat nilai tugas, kuis, PTS, PAS, dan praktik.',
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _openGradeDialog(BuildContext context) async {
    final AppStore store = AppScope.of(context);
    String courseId = store.courses.first.id;
    final TextEditingController category =
        TextEditingController(text: 'Tugas Harian');
    final TextEditingController score = TextEditingController();
    final TextEditingController maxScore = TextEditingController(text: '100');
    final TextEditingController weight = TextEditingController(text: '1');
    DateTime date = DateTime.now();

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Nilai'),
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
                      TextField(
                        controller: category,
                        decoration: const InputDecoration(
                          labelText: 'Jenis penilaian',
                          hintText: 'Contoh: Kuis, PTS, PAS, Praktik',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: score,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(labelText: 'Nilai'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: maxScore,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(labelText: 'Nilai maksimum'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Bobot',
                          helperText: 'Contoh: tugas 1, PTS 2, PAS 3',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final DateTime? selected = await showDatePicker(
                            context: context,
                            initialDate: date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (selected != null) {
                            setDialogState(() => date = selected);
                          }
                        },
                        icon: const Icon(Icons.event),
                        label: Text('Tanggal: ${formatShortDate(date)}'),
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

    final double? parsedScore =
        double.tryParse(score.text.replaceAll(',', '.'));
    final double? parsedMax =
        double.tryParse(maxScore.text.replaceAll(',', '.'));
    final double? parsedWeight =
        double.tryParse(weight.text.replaceAll(',', '.'));
    if (saved != true ||
        category.text.trim().isEmpty ||
        parsedScore == null ||
        parsedMax == null ||
        parsedWeight == null ||
        parsedMax <= 0 ||
        parsedWeight <= 0) {
      return;
    }

    await store.saveGrade(
      GradeEntry(
        id: const Uuid().v4(),
        courseId: courseId,
        category: category.text.trim(),
        score: parsedScore,
        maxScore: parsedMax,
        weight: parsedWeight,
        date: date,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, GradeEntry grade) async {
    final AppStore store = AppScope.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Hapus nilai?'),
        content: Text('${grade.category} akan dihapus.'),
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
    if (confirmed == true) await store.deleteGrade(grade);
  }
}
