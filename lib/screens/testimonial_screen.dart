import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_service.dart';
import '../models/data_record.dart';
import '../screens/navscreen.dart';

class TestimonialScreen extends StatefulWidget {
  const TestimonialScreen({super.key});

  @override
  State<TestimonialScreen> createState() => _TestimonialScreenState();
}

class _TestimonialScreenState extends State<TestimonialScreen> {
  final _service = DataService.instance;
  final _auth = FirebaseAuth.instance;

  User? _user;
  bool _loadingAuth = true;

  String? _localTestimonialId; // stored per-device testimonial id

  // ================= INIT ANONYMOUS USER =================
  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      if (_auth.currentUser != null) {
        _user = _auth.currentUser;
      } else {
        // Ensure an anonymous identity exists per device. This identity persists
        // across app restarts unless the app data is cleared.
        final cred = await _auth.signInAnonymously();
        _user = cred.user;
      }

      // Load per-device stored testimonial id
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('testimonial_id');
      if (stored != null && stored.isNotEmpty) {
        // verify referenced testimonial still belongs to this device/user
        final t = await _service.getTestimonialById(stored);
        if (t == null) {
          // stale id, clear
          await prefs.remove('testimonial_id');
        } else if (t.userId != (_user?.uid ?? '')) {
          // If the stored testimonial doesn't match current auth uid, clear it
          await prefs.remove('testimonial_id');
        } else {
          _localTestimonialId = stored;
        }
      }
    } catch (e) {
      _user = null;
    } finally {
      if (mounted) {
        setState(() => _loadingAuth = false);
      }
    }
  }


  void _openForm({TestimonialRecord? testimonial}) async {
    // Pass testimonialId to the form and open bottom sheet immediately so we
    // don't block the UI waiting for network/disk I/O (fixes keyboard lag).
    final idToLoad = (_localTestimonialId != null && testimonial == null) ? _localTestimonialId : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: _TestimonialForm(
                  testimonial: testimonial,
                  testimonialId: idToLoad,
                  onCreated: (id) async {
                    // Save per-device id
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('testimonial_id', id);
                    setState(() => _localTestimonialId = id);
                  },
                  onDeleted: (id) async {
                    // If deleted, clear local key
                    final prefs = await SharedPreferences.getInstance();
                    final stored = prefs.getString('testimonial_id');
                    if (stored == id) {
                      await prefs.remove('testimonial_id');
                      setState(() => _localTestimonialId = null);
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
  Future<void> _confirmDelete(TestimonialRecord t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Testimoni'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus testimoni ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteTestimonial(t.id);

      // update stats (best-effort)
      try {
        await _service.updateStatsOnDelete(t.rating);
      } catch (e) {
        print('updateStatsOnDelete failed: $e');
      }

      // clear local device flag if matches
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('testimonial_id');
      if (stored == t.id) {
        await prefs.remove('testimonial_id');
        setState(() => _localTestimonialId = null);
      }


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testimoni berhasil dihapus')),
        );
      }
    }
  }

  // ================= BUILD (HANYA SATU) =================
  @override
  Widget build(BuildContext context) {
    if (_loadingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userId = _user?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Gagal memuat user')),
      );
    }

    return Scaffold(
      drawer: const NavScreen(currentPage: 'testimoni'),
      appBar: AppBar(
        title: const Text('Testimoni Pengguna'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [

          // ⭐ RINGKASAN BINTANG
          StreamBuilder<Map<String, dynamic>>(
            stream: _service.streamTestimonialStats(),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const SizedBox();
              }

              final data = snap.data!;
              final avg = (data['average'] ?? 0).toDouble();
              final total = data['totalReviews'] ?? 0;

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StarRating(rating: avg.round()),
                        Text('$total ulasan'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          // 📋 DAFTAR TESTIMONI
          Expanded(
            child: StreamBuilder<List<TestimonialRecord>>(
              stream: _service.streamTestimonials(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snap.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('Belum ada testimoni'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    90, // ⬅️ INI KUNCINYA (ruang untuk tombol +)
                  ),
                  itemCount: data.length,
                  itemBuilder: (_, i) {
                    final t = data[i];
                    final isMine = t.userId == userId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${t.name} • Angkatan ${t.angkatan}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                StarRating(rating: t.rating),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(t.message),
                            if (isMine) ...[
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Edit Testimoni'),
                                          content: const Text(
                                            'Apakah Anda ingin mengedit testimoni ini?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Edit'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        _openForm(testimonial: t);
                                      }
                                    },
                                    child: const Text('Edit'),
                                  ),
                                  TextButton(
                                    onPressed: () => _confirmDelete(t),
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// ======================= BOTTOM SHEET FORM ==========================
// ===================================================================

class _TestimonialForm extends StatefulWidget {
  final TestimonialRecord? testimonial;
  final String? testimonialId; // load async inside form if provided
  final void Function(String id)? onCreated;
  final void Function(String id)? onDeleted;
  const _TestimonialForm({this.testimonial, this.testimonialId, this.onCreated, this.onDeleted});

  @override
  State<_TestimonialForm> createState() => _TestimonialFormState();
}

class _TestimonialFormState extends State<_TestimonialForm> {
  final _service = DataService.instance;
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _angkatanCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  int _rating = 5;
  bool _saving = false;
  bool _loadingInitial = false;
  TestimonialRecord? _loadedTestimonial;

  @override
  void initState() {
    super.initState();
    if (widget.testimonial != null) {
      _populateFrom(widget.testimonial!);
    } else if (widget.testimonialId != null) {
      // Load asynchronously but do not block UI; show progress indicator if desired
      _loadTestimonial(widget.testimonialId!);
    }
  }

  void _populateFrom(TestimonialRecord t) {
    _loadedTestimonial = t;
    _nameCtrl.text = t.name;
    _angkatanCtrl.text = t.angkatan;
    _messageCtrl.text = t.message;
    _rating = t.rating;
  }

  Future<void> _loadTestimonial(String id) async {
    setState(() => _loadingInitial = true);
    try {
      final t = await _service.getTestimonialById(id);
      if (t != null) {
        _populateFrom(t);
      }
    } catch (e) {
      print('Failed to load testimonial in form: $e');
    } finally {
      if (mounted) setState(() => _loadingInitial = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return; // ⬅️ validasi form muncul di DALAM bottom sheet
    }

    setState(() => _saving = true);

    try {
      User? user = _auth.currentUser;
      user ??= (await _auth.signInAnonymously()).user;
      if (user == null) return;

      final name = _nameCtrl.text.trim();
      final angkatan = int.parse(_angkatanCtrl.text.trim());
      final message = _messageCtrl.text.trim();

      final isEditing = (widget.testimonial != null) || (_loadedTestimonial != null);

      if (!isEditing) {
        final id = await _service.addTestimonial(
          TestimonialRecord(
            id: '',
            userId: user.uid,
            name: name,
            angkatan: angkatan.toString(),
            rating: _rating,
            message: message,
            createdAt: DateTime.now(),
          ),
        );

        // Save id locally so device can only submit once
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('testimonial_id', id);

        if (mounted) {
          widget.onCreated?.call(id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Testimoni berhasil ditambahkan')),
          );
        }
      } else {
        final idToUpdate = widget.testimonial?.id ?? _loadedTestimonial?.id;
        if (idToUpdate != null) {
          await _service.updateTestimonial(
            idToUpdate,
            message,
            _rating,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Testimoni berhasil diperbarui')),
          );
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final idToDelete = widget.testimonial?.id ?? _loadedTestimonial?.id;
    if (idToDelete == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Testimoni'),
        content: const Text('Anda yakin ingin menghapus testimoni ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _service.deleteTestimonial(idToDelete);

      // clear local saved id if matches
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('testimonial_id');
      if (stored == idToDelete) {
        await prefs.remove('testimonial_id');
      }

      // update stats (best-effort)
      try {
        await _service.updateStatsOnDelete(widget.testimonial!.rating);
      } catch (e) {
        print('updateStatsOnDelete failed: $e');
      }

      if (mounted) {
        widget.onDeleted?.call(idToDelete);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Testimoni berhasil dihapus')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
        child: Form(
          key: _formKey,
          child: Column(
          mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingInitial) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          Text(
            widget.testimonial == null
                ? 'Tambah Testimoni'
                : 'Edit Testimoni',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nama'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Nama wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _angkatanCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Angkatan',
              helperText: 'Angkatan minimal 2013',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Angkatan wajib diisi';
              }
              final year = int.tryParse(v);
              if (year == null) return 'Angkatan harus berupa angka';
              if (year < 2013) return 'Angkatan minimal 2013';
              if (year > DateTime.now().year) return 'Angkatan tidak valid';
              return null;
            },
          ),


          StarRating(
            rating: _rating,
            onTap: (v) => setState(() => _rating = v),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _messageCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tulis pengalaman kamu...',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Pengalaman wajib diisi';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Simpan'),
                ),
              ),
              const SizedBox(width: 12),
              if (widget.testimonial != null)
                OutlinedButton(
                  onPressed: _saving ? null : _delete,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Hapus'),
                ),
            ],
          ),
        ],
      ),
        )
    );
  }
}


// ===================================================================
// ========================== STAR RATING =============================
// ===================================================================

class StarRating extends StatelessWidget {
  final int rating;
  final void Function(int)? onTap;

  const StarRating({
    super.key,
    required this.rating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            i < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
          onPressed: onTap == null ? null : () => onTap!(i + 1),
        );
      }),
    );
  }
}
