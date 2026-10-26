# Panduan Membangun PelajarKu untuk Android dan iOS

Dokumen ini memandu dari komputer kosong sampai aplikasi berjalan. Source code di folder ini merupakan MVP offline-first dan memakai satu basis kode Flutter.

## 1. Software yang diperlukan

### Semua sistem operasi

1. **Git** untuk mengelola source code.
2. **Flutter stable** dan Dart yang ikut di dalam Flutter.
3. **Android Studio** untuk Android SDK, emulator, dan alat build.
4. **Visual Studio Code** atau Android Studio sebagai editor.
5. Ekstensi Flutter dan Dart pada editor.

### Khusus build iOS

Build iOS wajib dilakukan di macOS dengan:

1. Xcode;
2. Xcode Command Line Tools;
3. CocoaPods;
4. Apple ID untuk simulator, serta Apple Developer Program untuk distribusi ke App Store/TestFlight.

Windows atau Linux tetap dapat dipakai untuk menulis kode dan membuat Android, tetapi tidak dapat menghasilkan arsip iOS final tanpa macOS/Xcode.

## 2. Instalasi Flutter

1. Unduh Flutter stable dari situs resmi Flutter.
2. Ekstrak ke folder yang tidak memerlukan akses administrator.
3. Masukkan folder `flutter/bin` ke PATH.
4. Jalankan:

```bash
flutter doctor -v
flutter channel stable
flutter upgrade
```

Perbaiki semua tanda merah pada bagian Android toolchain. Tanda merah pada Xcode dapat diabaikan sementara apabila hanya mengembangkan Android dari Windows/Linux.

## 3. Membuat kerangka platform

Ekstrak ZIP, buka terminal pada folder proyek, lalu jalankan:

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

Pada Windows PowerShell, jalankan perintah setara secara manual:

```powershell
flutter create --platforms=android,ios --org=id.pelajarku --project-name=pelajarku .
flutter pub get
```

Setelah `flutter create`, pastikan folder `lib` dari paket ini tidak tertimpa. Skrip `bootstrap.sh` otomatis mencadangkan dan mengembalikannya.

## 4. Konfigurasi Android

### 4.1 Gradle

Buka `android/app/build.gradle.kts`, lalu selaraskan dengan:

```text
platform_setup/android/app_build.gradle.kts.snippet
```

Periksa juga versi Android Gradle Plugin pada `android/settings.gradle.kts` menggunakan `platform_setup/android/settings.gradle.kts.snippet`. Jangan menghapus plugin Flutter/Kotlin lain yang dihasilkan oleh `flutter create`.

Poin penting:

- AGP minimal 8.11.1 untuk versi plugin notifikasi yang dipakai;
- `compileSdk = 36`;
- `targetSdk = 36`;
- `minSdk = 24`;
- Java 17;
- core library desugaring aktif.

### 4.2 Manifest untuk pengingat

Buka `android/app/src/main/AndroidManifest.xml`. Tambahkan permission dan receiver dari:

```text
platform_setup/android/AndroidManifest.xml.snippet
```

Receiver dibutuhkan agar jadwal pengingat didaftarkan kembali setelah perangkat dinyalakan ulang atau aplikasi diperbarui.

### 4.3 Nama aplikasi

Pada `android/app/src/main/AndroidManifest.xml`, ubah label:

```xml
<application
    android:label="PelajarKu"
    ...>
```

### 4.4 Menjalankan Android

Buat emulator di Android Studio atau sambungkan ponsel dengan USB debugging, lalu:

```bash
flutter devices
flutter run
```

## 5. Konfigurasi iOS

1. Buka `ios/Podfile` dan gunakan minimum iOS 13 sebagaimana contoh `platform_setup/ios/Podfile.snippet`.
2. Selaraskan `ios/Runner/AppDelegate.swift` dengan `platform_setup/ios/AppDelegate.swift.snippet` agar notifikasi dapat ditangani saat aplikasi aktif.
3. Jalankan:

```bash
cd ios
pod install
cd ..
```

4. Buka `ios/Runner.xcworkspace` di Xcode.
5. Pada **Signing & Capabilities**, pilih Team dan ubah Bundle Identifier agar unik, misalnya `id.pelajarku.app`.
6. Atur Display Name menjadi **PelajarKu**.
7. Jalankan simulator:

```bash
open -a Simulator
flutter run
```

Aplikasi meminta izin notifikasi dari halaman Pengaturan agar permintaan tidak muncul tanpa konteks.

## 6. Memeriksa kualitas kode

Jalankan setiap kali melakukan perubahan:

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
```

Sebelum rilis, uji setidaknya pada:

- satu Android versi minimum;
- satu Android versi terbaru;
- satu iPhone layar kecil;
- satu iPhone layar besar;
- zona waktu WIB, WITA, dan WIT;
- kondisi tanpa internet;
- perangkat direstart setelah memasang pengingat.

## 7. Struktur source code

```text
lib/
  main.dart                     titik masuk aplikasi
  data/app_database.dart        database SQLite dan CRUD
  models/                       model data
  services/notification_service.dart
  state/app_store.dart          state aplikasi tanpa paket tambahan
  screens/                      seluruh halaman
  theme/                        tema Material 3
  utils/                        formatter tanggal dan jam
  widgets/                      widget yang dipakai berulang
```

Arsitektur ini sengaja sederhana untuk MVP. Untuk tim besar, pisahkan per fitur dan tambahkan repository, use case, serta dependency injection.

## 8. Tabel database lokal

| Tabel | Fungsi | Kolom penting |
|---|---|---|
| `courses` | jadwal pelajaran | nama, guru, ruangan, hari, jam |
| `tasks` | tugas, ujian, kegiatan | tenggat, pengingat, prioritas, selesai |
| `grades` | nilai | skor, maksimum, kategori, bobot |
| `attendance` | kehadiran | tanggal, status, catatan |
| `notes` | catatan sekolah | judul, isi, mapel |
| `settings` | profil dan preferensi | kelas, semester, KKM, zona waktu |

SQLite dipilih agar fungsi inti tetap berjalan tanpa internet. Pengaturan yang penting juga disimpan di SQLite, bukan hanya preferensi sederhana.

## 9. Alur fitur utama

### Menambahkan jadwal

1. Masuk ke tab **Jadwal**.
2. Pilih hari.
3. Tekan tombol tambah.
4. Isi mapel, guru, ruangan, waktu, dan warna.
5. Data disimpan ke tabel `courses`.

### Menambahkan tugas atau ujian

1. Masuk ke tab **Tugas**.
2. Isi judul, mapel, jenis, prioritas, tenggat, dan catatan.
3. Aktifkan pengingat dan pilih waktu sebelum tenggat.
4. Data masuk ke SQLite.
5. `NotificationService` menjadwalkan notifikasi lokal.

### Menghitung nilai

Setiap nilai dinormalisasi menjadi persen:

```text
persentase = skor / nilai_maksimum × 100
```

Rata-rata keseluruhan memakai bobot:

```text
rata-rata = jumlah(persentase × bobot) / jumlah(bobot)
```

KKM dapat diubah dari Pengaturan.

## 10. Build Android

### APK untuk uji langsung

```bash
flutter build apk --release
```

Hasil umumnya berada di:

```text
build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle untuk Google Play

1. Buat upload keystore dan simpan dengan aman.
2. Tambahkan konfigurasi signing sesuai panduan Flutter/Google Play.
3. Jalankan:

```bash
flutter build appbundle --release
```

Jangan memasukkan password keystore ke Git.

## 11. Build iOS

Pada Mac:

```bash
flutter build ipa --release
```

Pastikan signing, bundle ID, privacy manifest, ikon, dan versi sudah benar. Unggah melalui Xcode Organizer atau Transporter, lalu uji dengan TestFlight.

## 12. Menjadikan aplikasi produksi

MVP ini sudah cocok untuk validasi fungsi dan UI. Sebelum dipublikasikan, tambahkan:

1. onboarding dan empty state per jenjang;
2. backup/restore;
3. login serta sinkronisasi cloud bila diperlukan;
4. penghapusan akun dan ekspor data;
5. kebijakan privasi untuk pengguna anak;
6. pengujian aksesibilitas;
7. crash reporting;
8. audit keamanan;
9. ikon dan aset orisinal;
10. proses internal testing Play Console dan TestFlight.

Panduan Firebase terdapat di `docs/FIREBASE_PRODUKSI.md`.

## 13. Batasan MVP

- Belum ada login atau sinkronisasi antarperangkat.
- Belum ada akun orang tua/guru.
- Belum ada kalender bulanan dan widget home screen.
- Jadwal saat ini Senin–Sabtu dan belum mendukung rotasi minggu A/B.
- Pengingat lokal bergantung pada kebijakan baterai setiap produsen Android.
- iOS membatasi jumlah notifikasi tertunda, sehingga aplikasi produksi perlu menjadwalkan ulang daftar terdekat secara berkala.

## 14. Identitas dan hak cipta

PelajarKu dibuat sebagai implementasi orisinal atas kategori aplikasi agenda sekolah. Jangan menyalin nama, logo, ilustrasi, susunan layar khas, teks pemasaran, aset, atau source code School Planner. Pertahankan merek, desain, ikon, dan bahasa yang orisinal serta sesuai pengguna Indonesia.
