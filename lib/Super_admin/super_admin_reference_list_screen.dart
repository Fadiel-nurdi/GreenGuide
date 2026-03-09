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

// 🔥 KELOMPOKKAN BERDASARKAN ECOSYSTEM
          final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};

          for (var doc in docs) {
            final eco = doc.data()['ecosystem'] ?? 'Lainnya';
            grouped.putIfAbsent(eco, () => []);
            grouped[eco]!.add(doc);
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: grouped.entries.map((entry) {
              final ecosystemName = entry.key;
              final items = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // 🔹 JUDUL EKOSISTEM
                  Text(
                    ecosystemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  ...items.map((doc) {
                    final data = doc.data();

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
                  }).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
