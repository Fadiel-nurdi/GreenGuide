import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'super_admin_nav.dart';


class SuperAdminAdminManage extends StatelessWidget {
  const SuperAdminAdminManage({super.key});

  static const routeName = '/super-admin/manage-admin';

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('admins');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      drawer: const SuperAdminNav(),
      appBar: AppBar(
        title: const Text('Kelola Admin'),
        backgroundColor: Colors.green[800],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () => _showAddAdminDialog(context),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _ref.orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Belum ada admin'));
            }

            final docs = snapshot.data!.docs;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final data = docs[i].data();
                final docId = docs[i].id;

                final Timestamp? lastOnline = data['lastOnline'];

                return _adminCard(
                  context: context,
                  docId: docId,
                  name: data['name'] ?? '-',
                  email: data['email'] ?? '-',
                  role: data['role'] ?? '-',
                  active: data['active'] == true,
                  isOnline: data['isOnline'] == true,
                  lastOnline: lastOnline,
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget _adminCard({
    required BuildContext context,
    required String docId,
    required String name,
    required String email,
    required String role,
    required bool active,
    required bool isOnline,
    required Timestamp? lastOnline,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: active ? Colors.green : Colors.red,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(email,
                    style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(role, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  isOnline
                      ? 'Online sekarang'
                      : lastOnline != null
                      ? 'Terakhir online: ${_timeAgo(lastOnline)}'
                      : 'Offline',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: active,
                onChanged: (val) => _toggleActive(context, docId, val),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(context, docId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= ADD ADMIN =================
  void _showAddAdminDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Admin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
          onPressed: () async {
    try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Super admin belum login')),
    );
    return;
    }
    print("UID LOGIN: ${FirebaseAuth.instance.currentUser!.uid}");
    print("EMAIL LOGIN: ${FirebaseAuth.instance.currentUser!.email}");

    await user.getIdToken(true); // refresh token WAJIB

    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
      app: FirebaseAuth.instance.app,
    ).httpsCallable('createAdmin');




    await callable.call({
      'name': nameCtrl.text.trim(),
      'email': emailCtrl.text.trim().toLowerCase(),
    });

// 🔥 Kirim email reset password otomatis
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailCtrl.text.trim().toLowerCase(),
      );


      Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Admin berhasil dibuat')),
    );

    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Gagal: $e')),
    );
    }
    },

    child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ================= DELETE =================
  Future<void> _confirmDelete(BuildContext context, String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Admin'),
        content: const Text('Admin ini akan dihapus dari sistem.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final callable = FirebaseFunctions.instanceFor(
          region: 'us-central1',
          app: FirebaseAuth.instance.app,
        ).httpsCallable('deleteAdmin');



        await callable.call({'uid': docId});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin berhasil dihapus'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal hapus: $e'),
          ),
        );
      }
    }

  }

  // ================= TOGGLE ACTIVE =================
  Future<void> _toggleActive(
      BuildContext context, String docId, bool value) async {

    await _ref.doc(docId).update({
      'active': value,
      'isOnline': value ? true : false,
      'lastOnline': value ? null : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? 'Admin diaktifkan' : 'Admin dinonaktifkan',
        ),
      ),
    );
  }


  // ================= TIME AGO =================
  static String _timeAgo(Timestamp ts) {
    final diff = DateTime.now().difference(ts.toDate());

    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${(diff.inDays / 7).floor()} minggu lalu';
  }
}
