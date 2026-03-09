import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_record.dart';
import '../services/data_service.dart';
import 'navscreen.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _service = DataService.instance;
  final _auth = FirebaseAuth.instance;
  User? _user;
  bool _loading = true;
  String? _localSuggestionId;
  String? _role; // 'admin', 'super_admin', or null

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Anonymous auth
      if (_auth.currentUser == null) {
        final cred = await _auth.signInAnonymously();
        _user = cred.user;
      } else {
        _user = _auth.currentUser;
      }

      // Role detection
      if (_user != null && !_user!.isAnonymous) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('admins')
              .doc(_user!.uid)
              .get();

          if (doc.exists) {
            final r = doc.data()?['role'];
            if (r == 'admin' || r == 'super_admin') {
              _role = r;
            }
          }
        } catch (_) {}
      }

      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('suggestion_id');

      if (stored != null && stored.isNotEmpty) {
        final s = await _service.getSuggestionById(stored);

        // Cek apakah saran masih ada DAN milik device ini (tidak peduli userId)
        if (s == null) {
          // Saran sudah dihapus, bersihkan local storage
          await prefs.remove('suggestion_id');
          _localSuggestionId = null;
        } else {
          // Saran masih ada, device ini sudah pernah submit
          _localSuggestionId = stored;
        }
      } else {
        _localSuggestionId = null;
      }
    } catch (e) {
      print("INIT ERROR: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openForm({SuggestionRecord? suggestion}) {
    final idToLoad = (_localSuggestionId != null && suggestion == null) ? _localSuggestionId : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: _SuggestionForm(
            suggestion: suggestion,
            suggestionId: idToLoad,
            onCreated: (id) async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('suggestion_id', id);
              setState(() => _localSuggestionId = id);
            },
            onDeleted: (id) async {
              final prefs = await SharedPreferences.getInstance();
              final stored = prefs.getString('suggestion_id');
              if (stored == id) {
                await prefs.remove('suggestion_id');
                setState(() => _localSuggestionId = null);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(SuggestionRecord s) async {
    final prefs = await SharedPreferences.getInstance();

    // HANYA ADMIN YANG BISA DELETE (bukan device owner)
    final canDelete = (_role == 'admin');

    if (!canDelete) return;

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

    await _service.deleteSuggestion(s.id);

    final storedId = prefs.getString('suggestion_id');
    if (storedId == s.id) {
      await prefs.remove('suggestion_id');
      setState(() => _localSuggestionId = null);
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saran dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      drawer: const NavScreen(currentPage: 'suggestions'),
      appBar: AppBar(title: const Text('Saran & Masukan')),
      floatingActionButton: (_localSuggestionId == null && _role != 'super_admin')
          ? FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_comment),
      )
          : null,
      body: StreamBuilder<List<SuggestionRecord>>(
        stream: _service.streamSuggestions(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
          final data = snap.data ?? [];
          if (data.isEmpty) return const Center(child: Text('Belum ada saran'));

          data.sort((a, b) {
            if (_localSuggestionId == a.id) return -1;
            if (_localSuggestionId == b.id) return 1;
            return b.createdAt.compareTo(a.createdAt);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: data.length,
            itemBuilder: (ctx, i) {
              final s = data[i];
              // HANYA ADMIN YANG BISA DELETE (bukan device owner)
              final canDelete = (_role == 'admin');
              final showDelete = canDelete && (_role != 'super_admin'); // super admin read-only

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text(s.message),
                  trailing: showDelete
                      ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(s),
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SuggestionForm extends StatefulWidget {
  final SuggestionRecord? suggestion;
  final String? suggestionId;
  final void Function(String id)? onCreated;
  final void Function(String id)? onDeleted;

  const _SuggestionForm({this.suggestion, this.suggestionId, this.onCreated, this.onDeleted});

  @override
  State<_SuggestionForm> createState() => _SuggestionFormState();
}

class _SuggestionFormState extends State<_SuggestionForm> {
  final _service = DataService.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _angkatan = TextEditingController();
  final _message = TextEditingController();
  bool _loading = false;
  bool _initialLoading = false;
  SuggestionRecord? _loaded;

  @override
  void initState() {
    super.initState();
    if (widget.suggestion != null) {
      _populate(widget.suggestion!);
    } else if (widget.suggestionId != null) {
      _load(widget.suggestionId!);
    }
  }

  void _populate(SuggestionRecord s) {
    _loaded = s;
    _name.text = s.name;
    _angkatan.text = s.angkatan;
    _message.text = s.message;
  }

  Future<void> _load(String id) async {
    setState(() => _initialLoading = true);
    final s = await _service.getSuggestionById(id);
    if (s != null) _populate(s);
    if (mounted) setState(() => _initialLoading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      User? user = _auth.currentUser;
      user ??= (await _auth.signInAnonymously()).user;
      if (user == null) throw Exception('Auth failed');

      if (_loaded == null) {
        final id = await _service.addSuggestion(
          SuggestionRecord(
            id: '',
            userId: user.uid,
            name: _name.text.trim(),
            angkatan: _angkatan.text.trim(),
            message: _message.text.trim(),
            createdAt: DateTime.now(),
          ),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('suggestion_id', id);
        widget.onCreated?.call(id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saran dikirim')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit tidak didukung untuk saran')));
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 12, left: 16, right: 16, top: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_initialLoading) const Padding(padding: EdgeInsets.all(8.0), child: Center(child: CircularProgressIndicator())),
                  Text(widget.suggestion == null ? 'Kirim Saran' : 'Saran Anda', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(labelText: 'Nama'),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Nama wajib diisi';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _angkatan,
                          decoration: const InputDecoration(labelText: 'Angkatan'),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Angkatan wajib diisi';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _message,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(hintText: 'Tulis saran atau masukan Anda...'),
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Kirim'),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
