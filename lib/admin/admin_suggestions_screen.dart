import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/data_record.dart';
import '../services/data_service.dart';
import 'admin_nav.dart';

class AdminSuggestionsScreen extends StatefulWidget {
  static const routeName = '/admin/suggestions';
  const AdminSuggestionsScreen({Key? key}) : super(key: key);

  @override
  State<AdminSuggestionsScreen> createState() => _AdminSuggestionsScreenState();
}

class _AdminSuggestionsScreenState extends State<AdminSuggestionsScreen> {
  final _service = DataService.instance;
  bool _busy = false;

  Future<void> _confirmDelete(SuggestionRecord s) async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString('suggestion_id');
    final isOwnerByDevice = storedId == s.id;

    // Admin can always delete here (this screen only reachable for admins)
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Saran'),
        content: const Text('Apakah Anda yakin ingin menghapus saran ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok != true) return;

    try {
      setState(() => _busy = true);
      await _service.deleteSuggestion(s.id);
      if (storedId == s.id) await prefs.remove('suggestion_id');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saran dihapus')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminNav(),
      appBar: AppBar(title: const Text('Saran & Masukan (Admin)')),
      body: StreamBuilder<List<SuggestionRecord>>(
        stream: _service.streamSuggestions(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final data = snap.data ?? [];
          if (data.isEmpty) return const Center(child: Text('Belum ada saran'));

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final s = data[i];
              return Card(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.angkatan.isNotEmpty) Text('Angkatan: ${s.angkatan}'),
                      const SizedBox(height: 6),
                      Text(s.message),
                      const SizedBox(height: 6),
                      Text(
                        'Tanggal: ${s.createdAt.toLocal()}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: _busy
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(s),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

