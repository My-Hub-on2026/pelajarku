# Mengaktifkan email orang tua PelajarKu

**Status kode:** layar Email Orang Tua, event dari perubahan pada AppStore, backend Cloud Functions, OTP 6 digit, batas dasar penggunaan, dan opsi build Firebase di CI sudah dibuat. **Pengiriman belum aktif** sampai Anda mengonfigurasi Firebase + domain email sendiri. APK tanpa rahasia Firebase tetap bisa dipakai offline.

## 1. Siapkan Firebase
1. Buka https://console.firebase.google.com dan buat proyek baru misalnya `pelajarku-indonesia`.
2. Tambah Android app dengan Application ID `id.pelajarku.pelajarku`, daftarkan SHA-256 signing certificate yang dipakai ketika APK dijalankan (rilis Play Store memiliki certificate berbeda dari APK debug/sideload).
3. Aktifkan Authentication → Sign-in method → Anonymous.
4. Aktifkan Firestore (mode produksi), siapkan aturan yang **menolak akses database langsung dari aplikasi**, sebab seluruh dokumen `parentMailLinks`, `parentMailEvents`, dan `parentMailQuotas` hanya boleh diakses Admin SDK Cloud Functions.
5. Di Security → App Check, daftarkan Android app. Untuk pengujian sideload gunakan provider debug beserta token yang didaftarkan di konsol. Untuk distribusi resmi gunakan Play Integrity dengan signing certificate terdaftar.
6. Unduh `google-services.json` dari Firebase Android app. JSON ini berisi konfigurasi aplikasi (bukan password SMTP).

## 2. Aktifkan provider email
1. Daftar ke provider pengiriman email seperti Resend.
2. Verifikasi domain email pengirim milik Anda dan sesuaikan DNS SPF/DKIM.
3. Edit `backend/functions/index.js`, ubah `notifikasi@YOUR_VERIFIED_DOMAIN` ke email pengirim pada domain terverifikasi.
4. **Jangan** mengunggah API key email ke GitHub dan jangan meletakkannya di aplikasi Flutter.

## 3. Deploy Cloud Functions
Di komputer pengembang setelah instalasi Node.js dan Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
firebase use --add
cd backend/functions
npm install
cd ../..
firebase functions:secrets:set RESEND_API_KEY
firebase functions:secrets:set OTP_HMAC_SECRET
firebase deploy --only functions --config backend/firebase.json --project ID_FIREBASE_ANDA
```
Gunakan string acak kuat sebagai `OTP_HMAC_SECRET`, jangan reuse password email. Cloud Functions dan Firestore umumnya memerlukan konfigurasi billing. Sebelum produksi lakukan audit keamanan dan pengetesan E2E. Backend berada di region `asia-southeast2` sesuai aplikasi.

## 4. Build APK dari GitHub
Repo GitHub → Settings → Secrets and variables → Actions → New repository secret:
- Nama: `FIREBASE_ANDROID_JSON_B64`.
- Isi: hasil Base64 **satu baris** dari file `google-services.json` asli, tanpa baris baru.

Linux/macOS:
```bash
base64 < google-services.json | tr -d '\\n'
```
PowerShell:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\\lokasi\\google-services.json"))
```
Workflow mendeteksi secret tersebut dan menyisipkan konfigurasi Firebase serta plugin Google Services saat build; tanpa secret, fitur email tetap nonaktif.

Untuk tes sideload, developer harus menggunakan App Check debug provider dan mendaftarkan debug token. Build rilis umum memakai Play Integrity. Jangan mengaktifkan mode debug pada APK publik. Tombol Email Orang Tua tidak akan menyala sebelum Firebase & autentikasi siap.

## 5. Uji lengkap
1. Masuk halaman Lainnya → Email Orang Tua.
2. Masukkan email wali, tekan Kirim Kode Verifikasi.
3. Periksa inbox wali, masukkan OTP sebelum 10 menit dan tekan Verifikasi.
4. Tambahkan/ubah/hapus tugas; periksa email wali, juga periksa Firestore `parentMailEvents`.
5. Coba salah kode, kode kedaluwarsa, email lain, rate limit, dan berhenti berlangganan.
6. Uji perubahan profil, nilai, catatan, dan kehadiran. Saat offline, email **belum dijamin terkirim** sebab SQLite outbox belum diselesaikan.

## Batasan prototipe yang WAJIB diketahui
- Aplikasi saat ini memakai login Firebase **anonymous** sehingga orang tua perlu menyetujui alamat penerima melalui OTP. Belum ada perpindahan akun siswa lintas perangkat.
- Kiriman email saat offline belum diantrikan dengan aman. Untuk "setiap perubahan tanpa kehilangan event" perlu outbox persisten + retry idempotent, dan monitoring server.
- Backend melindungi data melalui auth/App Check/OTP, namun perlindungan terhadap spam massal, pembatasan per IP, legal consent wali, data retention, dan proses penghapusan data perlu diselesaikan sebelum diluncurkan kepada siswa umum.
- Dengan repositori PUBLIC, gunakan GitHub Secrets, Firebase Secrets, dan jangan pernah commit service account credentials.
- Status layar email adalah status koneksi lokal, bukan jaminan email sudah diterima penerima.
