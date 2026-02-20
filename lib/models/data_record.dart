import 'package:cloud_firestore/cloud_firestore.dart';

class DataRecord {
  final String id;
  final Map<String, dynamic> fields;

  const DataRecord({
    required this.id,
    required this.fields,
  });

  factory DataRecord.fromJson(Map<String, dynamic> json) {
    // Support 2 bentuk:
    // 1) { "id": "...", "fields": {...} }
    // 2) { "ekosistem": "...", ... } (flat map)
    final map = (json['fields'] is Map<String, dynamic>)
        ? (json['fields'] as Map<String, dynamic>)
        : json;

    final id = (json['id'] ?? map['id'] ?? '').toString();

    return DataRecord(
      id: id.isEmpty ? 'rec_${map.hashCode}' : id,
      fields: map,
    );
  }

  /// Alias aman untuk ekosistem
  String? get ekosistem => getString('ekosistem');
  String? get ecosystem => getString('ekosistem');

  // ===================== GETTERS =====================

  /// Ambil nilai String dengan key-normalization:
  /// - case-insensitive
  /// - ignore spasi, underscore, dash
  String? getString(String key) {
    final direct = fields[key];
    if (direct != null) return direct.toString().trim();

    final target = _normalizeKey(key);
    for (final entry in fields.entries) {
      if (_normalizeKey(entry.key) == target) {
        final v = entry.value;
        return v == null ? null : v.toString().trim();
      }
    }
    return null;
  }

  /// Ambil nilai List<String> (aman)
  List<String>? getList(String key) {
    final direct = fields[key];
    if (direct is List) {
      return direct.map((e) => e.toString().trim()).toList();
    }

    final target = _normalizeKey(key);
    for (final entry in fields.entries) {
      if (_normalizeKey(entry.key) == target && entry.value is List) {
        return (entry.value as List)
            .map((e) => e.toString().trim())
            .toList();
      }
    }
    return null;
  }

  /// Ambil angka jika dibutuhkan
  double? getDouble(String key) {
    final s = getString(key);
    if (s == null) return null;
    final normalized = s.replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  // ===================== INTERNAL =====================

  String _normalizeKey(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_\-]+'), '');
  }
}
// =====================================================
// ================= TESTIMONIAL RECORD =================
// =====================================================

class TestimonialRecord {
  final String id;
  final String userId;
  final String name;
  final String angkatan;
  final int rating;
  final String message;
  final DateTime createdAt;

  TestimonialRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.angkatan,
    required this.rating,
    required this.message,
    required this.createdAt,
  });

  factory TestimonialRecord.fromMap(String id, Map<String, dynamic> map) {
    return TestimonialRecord(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Anonim',
      angkatan: map['angkatan'] ?? '-',
      rating: map['rating'] ?? 0,
      message: map['message'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'angkatan': angkatan,
      'rating': rating,
      'message': message,
      'createdAt': createdAt,
    };
  }
}

// ================= SUGGESTION RECORD =================
class SuggestionRecord {
  final String id;
  final String userId;
  final String name;
  final String angkatan;
  final String message;
  final DateTime createdAt;

  SuggestionRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.angkatan,
    required this.message,
    required this.createdAt,
  });

  factory SuggestionRecord.fromMap(String id, Map<String, dynamic> map) {
    return SuggestionRecord(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Anonim',
      angkatan: map['angkatan'] ?? '-',
      message: map['message'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'angkatan': angkatan,
      'message': message,
      'createdAt': createdAt,
    };
  }
}
