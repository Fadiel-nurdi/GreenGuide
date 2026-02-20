import '../models/data_record.dart';

class RecommendationResult {
  final List<String> recommendations;

  const RecommendationResult({
    required this.recommendations,
  });
}

class FilterEngine {
  final List<DataRecord> dataset;

  const FilterEngine({required this.dataset});

  // ================= OPTIONS (DROPDOWN) =================
  Map<String, List<String>> optionsFor({
    required String ecosystem,
    required Map<String, String?> answeredFilters,
    required List<String> fieldOrder,
  }) {
    final ecoNorm = _normEco(ecosystem);

    final nextField = _nextUnanswered(fieldOrder, answeredFilters);
    if (nextField == null) return {};

    // ⬇️ PENTING: jangan normKey di sini
    final nextKey = nextField;

    var filtered = _filterByEco(ecoNorm);

    for (final entry in answeredFilters.entries) {
      final field = entry.key;
      final selected = entry.value;
      if (selected == null || selected.trim().isEmpty) continue;
      if (field == nextField) continue;

      filtered = _applyAnswerFilter(
        filtered,
        field,
        selected,
      );
    }

    final values = <String>{};

    for (final r in filtered) {
      final raw = r.getString(nextKey);
      if (raw == null || raw.trim().isEmpty) continue;

      if (_isSubstrat(nextKey)) {
        values.addAll(_substratTokens(raw));
      } else if (_isSalinitas(nextKey)) {
        values.add(_normSalinitas(raw));
      } else {
        values.add(raw.trim());
      }
    }

    return {nextField: _sortValues(nextField, values.toList())};
  }

  // ================= FINAL RESULT =================
  RecommendationResult result({
    required String ecosystem,
    required Map<String, String?> answers,
    required String recommendationKey,
  }) {
    final ecoNorm = _normEco(ecosystem);

    var filtered = _filterByEco(ecoNorm);

    for (final entry in answers.entries) {
      final field = entry.key;
      final selected = entry.value;
      if (selected == null || selected.trim().isEmpty) continue;

      filtered = _applyAnswerFilter(
        filtered,
        field,
        selected,
      );
    }

    final recSet = <String>{};

    for (final r in filtered) {
      final rec = r.getString(recommendationKey);
      if (rec != null && rec.trim().isNotEmpty) {
        recSet.addAll(_split(rec));
      }
    }

    return RecommendationResult(
      recommendations: recSet.toList()..sort(),
    );
  }

  // ================= CORE FILTER =================

  List<DataRecord> _filterByEco(String ecoNorm) {
    return dataset.where((r) {
      final eco = r.getString('ecosystem') ?? '';
      return _normEco(eco) == ecoNorm;
    }).toList();
  }

  List<DataRecord> _applyAnswerFilter(
      List<DataRecord> input,
      String field,
      String selected,
      ) {
    final selNorm = _normValue(selected);

    return input.where((r) {
      final raw = r.getString(field);
      if (raw == null || raw.trim().isEmpty) return true;

      if (_isSubstrat(field)) {
        return _substratTokens(raw)
            .map((e) => e.toLowerCase())
            .contains(selNorm);
      }

      if (_isSalinitas(field)) {
        return _normSalinitas(raw) == selNorm;
      }

      return _normValue(raw) == selNorm;
    }).toList();
  }

  // ================= HELPERS =================

  String _normEco(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('mangrove')) return 'mangrove';
    if (s.contains('dataran')) return 'dataran_rendah';
    return s.replaceAll(' ', '_');
  }

  String _normValue(String v) =>
      v.toLowerCase().replaceAll(':', '').replaceAll(RegExp(r'\s+'), ' ').trim();

  bool _isSubstrat(String key) => key.contains('substrat');

  bool _isSalinitas(String key) => key.contains('salinitas');

  String _normSalinitas(String raw) =>
      raw.toLowerCase().replaceAll('ppt', '').replaceAll(':', '').trim();

  String? _nextUnanswered(
      List<String> order,
      Map<String, String?> answers,
      ) {
    for (final k in order) {
      if ((answers[k] ?? '').trim().isEmpty) return k;
    }
    return null;
  }

  Set<String> _substratTokens(String raw) {
    final s = raw.toLowerCase();
    final out = <String>{};

    if (s.contains('lumpur')) out.add('LUMPUR');
    if (s.contains('pasir') || s.contains('berpasir')) out.add('PASIR');
    if (s.contains('karang') ||
        s.contains('batu') ||
        s.contains('berbatu') ||
        s.contains('kerikil') ||
        s.contains('keras')) {
      out.add('KARANG');
    }

    return out;
  }

  List<String> _sortValues(String field, List<String> values) {
    int rank(String v) {
      final s = v.toLowerCase();

      if (field.contains('ketinggian')) {
        if (s.contains('<')) return 0;
        if (s.contains('100')) return 1;
        if (s.contains('500')) return 2;
        if (s.contains('1000')) return 3;
      }

      if (field.contains('curah')) {
        if (s.contains('rendah')) return 0;
        if (s.contains('menengah')) return 1;
        if (s.contains('tinggi') && !s.contains('sangat')) return 2;
        if (s.contains('sangat')) return 3;
      }

      if (field.contains('intensitas')) {
        if (s.contains('<')) return 0;
        if (s.contains('3000')) return 1;
        if (s.contains('>')) return 2;
      }

      if (field.contains('suhu')) {
        if (s.contains('<')) return 0;
        if (s.contains('25')) return 1;
        if (s.contains('>')) return 2;
      }

      if (field.contains('ph')) {
        if (s.contains('<')) return 0;
        if (s.contains('4.5')) return 1;
        if (s.contains('5.5')) return 2;
        if (s.contains('6.5')) return 3;
        if (s.contains('7.5')) return 4;
      }

      return 99;
    }

    values.sort((a, b) => rank(a).compareTo(rank(b)));
    return values;
  }

  List<String> _split(String raw) =>
      raw.split(RegExp(r'[;,\n]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}
