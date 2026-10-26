# Product Requirements Document — PelajarKu

## 1. Tujuan

Membuat aplikasi perencana sekolah lintas Android dan iOS yang mudah digunakan siswa Indonesia, tetap berguna tanpa internet, dan dapat berkembang menjadi sistem sinkronisasi siswa–orang tua–sekolah.

## 2. Pengguna utama

### Siswa SD/MI

- membutuhkan tombol besar dan bahasa sederhana;
- lebih sering memakai checklist dan jadwal harian;
- pengaturan dapat dibantu orang tua.

### Siswa SMP/MTs

- mulai mengelola banyak tugas dan ujian;
- membutuhkan prioritas dan pengingat;
- membutuhkan nilai dan kehadiran sederhana.

### Siswa SMA/MA/SMK

- membutuhkan bobot nilai, proyek, praktik, dan tenggat lebih kompleks;
- membutuhkan catatan per mata pelajaran;
- dapat memakai sinkronisasi antarperangkat.

## 3. Prinsip desain Indonesia

1. Gunakan istilah **mata pelajaran**, **tugas**, **ulangan/ujian**, **kelas**, **semester ganjil/genap**, dan **KKM**.
2. Dukungan zona waktu WIB, WITA, dan WIT.
3. Jadwal Senin–Sabtu sebagai default.
4. Aplikasi tetap dapat dipakai tanpa akun.
5. Warna mata pelajaran membantu pengenalan cepat.
6. Tidak memaksa siswa memasukkan data pribadi yang tidak diperlukan.
7. Navigasi utama maksimal lima tab.
8. Setiap formulir memiliki nilai awal yang masuk akal.

## 4. Navigasi

```text
Beranda
  ├─ ringkasan hari ini
  ├─ jadwal hari ini
  └─ tenggat terdekat

Jadwal
  ├─ pilih hari
  ├─ tambah/edit mapel
  └─ hapus mapel

Tugas
  ├─ filter aktif/selesai/semua
  ├─ tambah tugas/ujian/proyek/kegiatan
  ├─ pengingat
  └─ checklist selesai

Nilai
  ├─ rata-rata keseluruhan
  ├─ rata-rata per mapel
  ├─ status terhadap KKM
  └─ tambah/hapus nilai

Lainnya
  ├─ Kehadiran
  ├─ Catatan
  └─ Profil & Pengaturan
```

## 5. Kebutuhan fungsional MVP

### F-01 Jadwal pelajaran

- Siswa dapat membuat, mengubah, dan menghapus mata pelajaran.
- Mata pelajaran memiliki nama, guru, ruangan, hari, jam mulai, jam selesai, dan warna.
- Daftar diurutkan berdasarkan jam mulai.

### F-02 Tugas dan ujian

- Jenis: tugas, ujian, proyek, kegiatan.
- Prioritas: rendah, sedang, tinggi.
- Item memiliki tenggat, catatan, mapel opsional, pengingat opsional, dan status selesai.
- Pengingat harus lebih awal dari tenggat.

### F-03 Nilai

- Nilai terkait dengan mata pelajaran.
- Nilai memiliki kategori, skor, nilai maksimum, bobot, dan tanggal.
- Sistem menghitung persentase dan rata-rata berbobot.
- Sistem membandingkan rata-rata dengan KKM.

### F-04 Kehadiran

- Status: hadir, izin, sakit, alpa.
- Kehadiran terkait mapel dan tanggal.
- Sistem menampilkan persentase hadir.

### F-05 Catatan

- Catatan memiliki judul dan isi.
- Catatan dapat bersifat umum atau terkait mapel.
- Catatan diurutkan berdasarkan waktu pembaruan.

### F-06 Pengaturan

- Nama siswa, sekolah, kelas, semester, KKM, dan zona waktu.
- Izin notifikasi diminta setelah pengguna menekan tombol, bukan saat pertama membuka aplikasi.

## 6. Kebutuhan nonfungsional

- Waktu buka cepat dengan data lokal.
- Fungsi inti tidak membutuhkan internet.
- Tidak ada data sensitif di log.
- Antarmuka responsif pada ponsel kecil dan besar.
- Semua aksi hapus memiliki konfirmasi.
- Tanggal dan bahasa memakai lokal Indonesia.
- Database mendukung migrasi versi.
- Build production memakai signing key yang tidak disimpan di repository.

## 7. Definisi selesai untuk MVP

MVP dianggap siap diuji ketika:

1. `flutter analyze` tanpa error;
2. seluruh unit test lulus;
3. CRUD setiap fitur lulus pada Android dan iOS;
4. pengingat muncul setelah aplikasi ditutup;
5. pengingat tetap ada setelah restart perangkat;
6. seluruh layar tidak overflow pada ukuran teks 130%;
7. data tetap ada setelah aplikasi ditutup dan dibuka kembali;
8. penghapusan mata pelajaran tidak membuat aplikasi crash;
9. zona waktu WIB/WITA/WIT diuji;
10. build release dapat dipasang melalui internal testing.
