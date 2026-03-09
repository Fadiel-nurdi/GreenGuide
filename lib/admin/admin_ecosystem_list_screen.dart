import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_nav.dart';
import 'admin_ecosystem_form_screen.dart';
import 'admin_activity_logger.dart';

class AdminEcosystemListScreen extends StatefulWidget {
  const AdminEcosystemListScreen({super.key});

  static const routeName = '/admin/ecosystems';

  @override
  State<AdminEcosystemListScreen> createState() =>
      _AdminEcosystemListScreenState();
}

class _AdminEcosystemListScreenState
    extends State<AdminEcosystemListScreen> {

  final _ecoRef = FirebaseFirestore.instance.collection('ecosystems');

  final _border =
  TableBorder.all(color: Colors.grey.shade400, width: 1);

  // ================= SORT ORDER MAP =================
  final Map<String, int> _substratOrder = {
    'LUMPUR': 1,
    'PASIR': 2,
    'KARANG': 3,
  };

  final Map<String, int> _salinitasOrder = {
    '<3': 1,
    '3 - 16': 2,
    '16 - 25': 3,
    '25 - 30': 4,
    '>30': 5,
  };

  final Map<String, int> _ketinggianOrder = {
    '<100': 1,
    '101 - 500': 2,
    '501 - 1000': 3,
  };

  final Map<String, int> _curahHujanOrder = {
    'Rendah 0 - 100': 1,
    'Menengah 101 - 300': 2,
    'Tinggi 301 - 500': 3,
    'Sangat Tinggi >500': 4,
  };

  final Map<String, int> _cahayaOrder = {
    '<3000': 1,
    '3000 - 6000': 2,
    '>6000': 3,
  };

  final Map<String, int> _suhuOrder = {
    '<25': 1,
    '25.1 - 30': 2,
    '>30': 3,
  };

  final Map<String, int> _phOrder = {
    '<4.5': 1,
    '4.5 - 5.5': 2,
    '5.6 - 6.5': 3,
    '6.6 - 7.5': 4,
    '7.6 - 8.5': 5,
    '>8.5': 6,
  };

  // ================= ID COMPARATOR =================
  int _compareEcoId(dynamic a, dynamic b) {
    final na = int.tryParse(a?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
    final nb = int.tryParse(b?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 0;
    return na.compareTo(nb);
  }
  List<Map<String, dynamic>> _groupMangrove(
      List<Map<String, dynamic>> data,
      ) {
    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final e in data) {
      final key = e['substrat']?.toString() ?? '-';
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(e);
    }

    final orderedKeys = _substratOrder.keys.toList();

    final List<Map<String, dynamic>> result = [];
    for (final k in orderedKeys) {
      if (groups.containsKey(k)) {
        result.addAll(groups[k]!);
      }
    }

    return result;
  }
  List<Map<String, dynamic>> _groupDataran(
      List<Map<String, dynamic>> data,
      ) {
    final Map<String, List<Map<String, dynamic>>> groups = {};

    for (final e in data) {
      final key = e['ketinggian']?.toString() ?? '-';
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(e);
    }

    final orderedKeys = _ketinggianOrder.keys.toList();

    final List<Map<String, dynamic>> result = [];
    for (final k in orderedKeys) {
      if (groups.containsKey(k)) {
        result.addAll(groups[k]!);
      }
    }

    return result;
  }
  // ================= ROLE GUARD =================
  Future<bool> _canAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final snap = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();

    final role = snap.data()?['role'];
    return role == 'admin' || role == 'super_admin';
  }

  // ================= CONFIRM =================
  Future<bool?> _confirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  // ================= DELETE =================
  Future<void> _deleteEcosystem(
      BuildContext context, String docId) async {
    final ok = await _confirm(context);
    if (ok != true) return;

    final snap = await _ecoRef.doc(docId).get();
    final data = snap.data();

    await _ecoRef.doc(docId).delete();

    if (data != null) {
      await AdminActivityLogger.log(
        action: 'delete',
        ecoId: data['ecoId'] ?? '-',
        ecosystem: data['ecosystem'] ?? '-',
      );
    }

    if (!mounted) return;
    _showSuccess(context, 'Data berhasil dihapus');
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _canAccess(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snap.data != true) {
          return const Scaffold(
              body: Center(child: Text('Anda tidak memiliki akses')));
        }

        return Scaffold(
          drawer: const AdminNav(),
          appBar: AppBar(
            title: const Text('Kelola Ekosistem'),
            backgroundColor: Colors.green[700],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.green[700],
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AdminEcosystemFormScreen.routeName,
              );
            },
          ),
          body: _buildEcosystemList(),
        );
      },
    );
  }

  // ================= JUDUL TABEL (BARU) =================
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

  // ================= ECOSYSTEM LIST =================
  Widget _buildEcosystemList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _ecoRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Center(child: Text('Data ekosistem masih kosong'));
        }

        final mangrove = <Map<String, dynamic>>[];
        final dataran = <Map<String, dynamic>>[];

        for (final d in snap.data!.docs) {
          final data = d.data();
          data['docId'] = d.id;

          final eco = data['ecosystem']?.toString().trim().toLowerCase();

          if (eco == 'mangrove') {
            mangrove.add(data);
          } else if (eco == 'dataran rendah') {
            dataran.add(data);
          }
        }

        // SORTING (tetap)
        mangrove.sort((a, b) {
          final id = _compareEcoId(a['ecoId'], b['ecoId']);
          if (id != 0) return id;
          return 0;
        });

        final groupedMangrove = _groupMangrove(mangrove);


        dataran.sort((a, b) {
          final id = _compareEcoId(a['ecoId'], b['ecoId']);
          if (id != 0) return id;
          return 0;
        });

        final groupedDataran = _groupDataran(dataran);


        return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // ⬅️ PENTING
            children: [
              if (mangrove.isEmpty && dataran.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('Data tidak terbaca, cek field ecosystem'),
                  ),
                ),

              if (mangrove.isNotEmpty) ...[
                _tableTitle('Ekosistem Mangrove'),
                _tableMangrove(context, groupedMangrove),
              ],

              if (dataran.isNotEmpty) ...[
                const SizedBox(height: 32),
                _tableTitle('Ekosistem Dataran Rendah'),
                _tableDataran(context, groupedDataran),
              ],
            ]
        );
      },
    );
  }


  // ================= TABLE =================
  Widget _tableMangrove(
      BuildContext context, List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox();
    return _buildTable(data, true);
  }

  Widget _tableDataran(
      BuildContext context, List<Map<String, dynamic>> data) {
    if (data.isEmpty) return const SizedBox();
    return _buildTable(data, false);
  }

  Widget _buildTable(
      List<Map<String, dynamic>> data, bool mangrove) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65, // ⬅️ BATAS TINGGI
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical, // ⬅️ SCROLL KE BAWAH
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // ⬅️ SCROLL KE SAMPING
            child: DataTable(
              border: _border,
              headingRowColor:
              WidgetStateProperty.all(Colors.green.shade100),
              columns: mangrove
                  ? const [
                DataColumn(label: Text('No')),
                DataColumn(label: Text('Substrat')),
                DataColumn(label: Text('Salinitas')),
                DataColumn(label: Text('Jenis')),
                DataColumn(label: Text('Lokasi')),
                DataColumn(label: Text('Rekomendasi')),
                DataColumn(label: Text('Aksi')),
              ]
                  : const [
                DataColumn(label: Text('No')),
                DataColumn(label: Text('Ketinggian')),
                DataColumn(label: Text('Curah Hujan')),
                DataColumn(label: Text('Cahaya')),
                DataColumn(label: Text('Suhu')),
                DataColumn(label: Text('pH')),
                DataColumn(label: Text('Rekomendasi')),
                DataColumn(label: Text('Aksi')),
              ],
              rows: List.generate(data.length, (i) {
                final e = data[i];
                return DataRow(
                  cells: mangrove
                      ? [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text(e['substrat'] ?? '-')),
                    DataCell(Text(e['salinitas'] ?? '-')),
                    DataCell(Text(
                        e['jenis_ekosistem_mangrove'] ?? '-')),
                    DataCell(Text(
                        e['lokasi_pasang_surut'] ?? '-')),
                    DataCell(Text(
                        e['rekomendasi_jenis'] ?? '-')),
                    DataCell(
                        _actionsEco(context, e['docId'])),
                  ]
                      : [
                    DataCell(Text('${i + 1}')),
                    DataCell(Text(e['ketinggian'] ?? '-')),
                    DataCell(Text(e['curah_hujan'] ?? '-')),
                    DataCell(
                        Text(e['intensitas_cahaya'] ?? '-')),
                    DataCell(Text(e['suhu_udara'] ?? '-')),
                    DataCell(Text(e['ph_tanah'] ?? '-')),
                    DataCell(Text(
                        e['rekomendasi_jenis'] ?? '-')),
                    DataCell(
                        _actionsEco(context, e['docId'])),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }


  Widget _actionsEco(BuildContext context, String docId) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.orange),
          onPressed: () {
            Navigator.pushNamed(
              context,
              AdminEcosystemFormScreen.routeName,
              arguments: docId,
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteEcosystem(context, docId),
        ),
      ],
    );
  }
}