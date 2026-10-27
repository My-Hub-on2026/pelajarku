import 'package:flutter/material.dart';

import 'attendance_screen.dart';
import 'notes_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _MenuCard(
            icon: Icons.fact_check_outlined,
            title: 'Kehadiran',
            subtitle: 'Catat hadir, izin, sakit, dan alpa.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AttendanceScreen(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _MenuCard(
            icon: Icons.note_alt_outlined,
            title: 'Catatan',
            subtitle: 'Simpan ringkasan dan materi pelajaran.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const NotesScreen()),
            ),
          ),
          const SizedBox(height: 10),
          _MenuCard(
            icon: Icons.document_scanner_outlined,
            title: 'Pindai gambar & PDF',
            subtitle: 'Ambil foto atau PDF, ubah menjadi teks dan simpan catatan.',
            onTap: () => Navigator.push(context,
              MaterialPageRoute<void>(builder: (_) => const ScanScreen())),
          ),
          const SizedBox(height: 10),
          _MenuCard(
            icon: Icons.manage_accounts_outlined,
            title: 'Profil & Pengaturan',
            subtitle: 'Nama siswa, sekolah, kelas, semester, KKM, dan notifikasi.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Rencana versi berikutnya',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('• Akun siswa dan sinkronisasi cloud'),
                  Text('• Akses orang tua melalui kode undangan'),
                  Text('• Kalender libur nasional dan kalender sekolah'),
                  Text('• Lampiran foto/PDF untuk tugas dan catatan'),
                  Text('• Widget jadwal di layar utama'),
                  Text('• Impor jadwal dari Excel atau foto'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
