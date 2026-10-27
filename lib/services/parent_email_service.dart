import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Tidak menyimpan kunci email di ponsel. Hanya aktif jika Firebase
/// sudah dikonfigurasi dan Cloud Functions sudah diterbitkan.
class ParentEmailService {
  ParentEmailService._();
  static final instance = ParentEmailService._();
  bool ready = false;
  String status = 'Firebase belum dikonfigurasi';

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      await FirebaseAppCheck.instance.activate(
        providerAndroid: AndroidProvider.playIntegrity,
        providerApple: AppleProvider.appAttest,
      );
      await FirebaseAuth.instance.signInAnonymously();
      ready = FirebaseAuth.instance.currentUser != null;
      status = ready ? 'Cloud tersedia, email perlu diverifikasi' :
          'Login cloud belum berhasil';
    } catch (error) {
      ready = false;
      status = 'Email belum aktif: Firebase/Cloud Functions belum disiapkan';
      debugPrint('ParentEmailService: $error');
    }
  }

  HttpsCallable _function(String name) =>
      FirebaseFunctions.instanceFor(region: 'asia-southeast2').httpsCallable(name);

  Future<void> requestVerification(String email) async {
    if (!ready) throw StateError(status);
    await _function('requestParentEmailVerification').call(<String, dynamic>{
      'email': email.trim(),
    });
  }

  Future<void> confirmVerification(String code) async {
    if (!ready) throw StateError(status);
    await _function('confirmParentEmailVerification').call(<String, dynamic>{
      'code': code.trim(),
    });
  }

  Future<void> disconnect() async {
    if (!ready) throw StateError(status);
    await _function('disconnectParentEmail').call();
  }

  Future<void> notifyChange({
    required String type,
    required String action,
    required String summary,
  }) async {
    if (!ready) return;
    try {
      await _function('notifyParentOfChange').call(<String, dynamic>{
        'eventId': const Uuid().v4(),
        'type': type,
        'action': action,
        'summary': summary.length > 160 ? summary.substring(0,160) : summary,
      });
    } catch (error) {
      // DB lokal tetap berfungsi. Implementasi produksi memerlukan
      // persistent outbox agar event tidak hilang ketika offline.
      debugPrint('Pengiriman email gagal: $error');
    }
  }
}
