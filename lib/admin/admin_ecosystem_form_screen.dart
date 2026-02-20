import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'admin_activity_logger.dart';

class AdminEcosystemFormScreen extends StatefulWidget {
  const AdminEcosystemFormScreen({Key? key}) : super(key: key);

  static const routeName = '/admin/ecosystem-form';

  @override
  State<AdminEcosystemFormScreen> createState() =>
      _AdminEcosystemFormScreenState();
}

class _AdminEcosystemFormScreenState
    extends State<AdminEcosystemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;

  String _ecosystem = 'Mangrove';
  String? _docId;

  // ===== AUTO ID =====
  final _ecoIdC = TextEditingController();
  int _ecoNumber = 0;

  // ===== MANGROVE =====
  String? _substratValue;
  String? _salinitasValue;
  String? _jenisMangroveValue;
  String? _lokasiPasangSurutValue;

  // ===== DATARAN RENDAH =====
  final _ketinggianC = TextEditingController();
  final _curahHujanC = TextEditingController();
  final _intensitasCahayaC = TextEditingController();
  final _suhuUdaraC = TextEditingController();
  final _phTanahC = TextEditingController();

  // ===== UMUM =====
  final _rekomendasiC = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is String) {
        _docId = args;
        await _loadData();
      } else {
        await _generateEcoId();
      }

      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _ecoIdC.dispose();
    _ketinggianC.dispose();
    _curahHujanC.dispose();
    _intensitasCahayaC.dispose();
    _suhuUdaraC.dispose();
    _phTanahC.dispose();
    _rekomendasiC.dispose();
    super.dispose();
  }

  // ================= AUTO ID =================
  Future<void> _generateEcoId() async {
    final prefix = _ecosystem == 'Mangrove' ? 'M' : 'DR';

    final snap = await FirebaseFirestore.instance
        .collection('ecosystems')
        .where('ecosystem', isEqualTo: _ecosystem)
        .get();

    final usedNumbers = <int>{};

    for (final d in snap.docs) {
      final n = d.data()['ecoNumber'];
      if (n is int) usedNumbers.add(n);
    }

    int next = 1;
    while (usedNumbers.contains(next)) {
      next++;
    }

    _ecoNumber = next;
    _ecoIdC.text = '$prefix-${next.toString().padLeft(3, '0')}';
  }

  // ================= LOAD =================
  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('ecosystems')
        .doc(_docId)
        .get();

    final d = doc.data();
    if (d == null) return;

    _ecosystem = d['ecosystem'];
    _ecoNumber = d['ecoNumber'];
    _ecoIdC.text = d['ecoId'];

    if (_ecosystem == 'Mangrove') {
      _substratValue = d['substrat'];
      _salinitasValue = d['salinitas'];
      _jenisMangroveValue = d['jenis_ekosistem_mangrove'];
      _lokasiPasangSurutValue = d['lokasi_pasang_surut'];
    } else {
      _ketinggianC.text = d['ketinggian'] ?? '';
      _curahHujanC.text = d['curah_hujan'] ?? '';
      _intensitasCahayaC.text = d['intensitas_cahaya'] ?? '';
      _suhuUdaraC.text = d['suhu_udara'] ?? '';
      _phTanahC.text = d['ph_tanah'] ?? '';
    }

    _rekomendasiC.text = d['rekomendasi_jenis'] ?? '';
  }

  // ================= SAVE =================
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final firestore = FirebaseFirestore.instance;
    final ref = firestore.collection('ecosystems');

    final data = {
      'ecoId': _ecoIdC.text,
      'ecoNumber': _ecoNumber,
      'ecosystem': _ecosystem,
      'rekomendasi_jenis': _rekomendasiC.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_ecosystem == 'Mangrove') {
      data.addAll({
        'substrat': _substratValue!,
        'salinitas': _salinitasValue!,
        'jenis_ekosistem_mangrove': _jenisMangroveValue!,
        'lokasi_pasang_surut': _lokasiPasangSurutValue!,
      });
    } else {
      data.addAll({
        'ketinggian': _ketinggianC.text.trim(),
        'curah_hujan': _curahHujanC.text.trim(),
        'intensitas_cahaya': _intensitasCahayaC.text.trim(),
        'suhu_udara': _suhuUdaraC.text.trim(),
        'ph_tanah': _phTanahC.text.trim(),
      });
    }

    final existSnap = await ref
        .where('ecoId', isEqualTo: _ecoIdC.text)
        .limit(1)
        .get();

    // ================= EDIT =================
    if (_docId != null) {
      await ref.doc(_docId).update(data);

      await AdminActivityLogger.log(
        action: 'update',
        ecoId: _ecoIdC.text,
        ecosystem: _ecosystem,
      );
    }

    // ================= PREVENT DOUBLE =================
    else if (existSnap.docs.isNotEmpty) {
      final docId = existSnap.docs.first.id;

      await ref.doc(docId).update(data);

      await AdminActivityLogger.log(
        action: 'update',
        ecoId: _ecoIdC.text,
        ecosystem: _ecosystem,
      );
    }

    // ================= CREATE =================
    else {
      await ref.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await AdminActivityLogger.log(
        action: 'create',
        ecoId: _ecoIdC.text,
        ecosystem: _ecosystem,
      );
    }

    if (!mounted) return;
    Navigator.pop(context);
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
        title:
        Text(_docId == null ? 'Tambah Data Ekosistem' : 'Edit Data Ekosistem'),
        backgroundColor: Colors.green[700],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _ecoIdC,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'ID Ekosistem'),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _ecosystem,
              decoration:
              const InputDecoration(labelText: 'Jenis Ekosistem'),
              items: const [
                DropdownMenuItem(value: 'Mangrove', child: Text('Mangrove')),
                DropdownMenuItem(
                    value: 'Dataran Rendah',
                    child: Text('Dataran Rendah')),
              ],
              onChanged: _docId != null
                  ? null
                  : (v) async {
                setState(() => _ecosystem = v!);
                await _generateEcoId();
              },
            ),

            const SizedBox(height: 24),

            if (_ecosystem == 'Mangrove') ...[
              _dropdown(
                label: 'Substrat',
                value: _substratValue,
                items: const ['LUMPUR', 'PASIR', 'KARANG'],
                onChanged: (v) => setState(() => _substratValue = v),
              ),
              _dropdown(
                label: 'Salinitas',
                value: _salinitasValue,
                items: const ['< 3', '3 - 16', '16 - 25', '25 - 30', '> 30'],
                onChanged: (v) => setState(() => _salinitasValue = v),
              ),
              _dropdown(
                label: 'Jenis Ekosistem Mangrove',
                value: _jenisMangroveValue,
                items: const [
                  'Mangrove Sejati / Mayor',
                  'Mangrove Minor',
                  'Mangrove Asosiasi',
                ],
                onChanged: (v) =>
                    setState(() => _jenisMangroveValue = v),
              ),
              _dropdown(
                label: 'Lokasi Pasang Surut',
                value: _lokasiPasangSurutValue,
                items: const [
                  'Mangrove Terbuka',
                  'Mangrove Tengah',
                  'Mangrove Payau',
                  'Zona Depan',
                ],
                onChanged: (v) =>
                    setState(() => _lokasiPasangSurutValue = v),
              ),
            ],

            if (_ecosystem == 'Dataran Rendah') ...[
              _dropdown(
                label: 'Ketinggian Tempat (m dpl)',
                value: _ketinggianC.text.isEmpty ? null : _ketinggianC.text,
                items: const ['<100', '101 - 500', '501 - 1000'],
                onChanged: (v) =>
                    setState(() => _ketinggianC.text = v ?? ''),
              ),
              _dropdown(
                label: 'Curah Hujan (mm/bulan)',
                value: _curahHujanC.text.isEmpty ? null : _curahHujanC.text,
                items: const [
                  'Rendah 0 - 100',
                  'Menengah 101 - 300',
                  'Tinggi 301 - 500',
                  'Sangat Tinggi > 500',
                ],
                onChanged: (v) =>
                    setState(() => _curahHujanC.text = v ?? ''),
              ),
              _dropdown(
                label: 'Intensitas Cahaya (lux)',
                value: _intensitasCahayaC.text.isEmpty
                    ? null
                    : _intensitasCahayaC.text,
                items: const ['<3000', '3000 - 6000', '>6000'],
                onChanged: (v) =>
                    setState(() => _intensitasCahayaC.text = v ?? ''),
              ),
              _dropdown(
                label: 'Suhu Udara (°C)',
                value: _suhuUdaraC.text.isEmpty ? null : _suhuUdaraC.text,
                items: const ['<25', '25.1 - 30', '>30'],
                onChanged: (v) =>
                    setState(() => _suhuUdaraC.text = v ?? ''),
              ),
              _dropdown(
                label: 'pH Tanah',
                value: _phTanahC.text.isEmpty ? null : _phTanahC.text,
                items: const [
                  '<4.5',
                  '4.5 - 5.5',
                  '5.6 - 6.5',
                  '6.6 - 7.5',
                  '7.6 - 8.5',
                  '>8.5',
                ],
                onChanged: (v) =>
                    setState(() => _phTanahC.text = v ?? ''),
              ),
            ],

            RekomendasiField(
              key: const ValueKey('rekomendasi-field'),
              controller: _rekomendasiC,
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const CircularProgressIndicator()
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HELPER =================
  Widget _field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: c,
      decoration: InputDecoration(labelText: label),
      validator: (v) =>
      v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
    ),
  );

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(labelText: label),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
          validator: (v) => v == null ? 'Wajib dipilih' : null,
        ),
      );
}
class RekomendasiField extends StatelessWidget {
  final TextEditingController controller;

  const RekomendasiField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
        textInputAction: TextInputAction.newline,
        decoration: const InputDecoration(
          labelText: 'Rekomendasi',
        ),
        validator: (v) =>
        v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
      ),
    );
  }
}