import 'package:flutter/material.dart';

import '../state/app_store.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController studentName;
  late final TextEditingController schoolName;
  late final TextEditingController className;
  late final TextEditingController kkm;
  String semester = 'Ganjil';
  String timezone = 'Asia/Jakarta';
  bool initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    final AppStore store = AppScope.of(context);
    studentName = TextEditingController(
      text: store.settings['student_name'] ?? '',
    );
    schoolName = TextEditingController(
      text: store.settings['school_name'] ?? '',
    );
    className = TextEditingController(
      text: store.settings['class_name'] ?? '',
    );
    kkm = TextEditingController(text: store.settings['kkm'] ?? '75');
    semester = store.settings['semester'] ?? 'Ganjil';
    timezone = store.settings['timezone'] ?? 'Asia/Jakarta';
    initialized = true;
  }

  @override
  void dispose() {
    studentName.dispose();
    schoolName.dispose();
    className.dispose();
    kkm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppStore store = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil & Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Profil Siswa',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: studentName,
                    decoration: const InputDecoration(labelText: 'Nama siswa'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: schoolName,
                    decoration: const InputDecoration(labelText: 'Nama sekolah'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: className,
                    decoration: const InputDecoration(
                      labelText: 'Kelas',
                      hintText: 'Contoh: 6A, 9B, 10 IPA 1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: semester,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'Ganjil', child: Text('Ganjil')),
                      DropdownMenuItem(value: 'Genap', child: Text('Genap')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) setState(() => semester = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: kkm,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'KKM / nilai minimum',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: timezone,
                    decoration: const InputDecoration(labelText: 'Zona waktu'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'Asia/Jakarta',
                        child: Text('WIB — Jakarta'),
                      ),
                      DropdownMenuItem(
                        value: 'Asia/Makassar',
                        child: Text('WITA — Makassar'),
                      ),
                      DropdownMenuItem(
                        value: 'Asia/Jayapura',
                        child: Text('WIT — Jayapura'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) setState(() => timezone = value);
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _save(context),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Simpan pengaturan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const CircleAvatar(
                child: Icon(Icons.notifications_active_outlined),
              ),
              title: const Text(
                'Aktifkan notifikasi',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Izinkan aplikasi mengingatkan tugas dan ujian pada perangkat ini.',
              ),
              trailing: FilledButton.tonal(
                onPressed: () async {
                  await store.requestNotificationPermission();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Permintaan izin notifikasi telah ditampilkan.'),
                      ),
                    );
                  }
                },
                child: const Text('Aktifkan'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(child: ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Uji suara dan getar'),
            subtitle: const Text('Cek pemberitahuan sekarang dan jumlah pengingat yang aktif.'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                await store.testNotification();
                final total = await store.pendingNotifications();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Notifikasi uji dikirim. Jadwal aktif: $total. Periksa mode senyap dan setelan channel.'),
                ));
              },
              child: const Text('Tes'),
            ),
          )),
          const SizedBox(height: 12),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Privasi MVP: data tersimpan lokal di perangkat. Untuk versi produksi dengan sinkronisasi akun dan akses orang tua, tambahkan autentikasi, database cloud, aturan keamanan, persetujuan wali, ekspor data, dan penghapusan akun.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final AppStore store = AppScope.of(context);
    final double? parsedKkm = double.tryParse(kkm.text.replaceAll(',', '.'));
    if (studentName.text.trim().isEmpty ||
        schoolName.text.trim().isEmpty ||
        parsedKkm == null ||
        parsedKkm < 0 ||
        parsedKkm > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali nama sekolah, nama siswa, dan KKM.')),
      );
      return;
    }

    await Future.wait<void>(<Future<void>>[
      store.setSetting('student_name', studentName.text.trim()),
      store.setSetting('school_name', schoolName.text.trim()),
      store.setSetting('class_name', className.text.trim()),
      store.setSetting('semester', semester),
      store.setSetting('kkm', parsedKkm.toString()),
      store.setSetting('timezone', timezone),
    ]);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan tersimpan. Buka ulang aplikasi setelah mengganti zona waktu.'),
        ),
      );
    }
  }
}
