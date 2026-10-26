# Mulai PelajarKu — Panduan Pemula

Target pertama: tampilkan PelajarKu pada Android Emulator. Jangan mengatur Firebase, akun orang tua, atau Play Store sebelum target ini berhasil.

## Windows

1. Instal Git, Flutter stable, Android Studio, dan VS Code.
2. Tambahkan folder `flutter\bin` ke PATH.
3. Buka PowerShell baru dan jalankan:

```powershell
flutter doctor -v
flutter doctor --android-licenses
```

4. Buka Android Studio > SDK Manager dan pastikan Android SDK, Platform Tools, Command-line Tools, dan Emulator terpasang.
5. Buka Device Manager dan buat satu emulator Android.
6. Ekstrak ZIP ke folder sederhana, misalnya `C:\Proyek\pelajarku_mvp`.
7. Klik kanan `bootstrap_windows.ps1`, pilih **Run with PowerShell**, atau jalankan:

```powershell
cd C:\Proyek\pelajarku_mvp
Set-ExecutionPolicy -Scope Process Bypass
.\bootstrap_windows.ps1
```

8. Terapkan konfigurasi Android di folder `platform_setup/android` sesuai `docs/PANDUAN_MEMBANGUN.md` bagian 4.
9. Jalankan emulator, lalu:

```powershell
flutter devices
flutter analyze
flutter test
flutter run
```

## macOS atau Linux

```bash
cd pelajarku_mvp
chmod +x bootstrap.sh
./bootstrap.sh
flutter analyze
flutter test
flutter run
```

Untuk build iOS, gunakan macOS, Xcode, dan CocoaPods. Selesaikan Android terlebih dahulu.
