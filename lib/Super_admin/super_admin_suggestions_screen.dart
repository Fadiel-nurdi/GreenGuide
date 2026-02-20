import 'package:flutter/material.dart';

import '../models/data_record.dart';
import '../services/data_service.dart';
import 'super_admin_nav.dart';

class SuperAdminSuggestionsScreen extends StatelessWidget {
  static const routeName = '/super/suggestions';
  const SuperAdminSuggestionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _service = DataService.instance;

    return Scaffold(
      drawer: const SuperAdminNav(),
      appBar: AppBar(title: const Text('Saran & Masukan (Super Admin)')),
      body: StreamBuilder<List<SuggestionRecord>>(
        stream: _service.streamSuggestions(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final data = snap.data ?? [];
          if (data.isEmpty) return const Center(child: Text('Belum ada saran'));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (ctx, i) {
              final s = data[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}

