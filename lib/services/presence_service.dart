import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;

  /// Dipanggil SEKALI saat app start
  static void init() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _firestore.collection('admins').doc(user.uid).set({
          'isOnline': true,
          'isonline': true,
          'lastOnline': FieldValue.serverTimestamp(),
          'lastSeen': FieldValue.serverTimestamp(),
          'lastAction': 'login',
          'lastActionAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  /// Dipanggil SAAT LOGOUT
  static Future<void> setOfflineManually() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('admins').doc(user.uid).set({
      'isOnline': false,
      'isonline': false,
      'lastOnline': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'lastAction': 'logout',
      'lastActionAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
