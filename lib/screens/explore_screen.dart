import 'package:flutter/material.dart';
import 'navscreen.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const Color bg = Color(0xFFF3F6E9); // krem lembut

    return Scaffold(
      backgroundColor: bg,

      // ================= DRAWER (GESER DARI KIRI) =================
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: NavScreen(currentPage: 'panduan'),
      ),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,

        // ⛔ MATIKAN BACK ARROW
        automaticallyImplyLeading: false,

        // ☰ MENU DI KIRI (WAJIB)
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),

        // ================= TITLE =================
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
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
      ),

      // ================= BODY (TIDAK DIUBAH) =================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              _HeaderTitle(),
              SizedBox(height: 12),
              _TeacherCard(),
              SizedBox(height: 24),
              _StepsSection(),
              SizedBox(height: 24),
              _GoalsAndBenefitsSection(),
              SizedBox(height: 24),
              _ContactSection(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// ================== JUDUL HALAMAN "Panduan" ==================
class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'Panduan penggunaan',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// ================== KARTU GURU / INTRO ==================
class _TeacherCard extends StatelessWidget {
  const _TeacherCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          // foto guru (dibuat flex:0 supaya tidak ikut melar)
          Flexible(
            flex: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/Images/teacher.jpeg', // path yang sudah benar
                width: 72,
                height: 92,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // teks (Expanded supaya menyesuaikan sisa lebar)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tujuan Penggunaan\nAplikasi Green Guide',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Panduan singkat bagi pengguna untuk memahami cara kerja aplikasi, '
                      'mulai dari memasukkan data lahan hingga membaca rekomendasi tanaman.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.35,
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

/// ================== TUJUAN & KEUNTUNGAN ==================
class _GoalsAndBenefitsSection extends StatelessWidget {
  const _GoalsAndBenefitsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB8D9A8),
              Color(0xFFC8E6B8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // judul utama
            Text(
              'Tujuan dan\nKeuntungan',
              style: theme.textTheme.titleLarge?.copyWith(
                color: const Color(0xFF2D5016),
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Green Guide membantu petani, siswa, dan pemerhati lingkungan '
                  'untuk memilih tanaman yang sesuai dengan karakteristik lahan.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF3D6B22),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            // kartu tujuan
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF7BA557).withOpacity(0.6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Tujuan\n'
                    '• Membantu pengguna memahami kondisi lahan.\n'
                    '• Menyajikan rekomendasi tanaman yang akurat.\n'
                    '• Menjadi bahan ajar praktikum informatika dan geografi.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // kartu keuntungan
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Keuntungan\n'
                    '• Tampilan sederhana dan mudah dipahami.\n'
                    '• Menggunakan data ekosistem yang jelas.\n'
                    '• Dapat digunakan di kelas maupun di lapangan.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF3D6B22),
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================== LANGKAH / POINT 01–04 ==================
class _StepsSection extends StatelessWidget {
  const _StepsSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item(int number, String title, String desc) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // nomor besar di kiri
            SizedBox(
              width: 52,
              child: Text(
                number.toString().padLeft(2, '0'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // teks di kanan
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
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        item(
          1,
          'Membaca kondisi lahan yang sudah ada',
          'Perhatikan jenis tanah, ketinggian, pH, dan curah hujan di wilayahmu.',
        ),
        item(
          2,
          'Masukkan data ke dalam fitur ekosistem',
          'Isi formulir yang tersedia pada aplikasi sesuai kondisi lahan sebenarnya.',
        ),
        item(
          3,
          'Lihat rekomendasi tanaman',
          'Aplikasi akan menampilkan daftar tanaman yang paling cocok untuk lahan tersebut.',
        ),
        item(
          4,
          'Gunakan sebagai bahan dokumentasi bersama',
          'Data yang dihasilkan dapat didiskusikan di kelas atau dengan kelompok tani.',
        ),
      ],
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
