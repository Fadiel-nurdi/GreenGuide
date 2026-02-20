import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'super_admin_nav.dart';

class SuperAdminActivityScreen extends StatelessWidget {
  const SuperAdminActivityScreen({super.key});

  static const routeName = '/super-admin/activities';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),

      // 🔒 KUNCI: Super Admin SELALU pakai nav ini
      drawer: const SuperAdminNav(),

      appBar: AppBar(
        title: const Text('Aktivitas Admin'),
        backgroundColor: Colors.green[700],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('admin_activities')
              .orderBy('createdAtLocal', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada aktivitas admin',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final data = docs[i].data() as Map<String, dynamic>;

                final action = data['action'] as String? ?? '';
                final Timestamp? time =
                    data['createdAtLocal'] ?? data['createdAtServer'];

                return _activityCard(
                  email: data['adminEmail'] ?? '-',
                  action: action,
                  message: data['message'] ?? '-',
                  time: _timeAgo(time),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ================= CARD =================
  Widget _activityCard({
    required String email,
    required String action,
    required String message,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _icon(action),
            color: _iconColor(action),
            size: 28,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Text(
            time,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ================= ICON =================
  IconData _icon(String action) {
    switch (action) {
      case 'create':
        return Icons.add_circle;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info_outline;
    }
  }

  // ================= COLOR =================
  Color _iconColor(String action) {
    switch (action) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.orange;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ================= TIME =================
  static String _timeAgo(Timestamp? ts) {
    if (ts == null) return '-';

    final diff = DateTime.now().difference(ts.toDate());

    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
  }
}
