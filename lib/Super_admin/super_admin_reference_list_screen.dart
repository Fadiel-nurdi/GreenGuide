import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'super_admin_nav.dart'; // ✅ PENTING

class SuperAdminReferenceListScreen extends StatelessWidget {
  const SuperAdminReferenceListScreen({super.key});

  static const routeName = '/super-admin/references';

  CollectionReference<Map<String, dynamic>> get _refRef =>
      FirebaseFirestore.instance.collection('references');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ PAKAI NAV DRAWER
      drawer: const SuperAdminNav(),

      appBar: AppBar(
        title: const Text('Daftar Pustaka'),
        backgroundColor: Colors.green[700],

        // ✅ GANTI BACK JADI MENU
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _refRef
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return const Center(
              child: Text('Gagal memuat daftar pustaka'),
            );
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('Belum ada daftar pustaka'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    data['citation'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text('Kategori: ${data['ecosystem'] ?? '-'}'),
                      if (data['year'] != null)
                        Text('Tahun: ${data['year']}'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
