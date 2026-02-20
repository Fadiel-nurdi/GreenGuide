import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_activity_logger.dart';

class AdminReferenceFormScreen extends StatefulWidget {
  const AdminReferenceFormScreen({super.key});

  static const routeName = '/admin/reference-form';

  @override
  State<AdminReferenceFormScreen> createState() =>
      _AdminReferenceFormScreenState();
}

class _AdminReferenceFormScreenState
    extends State<AdminReferenceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;

  String? _docId;

  // ===== FORM FIELD =====
  final _citationC = TextEditingController();
  final _yearC = TextEditingController();

  String _ecosystem = 'global';

  final ValueNotifier<bool> _isActiveN = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is String) {
        _docId = args;
        await _loadData();
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  @override
  void dispose() {
    _citationC.dispose();
    _yearC.dispose();
    _isActiveN.dispose(); // ✅ TAMBAH INI
    super.dispose();
  }

  // ================= LOAD (EDIT) =================
  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('references')
          .doc(_docId)
          .get();

      final d = doc.data();
      if (d == null) return;

      _citationC.text = d['citation'] ?? '';
      _ecosystem = d['ecosystem'] ?? 'global';
      _isActiveN.value = d['isActive'] ?? true;

      if (d['year'] != null) {
        _yearC.text = d['year'].toString();
      }
    } catch (e) {
      debugPrint('LOAD REFERENCE ERROR: $e');
    }
  }

  // ================= SAVE (FINAL FIX) =================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final ref =
      FirebaseFirestore.instance.collection('references');

      final Map<String, dynamic> data = {
        'citation': _citationC.text.trim(),
        'ecosystem': _ecosystem,
        'isActive': _isActiveN.value, // ✅ PAKAI NOTIFIER
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_yearC.text.trim().isNotEmpty) {
        final year = int.tryParse(_yearC.text.trim());
        if (year != null) {
          data['year'] = year;
        }
      }

      // ================= EDIT =================
      if (_docId != null) {
        await ref.doc(_docId).update(data);

        // ✅ LOG UPDATE REFERENCE
        await AdminActivityLogger.log(
          action: 'update',
          ecoId: 'REF',
          ecosystem: 'Daftar Pustaka',
        );
      }
      // ================= CREATE =================
      else {
        await ref.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ✅ LOG CREATE REFERENCE
        await AdminActivityLogger.log(
          action: 'create',
          ecoId: 'REF',
          ecosystem: 'Daftar Pustaka',
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('SAVE REFERENCE ERROR: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan daftar pustaka'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _docId == null
              ? 'Tambah Daftar Pustaka'
              : 'Edit Daftar Pustaka',
        ),
        backgroundColor: Colors.green[700],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== CITATION =====
            TextFormField(
              controller: _citationC,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Sitasi / Daftar Pustaka',
                alignLabelWithHint: true,
              ),
              validator: (v) =>
              v == null || v.trim().isEmpty
                  ? 'Wajib diisi'
                  : null,
            ),

            const SizedBox(height: 16),

            // ===== ECOSYSTEM =====
            DropdownButtonFormField<String>(
              value: _ecosystem,
              decoration:
              const InputDecoration(labelText: 'Kategori Ekosistem'),
              items: const [
                DropdownMenuItem(
                  value: 'global',
                  child: Text('Global (semua)'),
                ),
                DropdownMenuItem(
                  value: 'Mangrove',
                  child: Text('Mangrove'),
                ),
                DropdownMenuItem(
                  value: 'Dataran Rendah',
                  child: Text('Dataran Rendah'),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _ecosystem = v);
                }
              },
            ),

            const SizedBox(height: 16),

            // ===== YEAR =====
            TextFormField(
              controller: _yearC,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(
                labelText: 'Tahun (opsional)',
                hintText: 'Contoh: 2022',
              ),
            ),

            const SizedBox(height: 16),

            // ===== ACTIVE =====
            ValueListenableBuilder<bool>(
              valueListenable: _isActiveN,
              builder: (_, v, __) {
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktifkan referensi'),
                  value: v,
                  onChanged: (nv) => _isActiveN.value = nv,
                );
              },
            ),

            const SizedBox(height: 32),

            // ===== SAVE =====
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
