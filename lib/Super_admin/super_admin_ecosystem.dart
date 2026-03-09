import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'super_admin_nav.dart';

class SuperAdminEcosystemScreen extends StatelessWidget {
  const SuperAdminEcosystemScreen({super.key});

  static const routeName = '/super-admin/ecosystems';

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('ecosystems');

  TableBorder get _border =>
      TableBorder.all(color: Colors.grey.shade400, width: 1);
  int _compareEcoId(dynamic a, dynamic b) {
    final na = int.tryParse(
      a?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '',
    ) ?? 0;
    final nb = int.tryParse(
      b?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '',
    ) ?? 0;
    return na.compareTo(nb);
  }

  List<Map<String, dynamic>> _groupMangrove(List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final e in data) {
      final key = e['substrat']?.toString() ?? '-';
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(e);
    }

    const order = ['LUMPUR', 'PASIR', 'KARANG'];

    final List<Map<String, dynamic>> result = [];
    for (final k in order) {
      if (groups.containsKey(k)) {
        result.addAll(groups[k]!);
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _groupDataran(List<Map<String, dynamic>> data) {
    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final e in data) {
      final key = e['ketinggian']?.toString() ?? '-';
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(e);
    }

    const order = ['<100', '101 - 500', '501 - 1000'];

    final List<Map<String, dynamic>> result = [];
    for (final k in order) {
      if (groups.containsKey(k)) {
        result.addAll(groups[k]!);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F3),
      drawer: const SuperAdminNav(),

      appBar: AppBar(
        title: const Text('Monitoring Ekosistem'),
        backgroundColor: Colors.green[800],
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),

        body: SafeArea(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _ref.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Belum ada data ekosistem'),
            );
          }

          final mangrove = <Map<String, dynamic>>[];
          final dataran = <Map<String, dynamic>>[];

          for (final d in snapshot.data!.docs) {
            final data = d.data();
            if (data['ecosystem'] == 'Mangrove') {
              mangrove.add(data);
            } else if (data['ecosystem'] == 'Dataran Rendah') {
              dataran.add(data);
            }
          }

          // ================= NOMOR 3 (BENAR) =================
          mangrove.sort((a, b) => _compareEcoId(a['ecoId'], b['ecoId']));
          dataran.sort((a, b) => _compareEcoId(a['ecoId'], b['ecoId']));

          final groupedMangrove = _groupMangrove(mangrove);
          final groupedDataran = _groupDataran(dataran);

          // ================= NOMOR 4 (BENAR) =================
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(groupedMangrove.length, groupedDataran.length),
              const SizedBox(height: 24),

              if (groupedMangrove.isNotEmpty) ...[
                _tableTitle('Ekosistem Mangrove'),
                _tableMangrove(groupedMangrove),
                const SizedBox(height: 32),
              ],

              if (groupedDataran.isNotEmpty) ...[
                _tableTitle('Ekosistem Dataran Rendah'),
                _tableDataran(groupedDataran),
              ],
            ],
          );
        },
      ),
        )
    );
  }


  // ================= SUMMARY =================
  Widget _summaryCard(int mangrove, int dataran) {
    return Row(
      children: [
        _statBox('Mangrove', mangrove, Icons.forest),
        const SizedBox(width: 12),
        _statBox('Dataran Rendah', dataran, Icons.grass),
      ],
    );
  }

  Widget _statBox(String title, int value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title),
          ],
        ),
      ),
    );
  }

  // ================= JUDUL TABEL =================
  Widget _tableTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================= MANGROVE =================
  Widget _tableMangrove(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox();

    return SizedBox(
      height: 400, // ⬅️ BATASI TINGGI TABEL
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              border: _border,
              headingRowColor:
              MaterialStateProperty.all(Colors.green.shade100),
              columns: const [
                DataColumn(label: Text('No')),
                DataColumn(label: Text('Substrat')),
                DataColumn(label: Text('Salinitas')),
                DataColumn(label: Text('Jenis')),
                DataColumn(label: Text('Lokasi')),
                DataColumn(label: Text('Rekomendasi')),
              ],
              rows: List.generate(data.length, (i) {
                final e = data[i];
                return DataRow(cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(e['substrat'] ?? '-')),
                  DataCell(Text(e['salinitas'] ?? '-')),
                  DataCell(Text(e['jenis_ekosistem_mangrove'] ?? '-')),
                  DataCell(Text(e['lokasi_pasang_surut'] ?? '-')),
                  DataCell(Text(e['rekomendasi_jenis'] ?? '-')),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ================= DATARAN RENDAH =================
  Widget _tableDataran(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox();

    return SizedBox(
      height: 400,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              border: _border,
              headingRowColor:
              MaterialStateProperty.all(Colors.green.shade100),
              columns: const [
                DataColumn(label: Text('No')),
                DataColumn(label: Text('Ketinggian')),
                DataColumn(label: Text('Curah Hujan')),
                DataColumn(label: Text('Cahaya')),
                DataColumn(label: Text('Suhu')),
                DataColumn(label: Text('pH')),
                DataColumn(label: Text('Rekomendasi')),
              ],
              rows: List.generate(data.length, (i) {
                final e = data[i];
                return DataRow(cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(Text(e['ketinggian'] ?? '-')),
                  DataCell(Text(e['curah_hujan'] ?? '-')),
                  DataCell(Text(e['intensitas_cahaya'] ?? '-')),
                  DataCell(Text(e['suhu_udara'] ?? '-')),
                  DataCell(Text(e['ph_tanah'] ?? '-')),
                  DataCell(Text(e['rekomendasi_jenis'] ?? '-')),
                ]);
              }),
            ),
          ),
        ),
      ),
    );
  }
}
