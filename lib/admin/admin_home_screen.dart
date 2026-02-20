import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/data_service.dart';
import '../models/data_record.dart';
import 'dart:async';


import 'admin_nav.dart';
class StarRating extends StatelessWidget {
  final int rating;

  const StarRating({
    super.key,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  static const routeName = '/admin/home';

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {


  final ScrollController _testimonialController = ScrollController();
  Timer? _timer;
  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_testimonialController.hasClients) return;

      final maxScroll = _testimonialController.position.maxScrollExtent;
      final current = _testimonialController.offset;
      final next = current + 260 + 12;

      _testimonialController.animateTo(
        next >= maxScroll ? 0 : next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
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

  @override
  void dispose() {
    _timer?.cancel();
    _testimonialController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      drawer: const AdminNav(),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        elevation: 0,
        title: const Text('Dashboard Admin'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // 🔕 icon lonceng dihapus
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _profileCard(),
            const SizedBox(height: 16),
            _statisticGridFirestore(),
            const SizedBox(height: 24),
            // ⬇️ TAMBAHKAN DI SINI
            _testimonialHighlight(),
            const SizedBox(height: 24),
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
            radius: 26,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage('assets/Images/Logo.png'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin GreenGuide',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.person_outline),
        ],
      ),
    );
  }

  // ================= STATISTIC =================
  Widget _statisticGridFirestore() {
    final ecoRef = FirebaseFirestore.instance.collection('ecosystems');

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      children: [

        // 🌱 Jenis Ekosistem
        StreamBuilder<QuerySnapshot>(
          stream: ecoRef.snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const _StatCard(
                'Jenis Ekosistem',
                '-',
                Icons.eco,
                backgroundImage: 'assets/Images/bgjeniseko.png',
              );
            }

            final types = <String>{};
            for (final d in snap.data!.docs) {
              final e = (d.data() as Map<String, dynamic>)['ecosystem'];
              if (e is String) types.add(e);
            }

            return _StatCard(
              'Jenis Ekosistem',
              types.length.toString(),
              Icons.eco,
              backgroundImage: 'assets/Images/bgjeniseko.png',
            );
          },
        ),

        // 🌳 Mangrove
        StreamBuilder<QuerySnapshot>(
          stream: ecoRef.where('ecosystem', isEqualTo: 'Mangrove').snapshots(),
          builder: (_, snap) {
            final total = snap.data?.docs.length ?? 0;
            return _StatCard(
              'Ekosistem Mangrove',
              '$total',
              Icons.forest,
              backgroundImage: 'assets/Images/bgmangrove.png',
            );
          },
        ),

        // 🌾 Dataran Rendah
        StreamBuilder<QuerySnapshot>(
          stream: ecoRef
              .where('ecosystem', isEqualTo: 'Dataran Rendah')
              .snapshots(),
          builder: (_, snap) {
            final total = snap.data?.docs.length ?? 0;
            return _StatCard(
              'Ekosistem Dataran Rendah',
              '$total',
              Icons.grass,
              backgroundImage: 'assets/Images/bgdataranrendah.png',
            );
          },
        ),

        // ⏰ UPDATE TERAKHIR (FIXED & SINKRON)
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('admin_activities')
              .orderBy('createdAtLocal', descending: true)
              .limit(1)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const _StatCard(
                'Update Terakhir',
                '-',
                Icons.schedule,
                backgroundImage: 'assets/Images/bgupdateterakhir.png',
              );
            }

            final data =
            snap.data!.docs.first.data() as Map<String, dynamic>;
            final Timestamp? ts =
                data['createdAtLocal'] as Timestamp? ??
                    data['createdAt'] as Timestamp?;

            return _StatCard(
              'Update Terakhir',
              _timeAgo(ts),
              Icons.schedule,
              backgroundImage: 'assets/Images/bgupdateterakhir.png',
            );
          },
        ),
      ],
    );
  }
  Widget _testimonialHighlight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Highlight Testimoni',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 150,
          child: StreamBuilder<List<TestimonialRecord>>(
            stream: DataService.instance.streamTopTestimonials(limit: 5),
            builder: (_, snap) {
              // 1️⃣ Loading
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              // 2️⃣ Error
              if (snap.hasError) {
                return const Center(
                  child: Text(
                    'Gagal memuat testimoni',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              // 3️⃣ Kosong
              if (!snap.hasData || snap.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada testimoni',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              final data = snap.data!;

              return ListView.separated(
                controller: _testimonialController, // ⬅️ INI KUNCI
                scrollDirection: Axis.horizontal,
                itemCount: data.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final t = data[i];

                  return Container(
                    width: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${t.name} • ${t.angkatan}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        StarRating(rating: t.rating),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            t.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }


  // ================= ACTIVITY =================
  Widget _activitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aktivitas Terakhir',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('admin_activities')
              .orderBy('createdAtLocal', descending: true)
              .limit(3)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const CircularProgressIndicator();
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Text(
                'Belum ada aktivitas',
                style: TextStyle(color: Colors.grey),
              );
            }

            return Column(
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                final Timestamp? ts =
                    data['createdAtLocal'] as Timestamp? ??
                        data['createdAt'] as Timestamp?;

                return _ActivityItem(
                  _icon(data['action']),
                  data['message'] ?? '-',
                  _timeAgo(ts),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // ================= HELPER =================
  IconData _icon(String? action) {
    switch (action) {
      case 'create':
        return Icons.add_box;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  static String _timeAgo(Timestamp? ts) {
    if (ts == null) return '-';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${(diff.inDays / 365).floor()} tahun lalu';
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
}

// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final String backgroundImage;

  const _StatCard(
      this.title,
      this.value,
      this.icon, {
        required this.backgroundImage,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.45),
              Colors.black.withOpacity(0.1),
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.white)),
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
  final String time;

  const _ActivityItem(this.icon, this.text, this.time);

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
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
          Text(
            time,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
