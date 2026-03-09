import 'package:flutter/material.dart';
import 'navscreen.dart';

class EcosystemScreen extends StatelessWidget {
  const EcosystemScreen({super.key});

  static const Color _bgColor = Color(0xFFF3F6E9);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _bgColor,

      // ✅ DRAWER SLIDE DARI KIRI (SAMA KAYAK ADMIN)
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: NavScreen(currentPage: 'data'),
      ),

      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,

        // ✅ ICON ☰ DI KIRI (WAJIB)
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),

        title: Text(
          'Data Ekosistem',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroIntro(),
              SizedBox(height: 16),

              _EcosystemSection(
                title: 'Hutan Mangrove',
                imageAsset: 'assets/Images/mangroveset.jpg',
                description:
                'Hutan mangrove adalah ekosistem unik yang berada di zona pasang surut, '
                    'di sekitar muara, delta, dan pesisir. Hutan ini berfungsi sebagai '
                    'pelindung pantai dari abrasi, penahan gelombang, serta habitat bagi '
                    'berbagai jenis satwa. Mangrove juga membantu menyerap karbon dan '
                    'menjaga kualitas air di lingkungan pesisir.',
              ),

              SizedBox(height: 16),

              _EcosystemSection(
                title: 'Hutan Dataran Rendah',
                imageAsset: 'assets/Images/daratanrendah.jpg',
                description:
                'Hutan dataran rendah adalah ekosistem hutan yang terletak di wilayah '
                    'dengan ketinggian rendah. Hutan ini umumnya memiliki keanekaragaman '
                    'hayati yang tinggi, dengan berbagai jenis pohon, tumbuhan bawah, '
                    'serta satwa liar. Hutan dataran rendah berperan penting dalam menjaga '
                    'keseimbangan ekosistem, menyimpan sumber daya alam, dan menjadi paru-paru '
                    'wilayah sekitarnya.',
              ),
              SizedBox(height: 16),
              _AboutFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroIntro extends StatelessWidget {
  const _HeroIntro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/Images/teacher2.png',
              width: double.infinity,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Data Ekosistem',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            'Dalam penggunaan sistem, data diperlukan untuk mengidentifikasi '
                'dan mengolah informasi kondisi lahan sehingga menghasilkan '
                'rekomendasi tanaman yang sesuai.',
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.35,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _EcosystemSection extends StatelessWidget {
  final String title;
  final String imageAsset;
  final String description;

  const _EcosystemSection({
    required this.title,
    required this.imageAsset,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              imageAsset,
              width: double.infinity,
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            description,
            textAlign: TextAlign.justify,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutFooter extends StatelessWidget {
  const _AboutFooter();

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

/// ================= CARD WRAPPER =================
class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}