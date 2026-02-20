import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ===============================
/// ADMIN ACTIVITY LOGGER (FINAL)
/// ===============================
/// Digunakan oleh:
/// - Admin
/// - Super Admin
///
/// Bertanggung jawab untuk:
/// - Mencatat aktivitas (create / update / delete)
/// - Menjadi SATU-SATUNYA sumber "Update Terakhir"
class AdminActivityLogger {
  static const String _collection = 'admin_activities';

  /// ACTION: create | update | delete
  static Future<void> log({
    required String action,
    required String ecoId,
    required String ecosystem,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // ⛔ safety guard

    final firestore = FirebaseFirestore.instance;

    try {
      final Timestamp localTime = Timestamp.now();

      final String message = _buildMessage(
        action: action,
        ecoId: ecoId,
        ecosystem: ecosystem,
      );

      // ===============================
      // SIMPAN LOG AKTIVITAS (SINGLE SOURCE)
      // ===============================
      await firestore.collection(_collection).add({
        'action': action,            // create | update | delete
        'ecoId': ecoId,
        'ecosystem': ecosystem,

        // admin info
        'adminUid': user.uid,
        'adminEmail': user.email,

        // UI
        'message': message,

        // timestamp (dipakai dashboard & aktivitas)
        'createdAtLocal': localTime,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ❗ Logging TIDAK BOLEH menggagalkan proses utama
      debugPrint('AdminActivityLogger error: $e');
    }
  }

  /// ===============================
  /// MESSAGE BUILDER (KONSISTEN & HUMAN)
  /// ===============================
  static String _buildMessage({
    required String action,
    required String ecoId,
    required String ecosystem,
  }) {
    switch (action) {
      case 'create':
        return '$ecoId ($ecosystem) berhasil ditambahkan';
      case 'update':
        return '$ecoId ($ecosystem) berhasil diperbarui';
      case 'delete':
        return '$ecoId ($ecosystem) berhasil dihapus';
      default:
        return '$ecoId ($ecosystem)';
    }
  }
}
