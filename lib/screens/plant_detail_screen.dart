import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../models/plant.dart';

// 📚 Referensi statis
import '../data/mangrove_references.dart';
import '../data/dataran_rendah_references.dart';

class PlantDetailScreen extends ConsumerWidget {
  final String id;
  const PlantDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(recommendationServiceProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<Plant?>(
      future: service.getById(id),
      builder: (context, snap) {
        // ================= LOADING =================
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ================= ERROR =================
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Tanaman')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Terjadi error:\n${snap.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final p = snap.data;

        // ================= NOT FOUND =================
        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail Tanaman')),
            body: const Center(child: Text('Tanaman tidak ditemukan')),
          );
        }

        final isMangrove = p.landType.toLowerCase() == 'mangrove';

        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ================= IMAGE =================
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: (p.imageUrl != null && p.imageUrl!.trim().isNotEmpty)
                    ? Image.network(
                  p.imageUrl!.trim(),
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _imagePlaceholder(cs),
                )
                    : _imagePlaceholder(cs),
              ),

              const SizedBox(height: 16),

              // ================= TITLE =================
              Text(
                p.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p.latinName.trim().isEmpty ? '-' : p.latinName,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 16),

              // ================= SPEC =================
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _SpecRow(
                      label: 'Jenis Lahan',
                      value: _safe(p.landType),
                    ),
                    const Divider(height: 16),
                    _SpecRow(
                      label: 'Ketinggian',
                      value: '${p.minAltitude}–${p.maxAltitude} mdpl',
                    ),

                    // 🔥 pH hanya untuk NON-mangrove
                    if (!isMangrove) ...[
                      const Divider(height: 16),
                      _SpecRow(
                        label: 'pH Tanah',
                        value: '${p.minPH}–${p.maxPH}',
                      ),
                    ],

                    const Divider(height: 16),
                    _SpecRow(
                      label: 'Curah Hujan',
                      value:
                      '${p.minRainfall}–${p.maxRainfall} mm/tahun',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ================= DESCRIPTION =================
              Text(
                'Deskripsi',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                p.description.trim().isEmpty ? '-' : p.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),

              // ================= DAFTAR PUSTAKA =================
              if (isMangrove && mangroveReferences.isNotEmpty) ...[
                const SizedBox(height: 24),
                _referenceSection(
                  title: 'Daftar Pustaka (Mangrove)',
                  items: mangroveReferences,
                  theme: theme,
                ),
              ],

              if (!isMangrove &&
                  dataranRendahReferences.isNotEmpty) ...[
                const SizedBox(height: 24),
                _referenceSection(
                  title: 'Daftar Pustaka (Dataran Rendah)',
                  items: dataranRendahReferences,
                  theme: theme,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ================= HELPER =================

  static Widget _imagePlaceholder(ColorScheme cs) => Container(
    height: 210,
    width: double.infinity,
    color: cs.surfaceContainerHighest,
    alignment: Alignment.center,
    child: const Icon(Icons.local_florist, size: 64),
  );

  static Widget _referenceSection({
    required String title,
    required List<String> items,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
              (e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $e'),
          ),
        ),
      ],
    );
  }

  String _safe(String? s) {
    final v = (s ?? '').trim();
    return v.isEmpty ? '-' : v;
  }
}

class _SpecRow extends StatelessWidget {
  final String label;
  final String value;
  const _SpecRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.trim().isEmpty ? '-' : value,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
