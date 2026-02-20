import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/data_record.dart';
import 'admin_nav.dart';

class AdminTestimonialScreen extends StatelessWidget {
  static const routeName = '/admin/testimoni'; // ✅ SAMAKAN
  AdminTestimonialScreen({super.key});

  final _service = DataService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminNav(),
      appBar: AppBar(
        title: const Text('Kelola Testimoni'),
      ),
      body: Column(
        children: [
          // ⭐ RINGKASAN TESTIMONI (SAMA DENGAN USER)
          StreamBuilder<Map<String, dynamic>>(
            stream: _service.streamTestimonialStats(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const SizedBox();
              }

              final data = snap.data!;
              final avg = (data['average'] ?? 0).toDouble();
              final total = data['totalReviews'] ?? 0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StarRating(rating: avg.round()),
                        Text('$total ulasan'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // 📋 DAFTAR TESTIMONI
          Expanded(
            child: StreamBuilder<List<TestimonialRecord>>(
              stream: _service.streamTestimonials(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data ?? [];

                if (data.isEmpty) {
                  return const Center(child: Text('Belum ada testimoni'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: data.length,
                  itemBuilder: (_, i) {
                    final t = data[i];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${t.name} • Angkatan ${t.angkatan}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                StarRating(rating: t.rating),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(t.message),
                            const Divider(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                label: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () => _confirmDelete(
                                  context,
                                  t.id,
                                  t.rating,
                                ),

                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context,
      String id,
      int rating,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Testimoni'),
        content: const Text(
          'Apakah kamu yakin ingin menghapus testimoni ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await _service.deleteTestimonial(id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Testimoni berhasil dihapus'),
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// ========================== STAR RATING =============================
// ===================================================================

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
          size: 20,
        );
      }),
    );
  }
}
