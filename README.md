# PelajarKu

PelajarKu adalah MVP aplikasi agenda sekolah Indonesia untuk Android dan iOS, dibuat dengan Flutter dan SQLite. Aplikasi dirancang offline-first agar siswa dapat mengelola sekolah tanpa wajib membuat akun.

## Fitur yang sudah dikodekan

- Dashboard harian.
- Jadwal pelajaran Senin–Sabtu.
- Tugas, ujian, kegiatan, prioritas, tenggat, dan checklist selesai.
- Pengingat lokal Android/iOS.
- Nilai, bobot, rata-rata, dan KKM.
- Kehadiran: hadir, izin, sakit, alpa.
- Catatan per mata pelajaran atau catatan umum.
- Profil siswa, sekolah, kelas, semester, KKM, zona waktu.
- Data contoh untuk memudahkan demo.

## Mulai cepat

```bash
chmod +x bootstrap.sh
./bootstrap.sh
flutter analyze
flutter test
flutter run
```

Baca petunjuk lengkap:

- `docs/PANDUAN_MEMBANGUN.md`
- `docs/PRD_PELAJARKU.md`
- `docs/FIREBASE_PRODUKSI.md`
- `docs/ROADMAP.md`

## Teknologi

- Flutter/Dart
- Material 3
- SQLite melalui `sqflite`
- `flutter_local_notifications`
- `timezone`
- `intl`

## Catatan penting

Folder Android dan iOS dibuat melalui `bootstrap.sh` agar paket source tetap kecil. Flutter SDK tidak tersedia pada lingkungan tempat paket ini disusun, sehingga jalankan `flutter analyze`, `flutter test`, dan build pada komputer pengembangan setelah ekstraksi.

Proyek ini bukan salinan source code atau aset School Planner. Ini adalah implementasi orisinal dengan fitur generik perencana sekolah dan terminologi Indonesia.
