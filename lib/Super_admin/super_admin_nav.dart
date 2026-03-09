import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:greenguide_app/Super_admin/super_admin_suggestions_screen.dart';

import 'super_admin_home_screen.dart';
import 'super_admin_profile_screen.dart';
import 'super_admin_activity_screen.dart';
import 'super_admin_ecosystem.dart';
import 'super_admin_admin_manage.dart';
import 'super_admin_reference_list_screen.dart';
import 'super_admin_testimonial_screen.dart';


class SuperAdminNav extends StatelessWidget {
  const SuperAdminNav({super.key});

  // ================= SET OFFLINE =================
  Future<void> _setOffline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .set({
      'isOnline': false,
      'isonline': false,
      'lastOnline': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ================= SAFE NAV =================
  void _go(BuildContext context, String route) {
    Navigator.pop(context);

    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) return;

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
              'Super Admin GreenGuide',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.transparent,
            ),
          ),

          // ================= DASHBOARD =================
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => _go(
              context,
              SuperAdminHomeScreen.routeName,
            ),
          ),

          // ================= PROFIL =================
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profil'),
            onTap: () => _go(
              context,
              SuperAdminProfileScreen.routeName,
            ),
          ),

          const Divider(),

          // ================= MONITORING EKOSISTEM =================
          ListTile(
            leading: const Icon(Icons.park),
            title: const Text('Monitoring Ekosistem'),
            onTap: () => _go(
              context,
              SuperAdminEcosystemScreen.routeName,
            ),
          ),

          // ================= DAFTAR PUSTAKA (READ ONLY) =================
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Daftar Pustaka'),
            subtitle: const Text('Read-only'),
            onTap: () => _go(
              context,
              SuperAdminReferenceListScreen.routeName,
            ),
          ),

          // ================= AKTIVITAS ADMIN =================
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Aktivitas Admin'),
            onTap: () => _go(
              context,
              SuperAdminActivityScreen.routeName,
            ),
          ),
          // ================= KELOLA TESTIMONI =================
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: const Text('Kelola Testimoni'),
            onTap: () => _go(
              context,
              SuperAdminTestimonialScreen.routeName,
            ),
          ),

          // ================= SARAN & MASUKAN (READ-ONLY FOR SUPERADMIN) =================
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Saran & Masukan'),
            onTap: () => _go(context, SuperAdminSuggestionsScreen.routeName,),
          ),

          // ================= KELOLA ADMIN =================
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Kelola Admin'),
            onTap: () => _go(
              context,
              SuperAdminAdminManage.routeName,
            ),
          ),

          const Divider(),

          // ================= LOGOUT (FIXED) =================
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
                      'lastOnline': FieldValue.serverTimestamp(),
                      'lastAction': 'logout',
                      'lastActionAt': FieldValue.serverTimestamp(),
                    });
                  } catch (e) {
                    try {
                      await adminRef.set({
                        'isOnline': false,
                        'isonline': false,
                        'lastOnline': FieldValue.serverTimestamp(),
                        'lastAction': 'logout',
                        'lastActionAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                    } catch (e2) {
                      print('Failed to clear admin online flag: $e2');
                    }
                  }
                }

                await FirebaseAuth.instance.signOut();
              } catch (e) {
                print('Logout error: $e');
              }

               if (context.mounted) {
                 Navigator.pushNamedAndRemoveUntil(
                   context,
                   '/admin-login', // ⬅️ HARUS ADA DI app_router.dart
                       (_) => false,
                 );
               }
             },
           ),
        ],
      ),
    );
  }
}
