# Membuat APK PelajarKu tanpa memasang Flutter/Android Studio

Paket ini sudah memiliki GitHub Actions yang akan membuat APK Android secara otomatis di server GitHub.

## Yang dibutuhkan

- Akun GitHub.
- Browser.
- File ZIP proyek PelajarKu ini.

Anda **tidak perlu** memasang Flutter atau Android Studio untuk metode ini.

## Langkah 1 — Buat repository GitHub

1. Masuk ke GitHub.
2. Klik **New repository**.
3. Nama repository: `pelajarku`.
4. Pilih **Private** jika aplikasi masih untuk pengujian pribadi.
5. Jangan tambahkan README, .gitignore, atau license dari GitHub karena proyek ini sudah mempunyai file sendiri.
6. Klik **Create repository**.

## Langkah 2 — Upload isi proyek

Upload **isi folder `pelajarku_mvp`**, bukan file ZIP-nya sebagai satu file.

Pastikan di root repository terlihat antara lain:

- `.github/workflows/build-android-apk.yml`
- `lib/`
- `test/`
- `tool/`
- `pubspec.yaml`
- `analysis_options.yaml`

Jika folder `.github` tidak terlihat pada File Explorer Windows, aktifkan **View > Show > Hidden items** atau upload dengan Git/GitHub Desktop.

## Langkah 3 — Jalankan build APK

1. Buka repository `pelajarku`.
2. Klik tab **Actions**.
3. Pilih workflow **Build PelajarKu Android APK**.
4. Klik **Run workflow**.
5. Pilih branch `main`.
6. Klik tombol **Run workflow**.

Workflow akan otomatis:

1. menyiapkan Java 17;
2. menyiapkan Flutter 3.47.8;
3. membuat file platform Android;
4. memasang dependency;
5. menjalankan analisis kode;
6. menjalankan test;
7. membangun APK release;
8. mengunggah APK sebagai artifact.

## Langkah 4 — Unduh APK

Jika build berwarna hijau:

1. Buka hasil workflow yang selesai.
2. Gulir ke bagian **Artifacts**.
3. Klik **PelajarKu-Android-APK**.
4. GitHub akan mengunduh ZIP artifact.
5. Ekstrak ZIP tersebut.
6. Di dalamnya terdapat:

`PelajarKu-0.1.0.apk`

Itulah file yang dapat dipindahkan ke smartphone Android dan diinstal.

## Langkah 5 — Instal di smartphone Android

1. Pindahkan `PelajarKu-0.1.0.apk` ke smartphone.
2. Buka file APK.
3. Jika Android meminta izin, aktifkan **Install unknown apps** hanya untuk aplikasi yang dipakai membuka APK (misalnya Files/Chrome).
4. Pilih **Install**.
5. Setelah instalasi selesai, buka **PelajarKu**.

Setelah selesai, Anda dapat menonaktifkan kembali izin **Install unknown apps**.

## Catatan penandatanganan

APK dari workflow ini ditujukan untuk pengujian/install langsung. Untuk publikasi resmi di Google Play, buat keystore rilis milik Anda sendiri dan simpan sebagai GitHub Actions Secret. Jangan pernah memasukkan password atau file keystore ke repository publik.

## Jika build gagal

Buka workflow yang merah, klik tahap yang gagal, lalu salin log error-nya ke ChatGPT. Error tersebut dapat digunakan untuk memperbaiki source atau konfigurasi build secara spesifik.
