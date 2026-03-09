import 'package:flutter/material.dart';
import '../models/data_record.dart';
import '../services/data_service.dart';
import '../services/filter_engine.dart';

class CascadingForm extends StatefulWidget {
  final List<DataRecord> dataset;
  final String ecosystem;
  final List<String> fieldOrder;
  final Map<String, String> fieldLabels;
  final String recommendationKey;

  const CascadingForm({
    Key? key,
    required this.dataset,
    required this.ecosystem,
    required this.fieldOrder,
    required this.fieldLabels,
    required this.recommendationKey,
  }) : super(key: key);

  @override
  State<CascadingForm> createState() => _CascadingFormState();
}

class _CascadingFormState extends State<CascadingForm> {
  final Map<String, String?> _values = {};
  Map<String, List<String>> _options = {};
  List<String> _recommendations = [];

  late FilterEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = FilterEngine(dataset: widget.dataset);
    _resetAll();
  }

  @override
  void didUpdateWidget(covariant CascadingForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // RESET TOTAL SAAT GANTI EKOSISTEM
    if (oldWidget.ecosystem != widget.ecosystem) {
      _resetAll();
    }
  }

  void _resetAll() {
    setState(() {
      _values.clear();
      _recommendations.clear();
      _options = _engine.optionsFor(
        ecosystem: widget.ecosystem,
        answeredFilters: {},
        fieldOrder: widget.fieldOrder,
      );
    });
  }

  void _resetFollowing(String fieldId) {
    final idx = widget.fieldOrder.indexOf(fieldId);
    if (idx == -1) return;

    for (int i = idx + 1; i < widget.fieldOrder.length; i++) {
      _values.remove(widget.fieldOrder[i]);
    }
  }

  void _onValueChanged(String fieldId, String? value) {
    setState(() {
      if (value == null || value.isEmpty) {
        _values.remove(fieldId);
      } else {
        _values[fieldId] = value;
      }

      _resetFollowing(fieldId);

      // ⛔ JANGAN FILTER DENGAN FIELD YANG SEDANG DIPILIH
      final filteredAnswers = Map<String, String?>.from(_values);
      filteredAnswers.remove(fieldId);

      _options = _engine.optionsFor(
        ecosystem: widget.ecosystem,
        answeredFilters: filteredAnswers,
        fieldOrder: widget.fieldOrder,
      );

      final allFilled =
      widget.fieldOrder.every((k) => (_values[k] ?? '').isNotEmpty);

      if (allFilled) {
        final res = _engine.result(
          ecosystem: widget.ecosystem,
          answers: _values,
          recommendationKey: widget.recommendationKey,
        );
        _recommendations = res.recommendations;
      } else {
        _recommendations.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: widget.fieldOrder.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, idx) {
              final fid = widget.fieldOrder[idx];

              // ✅ FIELD PERTAMA SELALU MUNCUL
              if (idx > 0 &&
                  (_values[widget.fieldOrder[idx - 1]] ?? '').isEmpty) {
                return const SizedBox.shrink();
              }

              final opts = _options[fid] ?? [];
              final val = _values[fid];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fieldLabels[fid] ?? fid,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: (val != null && opts.contains(val)) ? val : null,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('- Pilih -'),
                          ),
                          ...opts.map(
                                (o) => DropdownMenuItem<String?>(
                              value: o,
                              child: Text(o),
                            ),
                          ),
                        ],
                        onChanged: (v) => _onValueChanged(fid, v),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        const Text(
          'Rekomendasi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (_recommendations.isEmpty)
          const Text('Tidak ditemukan rekomendasi.'),

        if (_recommendations.isNotEmpty)
          ..._recommendations.map((r) => Text('- $r')),
      ],
    );
  }
}
