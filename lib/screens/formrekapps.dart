import 'package:flutter/material.dart';
import '../models/data_record.dart';
import '../services/data_service.dart';
import '../services/filter_engine.dart';
import 'navscreen.dart';

class FormRekAppsScreen extends StatefulWidget {
  const FormRekAppsScreen({super.key});

  @override
  State<FormRekAppsScreen> createState() => _FormRekAppsScreenState();
}

class _FormRekAppsScreenState extends State<FormRekAppsScreen> {
  final DataService _dataService = DataService.instance;
  final ScrollController _scrollC = ScrollController();

  // ===== KONSTANTA EKOSISTEM =====
  static const String ecoMangrove = 'Mangrove';
  static const String ecoLowland = 'Dataran Rendah';

  List<DataRecord> _dataset = [];
  String? _ecosystem;
  bool _loading = true;
  String? _errorText;
//sorting
  List<String> _sortOptions(String field, List<String> items) {
    final list = [...items];

    // ===== SUBSTRAT (manual order) =====
    if (field == 'substrat') {
      const order = ['LUMPUR', 'PASIR', 'KARANG'];
      list.sort((a, b) =>
          order.indexOf(a.toUpperCase())
              .compareTo(order.indexOf(b.toUpperCase())));
      return list;
    }

    // ===== SALINITAS =====
    if (field == 'salinitas' ||
        field == 'ketinggian' ||
        field == 'intensitas_cahaya') {

      list.sort((a, b) =>
          _extractMinValue(a).compareTo(_extractMinValue(b)));
      return list;
    }


    // ===== KETINGGIAN =====
    if (field == 'ketinggian') {
      const order = ['<100', '101 - 500', '501 - 1000'];
      list.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
      return list;
    }

    // ===== CURAH HUJAN =====
    if (field == 'curah_hujan') {
      const order = [
        'Rendah 0 - 100',
        'Menengah 101 - 300',
        'Tinggi 301 - 500'
      ];
      list.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
      return list;
    }

    // ===== SUHU UDARA =====
    if (field == 'suhu_udara') {
      const order = ['<25', '25.1 - 30', '>30'];
      list.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
      return list;
    }

    // ===== pH TANAH =====
    if (field == 'ph_tanah') {
      const order = ['<4.5', '4.5 - 5.5','5.6 - 6.5', '6.6 - 7.5', '7.6 - 8.5', '>8.5'];
      list.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
      return list;
    }



    // ===== DEFAULT (kalau ada field lain) =====
    list.sort();
    return list;
  }
  // ================= FIELD ORDER =================
  static const List<String> _mangroveFields = [
    'substrat',
    'salinitas',
    'jenis_ekosistem_mangrove',
    'lokasi_pasang_surut',
  ];

  static const List<String> _lowlandFields = [
    'ketinggian',
    'curah_hujan',
    'intensitas_cahaya',
    'suhu_udara',
    'ph_tanah',
  ];

  // ================= LABEL UI =================
  static const Map<String, String> fieldLabels = {
    'substrat': 'Substrat',
    'salinitas': 'Salinitas',
    'jenis_ekosistem_mangrove': 'Jenis Ekosistem Mangrove',
    'lokasi_pasang_surut': 'Lokasi Pasang Surut',
    'ketinggian': 'Ketinggian Tempat',
    'curah_hujan': 'Curah Hujan',
    'intensitas_cahaya': 'Intensitas Cahaya',
    'suhu_udara': 'Suhu Udara',
    'ph_tanah': 'pH Tanah',
  };

  final Map<String, String?> _answers = {};
  Map<String, List<String>> _options = {};
  final Map<String, List<String>> _baseOptions = {};
  List<String> _recommendations = [];

  // ✅ FIX: cache daftar pustaka per ekosistem
  List<String> _ecoReferences = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollC.dispose();
    super.dispose();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    try {
      final ecosystems = await _dataService.getEcosystems();
      final List<DataRecord> records = [];

      ecosystems.forEach((ecoKey, list) {
        final ecosystemName =
        ecoKey == 'mangrove' ? ecoMangrove : ecoLowland;

        for (final row in list) {
          records.add(
            DataRecord(
              id: row['id'] ?? '',
              fields: Map<String, String>.from({
                'ecosystem': ecosystemName,
                ...row.map((k, v) => MapEntry(k, v?.toString() ?? '')),
              }),
            ),
          );
        }
      });

      if (!mounted) return;
      setState(() {
        _dataset = records;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorText = e.toString();
      });
    }
  }

  // ================= HELPERS =================
  List<String> _currentOrder() =>
      _ecosystem == ecoMangrove ? _mangroveFields : _lowlandFields;

  bool _allAnswered(List<String> order) =>
      order.every((k) => (_answers[k] ?? '').trim().isNotEmpty);

  // ✅ FIX: dibuat SINKRON & TIDAK fetch network
  Future<void> _recomputeOptionsAndResults() async {
    if (_ecosystem == null) return;

    final engine = FilterEngine(dataset: _dataset);
    final order = _currentOrder();

    final newOptions = engine.optionsFor(
      ecosystem: _ecosystem!,
      answeredFilters: _answers,
      fieldOrder: order,
    );

    setState(() {
      _options = newOptions;
      _recommendations = [];
      _ecoReferences = []; // ⬅️ RESET dulu
    });

    // ⛔ JANGAN tampilkan apa pun jika belum lengkap
    if (!_allAnswered(order)) return;

    // ✅ REKOMENDASI
    final res = engine.result(
      ecosystem: _ecosystem!,
      answers: _answers,
      recommendationKey: 'rekomendasi_jenis',
    );

    // ✅ DAFTAR PUSTAKA (BARU DI SINI)
    final refs = await _dataService.getReferencesForUser(_ecosystem!);
    if (!mounted) return;

    setState(() {
      _recommendations = res.recommendations;
      _ecoReferences = refs;
    });
  }
  void _buildBaseOptions() {
    if (_ecosystem == null) return;

    final fields = _currentOrder();

    for (final field in fields) {
      _baseOptions[field] = _dataset
          .where((r) => r.fields['ecosystem'] == _ecosystem)
          .map((r) => r.fields[field] ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
          .cast<String>();  // ⬅️ TAMBAH INI
    }
  }

  int _extractMinValue(String text) {
    text = text.trim();

    // <3
    if (text.startsWith('<')) {
      return 0;
    }

    // >30
    if (text.startsWith('>')) {
      final num = int.tryParse(
        text.replaceAll(RegExp(r'[^0-9]'), ''),
      );
      return (num ?? 0) + 1;
    }

    // 3 - 16
    if (text.contains('-')) {
      final parts = text.split('-');
      return int.tryParse(parts.first.trim()) ?? 0;
    }

    // angka tunggal (jaga-jaga)
    return int.tryParse(text) ?? 0;
  }

  // ✅ FIX: daftar pustaka diambil SAAT pilih ekosistem
  void _onEcosystemSelected(String eco) async {
    if (_ecosystem == eco) return;

    setState(() {
      _ecosystem = eco;
      _answers.clear();
      _options.clear();
      _baseOptions.clear();
      _recommendations.clear();
      _ecoReferences.clear();
    });

    _buildBaseOptions();
    _recomputeOptionsAndResults();
  }
  void _onFieldChanged(String fieldId, String value) {
    setState(() {
      _answers[fieldId] = value;

      // ❗ reset jawaban field setelahnya (agar konsisten)
      final order = _currentOrder();
      final idx = order.indexOf(fieldId);

      if (idx != -1) {
        for (int i = idx + 1; i < order.length; i++) {
          _answers.remove(order[i]);
        }
      }
    });

    _recomputeOptionsAndResults();
  }

  bool _isUnlocked(int idx, List<String> order) {
    for (int i = 0; i < idx; i++) {
      if ((_answers[order[i]] ?? '').isEmpty) return false;
    }
    return true;
  }

  // ================= DROPDOWN =================
    Widget _buildDropdown(String fieldKey) {
      final rawOpts = _baseOptions[fieldKey] ?? [];


      final current = _answers[fieldKey];

      final uniqueItems = _sortOptions(
        fieldKey,
        rawOpts
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList(),
      );

      final selectedIndex =
      (current != null && uniqueItems.contains(current))
          ? uniqueItems.indexOf(current)
          : null;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fieldLabels[fieldKey] ?? fieldKey,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: selectedIndex,
                hint: const Text('- Pilih -'),
                items: List.generate(uniqueItems.length, (i) {
                  return DropdownMenuItem<int>(
                    value: i,
                    child: Text(uniqueItems[i]),
                  );
                }),
                onChanged: (i) {
                  if (i == null) return;
                  _onFieldChanged(fieldKey, uniqueItems[i]);
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      );
    }


    // ================= RESULT =================
  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ================= REKOMENDASI =================
        if (_recommendations.isNotEmpty) ...[
          const Text(
            'Rekomendasi Tanaman:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SelectableText(
            _recommendations.map((e) => '- $e').join('\n'),
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
        ],

        // ================= DAFTAR PUSTAKA =================
        if (_ecoReferences.isNotEmpty) ...[
          const Text(
            'Daftar Pustaka:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SelectableText(
            _ecoReferences.map((e) => '- $e').join('\n\n'),
            style: const TextStyle(height: 1.5),
          ),
        ],
      ],
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorText != null) {
      return Scaffold(body: Center(child: Text(_errorText!)));
    }

    final order = _currentOrder();

    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: NavScreen(currentPage: 'form'),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F6E9),
        elevation: 0,
        automaticallyImplyLeading: false,

        // ☰ DI KIRI
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),

        title: const Text(
          'Form Rekomendasi Tanaman',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          controller: _scrollC,
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            24 + MediaQuery.of(context).padding.bottom, // ⬅️ KUNCI UTAMA
          ),
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Mangrove'),
                  selected: _ecosystem == ecoMangrove,
                  onSelected: (_) => _onEcosystemSelected(ecoMangrove),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Dataran Rendah'),
                  selected: _ecosystem == ecoLowland,
                  onSelected: (_) => _onEcosystemSelected(ecoLowland),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_ecosystem != null)
              for (int i = 0; i < order.length; i++)
                if (_isUnlocked(i, order)) _buildDropdown(order[i]),

            const SizedBox(height: 16),

            if (_ecosystem != null) _buildResults(),
          ],
        ),
      ),
    );
  }
}