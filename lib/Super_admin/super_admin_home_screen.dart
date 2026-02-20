import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'super_admin_nav.dart';

class SuperAdminHomeScreen extends StatefulWidget {
  const SuperAdminHomeScreen({super.key});
  static const routeName = '/super/home';

  @override
  State<SuperAdminHomeScreen> createState() =>
      _SuperAdminHomeScreenState();
}
class _SuperAdminHomeScreenState extends State<SuperAdminHomeScreen> {

  @override
  void initState() {
    super.initState();
    _syncEmailToFirestore(); // 🔑 INI KUNCINYA
  }
  Future<void> _syncEmailToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .update({
      'email': user.email,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }


  // ================= ONLINE VALIDATOR =================
  bool _isAdminOnline(Map<String, dynamic> data) {
    if (data['isOnline'] != true) return false;

    final ts = data['lastOnline'];
    if (ts == null || ts is! Timestamp) return false;

    final last = ts.toDate();
    final diff = DateTime.now().difference(last);

    // ⏱ dianggap online jika update <= 2 menit
    return diff.inMinutes <= 2;
  }

  // ================= FORMAT LAST SEEN =================
  String _formatLastSeen(Timestamp? ts) {
    if (ts == null) return 'Tidak diketahui';

    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} detik lalu';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      drawer: const SuperAdminNav(),
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 1,
        title: const Text('Dashboard Super Admin'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/Images/Logo.png',
              height: 28,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _profileCard(),
            const SizedBox(height: 20),

            _statisticGrid(),
            const SizedBox(height: 28),

            _adminStatusSection(),
            const SizedBox(height: 28),

            _testimonialHighlightSection(), // ⬅️ INI YANG KAMU TAMBAHKAN
            const SizedBox(height: 28),

            _activitySection(),
          ],
        ),
      ),
    );
  }

  // ================= PROFILE =================
  Widget _profileCard() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '-';

    return _card(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.green,
            child: Icon(Icons.verified, color: Colors.white),
          ),

          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Super Admin GreenGuide',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATISTIC =================
  Widget _statisticGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('admins').snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snap.data!.docs;

// 🔥 FILTER HANYA ADMIN VALID
        final admins = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final role = data['role'];
          return role == 'admin' || role == 'super_admin';
        }).toList();

        final total = admins.length;

        final online = admins.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return _isAdminOnline(data);
        }).length;


        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              title: 'Total Admin',
              value: total.toString(),
              icon: Icons.people,
              strong: false,
            ),
            _StatCard(
              title: 'Admin Online',
              value: online.toString(),
              icon: Icons.circle,
              strong: true,
            ),
          ],
        );
      },
    );
  }

  // ================= ADMIN STATUS =================
  Widget _adminStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status Admin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('admins').snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const Text('Memuat...');

            final admins = snap.data!.docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final role = data['role'];
              return role == 'admin' || role == 'super_admin';
            }).toList();

            return Column(
              children: admins.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final online = _isAdminOnline(data);
                final String? photoUrl = data['photoUrl'];

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundImage:
                    (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    data['name'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    online
                        ? (data['email'] ?? 'Email tidak tersedia')
                        : 'Terakhir online: ${_formatLastSeen(data['lastOnline'])}',
                    style: const TextStyle(fontSize: 12),
                  ),

                  trailing: _statusChip(online),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _statusChip(bool online) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: online ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        online ? 'ONLINE' : 'OFFLINE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: online ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  // ================= ACTIVITY =================
  Widget _activitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktivitas Admin',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('admin_activities')
              .orderBy('createdAtLocal', descending: true)
              .limit(5)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const Text('Memuat...');

            return Column(
              children: snap.data!.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return _ActivityItem(
                  _icon(data['action']),
                  data['message'] ?? '-',
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  IconData _icon(String? action) {
    switch (action) {
      case 'create':
        return Icons.add_circle_outline;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete_outline;
      default:
        return Icons.info_outline;
    }
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
  Widget _testimonialHighlightSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('testimonial_stats')
          .doc('global')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final avg = (data['average'] ?? 0).toDouble();
        final total = data['totalReviews'] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Highlight Testimoni',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),

            _card(
              child: Row(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _starRow(avg.round()),
                      const SizedBox(height: 4),
                      Text('$total ulasan'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
  Widget _starRow(int rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }
}


// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final bool strong;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.strong,
  });

  @override
  Widget build(BuildContext context) {
    final bgImage = strong
        ? 'assets/Images/bg_adminonline.jpg'
        : 'assets/Images/bg_supertotaladmin.jpg';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(bgImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        // 🔑 overlay lembut biar gambar tetap kelihatan
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.85),
              Colors.white.withOpacity(0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.black87, // ✅ ICON HITAM
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black, // ✅ ANGKA HITAM
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87, // ✅ JUDUL HITAM
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ================= ACTIVITY ITEM =================
class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ActivityItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
