import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_home_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_ecosystem_list_screen.dart';
import 'admin_activity_screen.dart';
import 'admin_testimonial_screen.dart';

class AdminNav extends StatelessWidget {
  const AdminNav({super.key});

  // ================= SET OFFLINE (HANYA SAAT LOGOUT) =================
  Future<void> _setOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .update({
      'isOnline': false,
      'lastOnline': FieldValue.serverTimestamp(),
    });
  }

  void _go(BuildContext context, String route) {
    Navigator.pop(context);

    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == route) return;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '-';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ================= HEADER =================
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Images/kocak.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            accountName: const Text(
              'Admin GreenGuide',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            accountEmail: Text(
              email,
              style: const TextStyle(color: Colors.white),
            ),
            currentAccountPicture: Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/Images/Logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),


          // ================= DASHBOARD =================
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => _go(context, AdminHomeScreen.routeName),
          ),

          // ================= PROFIL ADMIN =================
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil Admin'),
            onTap: () => _go(context, AdminProfileScreen.routeName),
          ),

          const Divider(),

          // ================= KELOLA EKOSISTEM =================
          ListTile(
            leading: const Icon(Icons.park),
            title: const Text('Kelola Ekosistem'),
            onTap: () => _go(context, AdminEcosystemListScreen.routeName),
          ),

          // ================= AKTIVITAS =================
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Aktivitas'),
            onTap: () => _go(context, AdminActivityScreen.routeName),
          ),
          // ================= KELOLA TESTIMONI =================
          ListTile(
            leading: const Icon(Icons.star_rate),
            title: const Text('Kelola Testimoni'),
            onTap: () => _go(context, AdminTestimonialScreen.routeName),
          ),

          // ================= SARAN & MASUKAN =================
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Saran & Masukan'),
            onTap: () => _go(context, '/suggestions'),
          ),

          const Divider(),

          // ================= LOGOUT =================
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);

              try {
                final user = FirebaseAuth.instance.currentUser;

                if (user != null) {
                  final adminRef = FirebaseFirestore.instance.collection('admins').doc(user.uid);
                  try {
                    await adminRef.update({
                      'isOnline': false,
                      'isonline': false,
                      'lastSeen': FieldValue.serverTimestamp(),
                      'lastAction': 'logout',
                      'lastActionAt': FieldValue.serverTimestamp(),
                    });
                  } catch (e) {
                    // Fallback: try set with merge in case update is blocked for some fields
                    try {
                      await adminRef.set({
                        'isOnline': false,
                        'isonline': false,
                        'lastSeen': FieldValue.serverTimestamp(),
                        'lastAction': 'logout',
                        'lastActionAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    } catch (e2) {
                      // Give feedback but proceed to sign out to avoid locking user in app
                      print('Failed to clear admin online flag: $e2');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal menghapus status online di server. Anda tetap akan logout secara lokal.')),
                        );
                      }
                    }
                  }
                }

                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/admin-login',
                        (_) => false,
                  );
                }
              } catch (e) {
                print("LOGOUT ERROR: $e");
              }
            },
          ),
        ],
      ),
    );
  }
}
