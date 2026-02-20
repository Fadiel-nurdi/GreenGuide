import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/data_record.dart';
import 'super_admin_nav.dart';

class SuperAdminTestimonialScreen extends StatelessWidget {
  SuperAdminTestimonialScreen({super.key});


  static const routeName = '/super/testimonials'; // ⬅️ TAMBAHKAN INI

  final _service = DataService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Testimoni Pengguna (Read Only)'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: const SuperAdminNav(),
      body: Column(
        children: [

          // ================= RINGKASAN RATING =================
          StreamBuilder<Map<String, dynamic>>(
            stream: _service.streamTestimonialStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox();
              }

              final data = snapshot.data!;
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

          // ================= LIST TESTIMONI =================
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
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
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
}

// ================= STAR RATING =================

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
