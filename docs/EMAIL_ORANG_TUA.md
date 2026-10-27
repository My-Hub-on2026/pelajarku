# Integrasi email orang tua – spesifikasi implementasi aman

## Status
Fitur email otomatis BELUM aktif. Aplikasi saat ini menyimpan data hanya di SQLite. Mengisi alamat orang tua saja tidak membuktikan kepemilikan email. Diperlukan akun siswa (Firebase Authentication), backend (Cloud Functions), penyedia email (contoh: Resend/SendGrid), dan verifikasi kepemilikan alamat email sebelum pengiriman.

## Alur
1. Siswa/wali mendaftarkan alamat email orang tua dan memberi persetujuan.
2. Backend mengirim kode verifikasi ke alamat tersebut (berlaku 10 menit, maksimal 5 percobaan dan 3 permintaan per jam).
3. Pemilik email memasukkan kode untuk menyetujui penerimaan.
4. Server menyimpan pasangan UID siswa dan alamat orang tua berstatus verified, jangan percaya flag yang dikirim klien.
5. Semua operasi tambah/ubah/hapus tugas, jadwal, nilai, kehadiran, catatan, dan pengaturan menghasilkan event `{type,id,timestamp,diff}`; data dikirim hanya jika subscriber terverifikasi. Untuk sekolah/anak, jangan kirim isi catatan rahasia atau foto/PDF penuh.
6. Gunakan Cloud Functions dengan Firebase App Check + Authentication, rate limits, deduplikasi idempotent berbasis event ID; email dikirim dari backend saja menggunakan secrets.
7. Jika perangkat offline, simpan perubahan dalam outbox SQLite; kirim ulang saat online dan konfirmasi penerimaan idempotent; hindari hilangnya notifikasi atau email berulang.
8. Orang tua dapat berhenti berlangganan, siswa/wali dapat mencabut persetujuan; catat riwayat pengiriman tanpa menyimpan kode OTP asli.
9. Terapkan aturan Firestore yang hanya memperbolehkan tiap siswa membaca miliknya sendiri. Identitas penerima dan status terverifikasi tidak dapat diubah langsung lewat app.

## Sebelum produksi
- Konfigurasi proyek Firebase dan FlutterFire, jalankan server Cloud Functions, pasang domain pengirim dan SPF/DKIM/DMARC.
- Sediakan Privacy Policy, kebijakan retensi dan penghapusan, serta persetujuan wali sesuai peraturan perlindungan data pribadi.
- Uji pemalsuan UID, alamat tidak diverifikasi, percobaan OTP berulang, replay event, offline, serta pembatasan jumlah email.
- Biaya dan kuota Firebase/penyedia email harus diperiksa dan disetujui pemilik proyek.

Jangan memasukkan API key rahasia atau SMTP password ke dalam source code GitHub, terutama karena repository PelajarKu saat ini PUBLIC.
