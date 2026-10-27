import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';

import '../models/school_note.dart';
import '../state/app_store.dart';

/// Teks dikenali di perangkat. Pengguna harus meninjau sebelum menyimpan.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool busy = false;
  String text = '';
  String message = 'Pilih foto, ambil gambar, atau pindai PDF.';
  final controller = TextEditingController();
  final picker = ImagePicker();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _fromImage(ImageSource source) async {
    try {
      final file = await picker.pickImage(source: source, imageQuality: 95);
      if (file == null) return;
      await _run(() async {
        final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        try {
          final result = await recognizer.processImage(
            InputImage.fromFilePath(file.path));
          return result.text;
        } finally {
          await recognizer.close();
        }
      });
    } catch (error) {
      _error(error);
    }
  }

  Future<void> _fromPdf() async {
    try {
      final selected = await FilePicker().pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf'],
      );
      if (selected == null || selected.files.single.path == null) return;
      final path = selected.files.single.path!;
      await _run(() async {
        final document = await PdfDocument.openFile(path);
        final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final parts = <String>[];
        try {
          // Maksimum 10 halaman agar tetap praktis di perangkat sekolah.
          final pages = document.pagesCount > 10 ? 10 : document.pagesCount;
          for (int i = 1; i <= pages; i++) {
            final page = await document.getPage(i);
            try {
              final rendered = await page.render(
                width: page.width * 2,
                height: page.height * 2,
                format: PdfPageImageFormat.png,
              );
              if (rendered == null) continue;
              final temp = await getTemporaryDirectory();
              final image = File('${temp.path}/scan_page_$i.png');
              try {
                await image.writeAsBytes(rendered.bytes, flush: true);
                final scanned = await recognizer.processImage(
                  InputImage.fromFilePath(image.path));
                parts.add('Halaman $i\n${scanned.text}');
              } finally {
                if (await image.exists()) await image.delete();
              }
            } finally {
              await page.close();
            }
          }
        } finally {
          await recognizer.close();
          await document.close();
        }
        return parts.join('\n\n');
      });
    } catch (error) {
      _error(error);
    }
  }

  Future<void> _run(Future<String> Function() scan) async {
    setState(() { busy = true; message = 'Memindai dokumen…'; });
    try {
      final result = await scan();
      if (!mounted) return;
      setState(() {
        text = result;
        controller.text = result;
        message = result.trim().isEmpty
          ? 'Tidak ditemukan teks. Coba gambar yang lebih terang dan jelas.'
          : 'Hasil OCR tersedia. Periksa sebelum menyimpan.';
      });
    } catch (error) {
      _error(error);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _error(Object error) {
    if (!mounted) return;
    setState(() { busy = false; message = 'Gagal memindai: $error'; });
  }

  Future<void> _saveNote() async {
    final body = controller.text.trim();
    if (body.isEmpty) return;
    await AppScope.of(context).saveNote(SchoolNote(
      id: const Uuid().v4(),
      title: 'Hasil pindai ${DateTime.now().day}/${DateTime.now().month}',
      body: body,
      updatedAt: DateTime.now(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil pindai tersimpan sebagai catatan.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pindai Gambar & PDF')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Foto dan PDF dipindai di perangkat. Tinjau hasil sebelum menyimpan. '
          'OCR membaca teks; jadwal, tanggal, dan nilai perlu diverifikasi manual.'),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            onPressed: busy ? null : () => _fromImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Kamera')),
          OutlinedButton.icon(
            onPressed: busy ? null : () => _fromImage(ImageSource.gallery),
            icon: const Icon(Icons.image_outlined),
            label: const Text('Galeri')),
          OutlinedButton.icon(
            onPressed: busy ? null : _fromPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Pilih PDF')),
        ]),
        const SizedBox(height: 12),
        if (busy) const LinearProgressIndicator(),
        Text(message),
        const SizedBox(height: 16),
        TextField(
          controller: controller,
          minLines: 8,
          maxLines: 24,
          decoration: const InputDecoration(
            labelText: 'Hasil teks (bisa diedit)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : _saveNote,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Simpan sebagai catatan'),
        ),
      ],
    ),
  );
}
