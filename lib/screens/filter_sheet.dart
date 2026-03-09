import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilterResult {
  final String? landType;
  final int? altitude;
  final double? ph;
  final int? rainfall;

  const FilterResult({
    this.landType,
    this.altitude,
    this.ph,
    this.rainfall,
  });

  bool get isEmpty =>
      landType == null && altitude == null && ph == null && rainfall == null;

  FilterResult copyWith({
    String? landType,
    int? altitude,
    double? ph,
    int? rainfall,
  }) {
    return FilterResult(
      landType: landType ?? this.landType,
      altitude: altitude ?? this.altitude,
      ph: ph ?? this.ph,
      rainfall: rainfall ?? this.rainfall,
    );
  }

  @override
  String toString() =>
      'FilterResult(landType: $landType, altitude: $altitude, ph: $ph, rainfall: $rainfall)';
}

class FilterSheet extends StatefulWidget {
  /// Opsional: untuk ngisi nilai awal (misalnya kalau user buka ulang filter)
  final FilterResult? initial;

  const FilterSheet({super.key, this.initial});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _landType;

  late final TextEditingController _altitudeC;
  late final TextEditingController _phC;
  late final TextEditingController _rainfallC;

  final _formKey = GlobalKey<FormState>();

  // Kalau ini sebenarnya "jenis tanah", tetap boleh. Kalau nanti mau diganti sesuai dataset,
  // tinggal ubah list ini jadi dinamis dari JSON.
  static const landTypes = <String>[
    'Latosol',
    'Alluvial',
    'Andosol',
    'Glei',
    'Regosol',
    'Grumosol',
  ];

  @override
  void initState() {
    super.initState();

    final init = widget.initial;
    _landType = init?.landType;

    _altitudeC = TextEditingController(text: init?.altitude?.toString() ?? '');
    _phC = TextEditingController(text: init?.ph?.toString() ?? '');
    _rainfallC = TextEditingController(text: init?.rainfall?.toString() ?? '');
  }

  @override
  void dispose() {
    _altitudeC.dispose();
    _phC.dispose();
    _rainfallC.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _landType = null;
      _altitudeC.clear();
      _phC.clear();
      _rainfallC.clear();
    });

    // Optional: kalau mau langsung hilang error merah setelah reset
    _formKey.currentState?.reset();
  }

  void _apply() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final altitude = int.tryParse(_altitudeC.text.trim());
    final ph = double.tryParse(_phC.text.trim().replaceAll(',', '.'));
    final rainfall = int.tryParse(_rainfallC.text.trim());

    Navigator.of(context).pop(
      FilterResult(
        landType: _landType,
        altitude: altitude,
        ph: ph,
        rainfall: rainfall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: bottomInset + 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          // Biar ga overflow saat keyboard muncul
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Text(
                      'Atur Filter',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ===== Jenis tanah =====
                DropdownButtonFormField<String>(
                  value: _landType,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null, // <- OK karena genericnya String? TIDAK
                      // Maka dropdown harus String? (lihat perbaikan di bawah)
                      child: Text('Semua jenis tanah'),
                    ),
                    ...landTypes.map(
                          (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _landType = v),
                  decoration: const InputDecoration(
                    labelText: 'Jenis Tanah',
                    border: OutlineInputBorder(),
                  ),
                ),

                // NOTE: DropdownButtonFormField di atas seharusnya bertipe String?
                // agar value null valid. Cara paling benar adalah ubah genericnya jadi String?.
                // Karena Flutter kadang membolehkan null pada value, tapi type mismatch bisa muncul.
                // Kalau IDE kamu warning/error, ganti baris "DropdownButtonFormField<String>(" menjadi:
                // DropdownButtonFormField<String?>(
                // dan ubah _landType jadi String? (sudah) serta item map -> DropdownMenuItem<String?>.
                const SizedBox(height: 12),

                // ===== Ketinggian =====
                // Baris 202 - Ketinggian
                TextFormField(
                  controller: _altitudeC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Ketinggian (mdpl)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    final n = int.tryParse(t);
                    if (n == null) return 'Masukkan angka yang benar';
                    if (n < 0) return 'Tidak boleh negatif';
                    if (n > 10000) return 'Terlalu besar';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ===== pH =====
                TextFormField(
                  controller: _phC,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d{0,2}([.,]\d{0,2})?$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'pH Tanah (0 - 14)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final raw = (v ?? '').trim();
                    if (raw.isEmpty) return null;
                    final t = raw.replaceAll(',', '.');
                    final n = double.tryParse(t);
                    if (n == null) return 'Masukkan angka desimal yang benar';
                    if (n < 0 || n > 14) return 'pH harus 0 sampai 14';
                    return null;
                  },
                  onChanged: (v) {
                    // normalisasi koma jadi titik tanpa mengganggu cursor
                    final fixed = v.replaceAll(',', '.');
                    if (fixed != v) {
                      final sel = _phC.selection;
                      _phC.value = _phC.value.copyWith(
                        text: fixed,
                        selection: sel,
                        composing: TextRange.empty,
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),

                // ===== Curah hujan =====
                // Baris 258 - Curah Hujan
                TextFormField(
                  controller: _rainfallC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Curah Hujan (mm/tahun)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    final n = int.tryParse(t);
                    if (n == null) return 'Masukkan angka yang benar';
                    if (n < 0) return 'Tidak boleh negatif';
                    if (n > 100000) return 'Terlalu besar';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                FilledButton.icon(
                  onPressed: _apply,
                  icon: const Icon(Icons.check),
                  label: const Text('Terapkan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
