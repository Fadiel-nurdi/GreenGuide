import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleRedirector {
  static Future<void> redirect(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (user.isAnonymous) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/user/home');
      return;
    }

    try {
      final adminRef =
      FirebaseFirestore.instance.collection('admins').doc(user.uid);

      final adminDoc = await adminRef.get();

      if (!context.mounted) return;

      if (adminDoc.exists) {
        final role = adminDoc.data()?['role'];

        if (role != 'admin' && role != 'super_admin') {
          Navigator.pushReplacementNamed(context, '/user/home');
          return;
        }

        await adminRef.set({
          'isOnline': true,
          'lastOnline': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (role == 'super_admin') {
          Navigator.pushReplacementNamed(context, '/super/home');
        } else {
          Navigator.pushReplacementNamed(context, '/admin/home');
        }
        return;
      }

      Navigator.pushReplacementNamed(context, '/user/home');
    } catch (_) {
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/user/home');
    }
  }
}
