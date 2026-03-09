import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_home_screen.dart';
import 'admin_profile_screen.dart';
import 'admin_ecosystem_list_screen.dart';
import 'admin_reference_list_screen.dart';
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

          // ================= KELOLA DAFTAR PUSTAKA =================
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Kelola Daftar Pustaka'),
            onTap: () => _go(context, AdminReferenceListScreen.routeName),
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
            onTap: () => _go(context, '/admin/suggestions'),
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
                Navigator.of(context).pop(); // tutup drawer dulu

                try {
                  final user = FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('admins')
                        .doc(user.uid)
                        .update({
                      'isOnline': false,
                      'lastSeen': FieldValue.serverTimestamp(),
                    });
                  }

                  await FirebaseAuth.instance.signOut();

                  // gunakan root navigator
                  Navigator.of(context, rootNavigator: true)
                      .pushNamedAndRemoveUntil('/admin-login', (route) => false);

                } catch (e) {
                  print("LOGOUT ERROR: $e");
                }
              }
          ),
        ],
      ),
    );
  }
}
