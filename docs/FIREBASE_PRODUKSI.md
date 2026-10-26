# Tahap Produksi: Akun, Sinkronisasi, dan Orang Tua

MVP pada folder ini sengaja memakai SQLite agar aplikasi langsung dapat dipakai tanpa akun dan tanpa internet. Untuk aplikasi publik, tambahkan Firebase secara bertahap. Dokumentasi Firebase Flutter saat paket ini disusun mensyaratkan target iOS 15 atau lebih baru untuk integrasi Firebase, sehingga naikkan deployment target dari iOS 13 ketika tahap cloud mulai dipasang.

## 1. Layanan yang dipakai

- **Firebase Authentication**: akun siswa, orang tua, dan guru.
- **Cloud Firestore**: sinkronisasi jadwal, tugas, nilai, kehadiran, dan catatan.
- **Cloud Functions**: validasi undangan orang tua, rekap, dan proses yang tidak boleh dipercaya dari perangkat klien.
- **Firebase Cloud Messaging**: pengumuman sekolah atau pengingat lintas perangkat.
- **Firebase Storage**: lampiran tugas atau foto catatan, bila benar-benar diperlukan.
- **Crashlytics**: pelacakan crash tanpa menyimpan isi catatan siswa.

## 2. Struktur koleksi yang disarankan

```text
users/{uid}
  displayName
  role: student | parent | teacher
  schoolId
  createdAt

students/{studentUid}
  className
  semester
  kkm

students/{studentUid}/courses/{courseId}
students/{studentUid}/tasks/{taskId}
students/{studentUid}/grades/{gradeId}
students/{studentUid}/attendance/{entryId}
students/{studentUid}/notes/{noteId}

parentLinks/{linkId}
  studentUid
  parentUid
  status: pending | accepted | revoked
  createdAt

schools/{schoolId}/announcements/{announcementId}
```

Jangan menyimpan semua data siswa dalam satu dokumen. Gunakan subkoleksi agar ukuran dokumen tetap kecil dan aturan akses mudah diaudit.

## 3. Pemasangan FlutterFire

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
flutter pub add firebase_core firebase_auth cloud_firestore firebase_messaging
```

Kemudian inisialisasi Firebase sebelum `runApp`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## 4. Contoh aturan Firestore awal

Tautan orang tua harus dibuat dan diubah hanya melalui Cloud Function tepercaya. Klien tidak diberi izin menulis langsung ke `parentLinks`.

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function isOwner(studentUid) {
      return signedIn() && request.auth.uid == studentUid;
    }

    function parentLinkId(studentUid) {
      return request.auth.uid + '_' + studentUid;
    }

    function isLinkedParent(studentUid) {
      return signedIn() &&
        exists(/databases/$(database)/documents/parentLinks/$(parentLinkId(studentUid))) &&
        get(/databases/$(database)/documents/parentLinks/$(parentLinkId(studentUid))).data.status == 'accepted';
    }

    match /users/{uid} {
      allow read, write: if signedIn() && request.auth.uid == uid;
    }

    match /students/{studentUid} {
      allow read: if isOwner(studentUid) || isLinkedParent(studentUid);
      allow write: if isOwner(studentUid);

      match /{collectionName}/{documentId} {
        allow read: if isOwner(studentUid) || isLinkedParent(studentUid);
        allow write: if isOwner(studentUid);
      }
    }

    match /parentLinks/{linkId} {
      allow read: if signedIn() &&
        (resource.data.studentUid == request.auth.uid ||
         resource.data.parentUid == request.auth.uid);
      allow write: if false;
    }
  }
}
```

Aturan tersebut masih perlu diuji dengan Firebase Emulator Suite. Cloud Function yang memproses kode undangan wajib memverifikasi masa berlaku, siswa pemilik undangan, identitas orang tua, dan status tautan sebelum menulis memakai Admin SDK.

## 5. Strategi sinkronisasi

1. SQLite tetap menjadi sumber data lokal agar aplikasi cepat dan dapat dipakai offline.
2. Setiap perubahan lokal diberi `updatedAt`, `deviceId`, dan `syncState`.
3. Perubahan dikirim ke Firestore ketika koneksi tersedia.
4. Gunakan `serverTimestamp` untuk waktu server.
5. Konflik sederhana dapat memakai `last-write-wins`; untuk catatan panjang, tampilkan pilihan versi kepada pengguna.
6. Jangan mengirim ulang seluruh database. Sinkronkan per dokumen.

## 6. Akun orang tua

Alur aman:

1. Siswa membuat kode undangan sekali pakai.
2. Cloud Function menyimpan hash kode dan masa berlaku singkat.
3. Orang tua memasukkan kode setelah login.
4. Siswa menyetujui tautan di perangkatnya.
5. Orang tua mendapat akses baca, bukan akses mengubah nilai atau kehadiran.
6. Siswa dapat mencabut akses kapan saja.

Jangan memakai kode kelas permanen yang dapat diteruskan ke orang lain.

## 7. Data anak dan privasi

- Kumpulkan data seminimal mungkin.
- Jangan meminta tanggal lahir lengkap bila jenjang kelas sudah cukup.
- Jangan mengaktifkan iklan berbasis profil untuk akun anak.
- Sediakan ekspor dan penghapusan akun.
- Jelaskan data apa yang dibaca orang tua atau guru.
- Enkripsi komunikasi dengan HTTPS/TLS dan gunakan penyimpanan aman untuk token.
- Jangan menaruh kunci admin Firebase di aplikasi.
