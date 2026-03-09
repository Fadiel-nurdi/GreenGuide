import 'package:flutter/material.dart';
import 'navscreen.dart';
import '../services/data_service.dart';
import '../models/data_record.dart';
import '../screens/testimonial_screen.dart'; // kalau StarRating di sana
import 'dart:async';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color bg = Color(0xFFF3F6E9); // krem lembut seperti di Figma

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: bg,

      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: NavScreen(currentPage: 'home'),
      ),

      appBar: AppBar(
      backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,

        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/Images/Logo.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Green Guide',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),

      // ❗ Jangan pakai const di Column biar aman dari "Not a constant expression"
      body: SafeArea(
        bottom: true, // ⬅️ penting untuk HP Android
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + MediaQuery.of(context).padding.bottom, // ⬅️ kunci utama
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeroSection(),
              const SizedBox(height: 24),
              const _FeatureSection(),
              const SizedBox(height: 24),

              // ⭐ TAMBAHKAN DI SINI
              const _TestimonialPreviewSection(),
              const SizedBox(height: 24),

              const _ContactSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================= HERO =================
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Images/bghome1.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black54,
                            Colors.black26,
                            Colors.transparent,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    top: 20,
                    right: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Green Guide',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Aplikasi rekomendasi tanaman berdasarkan ekosistem lahan, jenis tanah, ketinggian, pH, dan curah hujan.\n\nSilahkan klik "PANDUAN" untuk penggunaan aplikasi.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ✅ TOMBOL SUDAH SESUAI PERMINTAAN
                        Row(
                          children: [
                            // Panduan -> explore_screen.dart
                            FilledButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/explore');
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF4C7C3C),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text('Panduan'),
                            ),
                            const SizedBox(width: 8),

                            // Mulai Rekomendasi -> formrekapps.dart
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/formrekapps');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: const Text('Mulai Rekomendasi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 16,
                    right: 18,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Row(
                          children: [
                            Icon(Icons.public, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Icon(Icons.camera_alt_outlined,
                                size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Icon(Icons.language, size: 18, color: Colors.white),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/Images/underhome.png',
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Temukan tanaman yang cocok untuk lahan secara cepat dan akurat berdasarkan data ekosistem.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= FITUR =================
class _FeatureSection extends StatelessWidget {
  const _FeatureSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget featureCard(
        String title,
        String subtitle,
        String desc, [
          String assetName = '',
        ]) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: assetName.isNotEmpty
                  ? Image.asset(
                assetName,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 72,
                height: 72,
                color: const Color(0xFFE4EED5),
                alignment: Alignment.center,
                child: const Icon(Icons.local_florist),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beberapa fitur yang tersedia',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // ✅ Panduan Aplikasi -> teacher.jpeg
        featureCard(
          'Panduan Aplikasi',
          'Maksimalkan penggunaan aplikasi',
          'Jelajahi panduan aplikasi sebelum mengeksplor lebih jauh.',
          'assets/Images/teacher.jpeg',
        ),

        // ✅ Ekosistem -> teacher2.png
        featureCard(
          'Ekosistem',
          'Ekosistem Lahan',
          'Jelajahi berbagai ekosistem tanaman yang tersedia.',
          'assets/Images/teacher2.png',
        ),

        // Formulir Rekomendasi -> placeholder
        featureCard(
          'Formulir Rekomendasi',
          'Rekomendasi',
          'Dapat rekomendasi tanaman yang sesuai dengan kebutuhan lahan Anda.',
          'assets/Images/teachermendata.jpg'
        ),
      ],
    );
  }
}

/// ================= TESTIMONI PREVIEW (HOME) =================
class _TestimonialPreviewSection extends StatefulWidget {
  const _TestimonialPreviewSection();

  @override
  State<_TestimonialPreviewSection> createState() =>
      _TestimonialPreviewSectionState();
}
class _TestimonialPreviewSectionState
    extends State<_TestimonialPreviewSection> {

  final ScrollController _listController = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_listController.hasClients) return;

      final maxScroll = _listController.position.maxScrollExtent;
      final current = _listController.offset;
      final next = current + 260 + 12;

      _listController.animateTo(
        next >= maxScroll ? 0 : next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _listController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final service = DataService.instance;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apa kata pengguna?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        StreamBuilder<List<TestimonialRecord>>(
          stream: service.streamTestimonials(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data ?? [];

            if (data.isEmpty) {
              return const Text('Belum ada testimoni.');
            }

            // 🔥 AMBIL MAX 3 TESTIMONI SAJA
            final preview = data
                .where((t) => t.rating == 5) // ⭐ hanya bintang 5
                .toList();

            return Column(
              children: [
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    controller: _listController, // ⬅️ INI KUNCI
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(), // ⬅️ BIAR TIDAK TARIK HALAMAN
                    itemCount: preview.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 260,
                        child: _TestimonialCard(preview[index]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/testimoni');
                    },
                    child: const Text('Lihat semua testimoni'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
class _TestimonialCard extends StatelessWidget {
  final TestimonialRecord t;
  const _TestimonialCard(this.t);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 NAMA + ANGKATAN (1 BARIS, AMAN)
          Text(
            '${t.name} • Angkatan ${t.angkatan}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 6),

          // ⭐ RATING (SENDIRI, TIDAK PEREBUTAN LEBAR)
          Wrap(
            spacing: 2,
            children: List.generate(
              5,
                  (index) => Icon(
                index < t.rating ? Icons.star : Icons.star_border,
                size: 18,
                color: Colors.amber,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 💬 PESAN
          Text(
            t.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}






/// ================= CONTACT / FOOTER =================
class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tentang kami',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          // Logo + Nama
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withOpacity(0.12),
                child: ClipOval(
                  child: Image.asset(
                    'assets/Images/Logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Green Guide',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Green Guide merupakan aplikasi edukatif berbasis sistem rekomendasi '
                'yang dikembangkan sebagai bagian dari proyek pembelajaran di bawah '
                'bimbingan Ibu Khoryfatul Munawaroh, dosen Program Studi Rekayasa Kehutanan, '
                'Institut Teknologi Sumatera (ITERA). '
                'Aplikasi ini dikembangkan oleh Fadiel Nurdiansyah, mahasiswa Program Studi '
                'Teknik Informatika, dengan dukungan data dari Yongki Saputra dan '
                'Awalinda Riski Aina, mahasiswa Program Studi Rekayasa Kehutanan.',
            textAlign: TextAlign.justify,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),


          // Email
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              const Icon(Icons.email_outlined, size: 16),
              SelectableText(
                'rekayasa.kehutanan@itera.ac.id',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Website (BISA DI COPY)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.public, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: SelectableText(
                  'https://rh.itera.ac.id/',
                  style: theme.textTheme.bodySmall
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 4),

          Text(
            '© 2025 Green Guide. All rights reserved.',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
