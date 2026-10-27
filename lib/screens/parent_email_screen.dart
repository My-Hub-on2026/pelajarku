import 'package:flutter/material.dart';

import '../services/parent_email_service.dart';

class ParentEmailScreen extends StatefulWidget {
  const ParentEmailScreen({super.key});
  @override
  State<ParentEmailScreen> createState() => _ParentEmailScreenState();
}

class _ParentEmailScreenState extends State<ParentEmailScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  bool busy = false;
  String status = '';
  @override
  void dispose() { email.dispose(); code.dispose(); super.dispose(); }

  Future<void> execute(Future<void> Function() action, String success) async {
    setState(() { busy = true; status = ''; });
    try {
      await action();
      if (mounted) setState(() => status = success);
    } catch (error) {
      if (mounted) setState(() => status = 'Gagal: $error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ParentEmailService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Email Orang Tua')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(service.ready
          ? 'Verifikasi email orang tua sebelum otomatis menerima ringkasan setiap perubahan.'
          : 'Belum aktif. ${service.status}. Pengembang harus menyiapkan Firebase, App Check, Cloud Functions dan domain email terlebih dahulu.'),
        const SizedBox(height: 16),
        TextField(controller: email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email orang tua',
            hintText: 'orangtua@contoh.com')),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: (!service.ready || busy) ? null : () =>
            execute(() => service.requestVerification(email.text),
              'Kode verifikasi telah dikirim. Periksa kotak masuk orang tua.'),
          child: const Text('Kirim kode verifikasi')),
        const SizedBox(height: 16),
        TextField(controller: code, keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Kode verifikasi 6 digit')),
        FilledButton.tonal(
          onPressed: (!service.ready || busy) ? null : () =>
            execute(() => service.confirmVerification(code.text),
              'Email orang tua terverifikasi. Perubahan berikutnya dapat dikirim via email.'),
          child: const Text('Verifikasi')),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: (!service.ready || busy) ? null : () =>
            execute(() => service.disconnect(), 'Email orang tua diputuskan.'),
          child: const Text('Hentikan pemberitahuan email')),
        const SizedBox(height: 16),
        Text(status),
        const Text('Catatan: pada tahap ini notifikasi offline belum memiliki antrean ulang. '
          'Jangan gunakan untuk pemantauan darurat atau penilaian resmi.'),
      ]),
    );
  }
}
