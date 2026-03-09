import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_nav.dart';
import 'admin_reference_form_screen.dart';
import 'admin_activity_logger.dart';

class AdminReferenceListScreen extends StatefulWidget {
  const AdminReferenceListScreen({super.key});

  static const routeName = '/admin/references';

  @override
  State<AdminReferenceListScreen> createState() =>
      _AdminReferenceListScreenState();
}

class _AdminReferenceListScreenState
    extends State<AdminReferenceListScreen> {

  final _refRef =
  FirebaseFirestore.instance.collection('references');

  // ================= CONFIRM =================
  Future<bool?> _confirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Yakin ingin menghapus daftar pustaka ini?'),
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
  Future<void> _deleteReference(
      BuildContext context, String docId) async {
    final ok = await _confirm(context);
    if (ok != true) return;

    await _refRef.doc(docId).delete();

    await AdminActivityLogger.log(
      action: 'delete',
      ecoId: 'REF',
      ecosystem: 'Daftar Pustaka',
    );

    if (!mounted) return;
    _showSuccess(context, 'Daftar pustaka berhasil dihapus');
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminNav(),
      appBar: AppBar(
        title: const Text('Kelola Daftar Pustaka'),
        backgroundColor: Colors.green[700],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.pushNamed(
            context,
            AdminReferenceFormScreen.routeName,
          );
        },
      ),
      body: _buildReferenceList(),
    );
  }

  // ================= REFERENCE LIST =================
  Widget _buildReferenceList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _refRef.orderBy('ecosystem').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Belum ada daftar pustaka'));
        }

        final Map<String,
            List<QueryDocumentSnapshot<Map<String, dynamic>>>>
        grouped = {};

        for (final d in docs) {
          final eco = d.data()['ecosystem'] ?? 'Tidak diketahui';
          grouped.putIfAbsent(eco, () => []);
          grouped[eco]!.add(d);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: grouped.entries.map((entry) {
            final ecoName = entry.key;
            final items = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                  const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    _prettyEcoName(ecoName),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...items.map((d) {
                  final data = d.data();
                  return Card(
                    child: ListTile(
                      title: Text(data['citation'] ?? '-'),
                      subtitle: Text(
                        _buildReferenceMeta(data),
                        style:
                        const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.orange),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AdminReferenceFormScreen
                                    .routeName,
                                arguments: d.id,
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () =>
                                _deleteReference(
                                    context, d.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  String _prettyEcoName(String raw) {
    final v = raw.toLowerCase().trim();
    if (v == 'mangrove') return 'Ekosistem Mangrove';
    if (v == 'dataran rendah') return 'Ekosistem Dataran Rendah';
    if (v == 'global') return 'Referensi Umum';
    return raw;
  }

  String _buildReferenceMeta(Map<String, dynamic> data) {
    final year = data['year'];
    final active =
    data['isActive'] == true ? 'Aktif' : 'Nonaktif';

    if (year != null && year.toString().isNotEmpty) {
      return 'Tahun: $year • Status: $active';
    }
    return 'Status: $active';
  }
}