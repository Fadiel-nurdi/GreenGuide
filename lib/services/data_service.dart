import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../models/plant.dart';
import '../models/data_record.dart'; // ⬅️ WAJIB


class DataService {
  DataService._();
  static final DataService instance = DataService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =====================================================
  // 🔐 NULL SAFETY HELPER (PENYELAMAT ERROR MERAH)
  // =====================================================
  String _safeString(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  // =====================================================
  // PUBLIC API – DIPAKAI UI / SERVICE LAIN
  // =====================================================
  Future<Map<String, List<Map<String, dynamic>>>> getEcosystems() async {
    final online = await _hasInternet();

    if (online) {
      final data = await _fetchFromFirestore();

      // ✅ VALIDASI DATA SEBELUM SIMPAN CACHE
      if (data['mangrove']!.isNotEmpty ||
          data['dataran_rendah']!.isNotEmpty) {
        await _saveCache(data);
      }

      return data;
    } else {
      // OFFLINE ONLY
      return _loadFromCacheOrAsset();
    }
  }

  // =====================================================
  // 🔥 ADAPTER UNTUK RECOMMENDATION SERVICE
  // =====================================================
  Future<List<Plant>> getPlants() async {
    final ecosystems = await getEcosystems();
    final List<Plant> plants = [];

    for (final item in ecosystems['mangrove'] ?? []) {
      plants.add(
        Plant.fromJson({
          ...item,
          'ecosystem': 'Mangrove',
          'landType': 'mangrove',
        }),
      );
    }

    for (final item in ecosystems['dataran_rendah'] ?? []) {
      plants.add(
        Plant.fromJson({
          ...item,
          'ecosystem': 'Dataran Rendah',
          'landType': 'dataran_rendah',
        }),
      );
    }

    return plants;
  }

  // =====================================================
// ✅ DAFTAR PUSTAKA (GLOBAL + SESUAI EKOSISTEM)
// =====================================================
  Future<List<String>> getReferencesByEcosystem(String ecosystem) async {
    final snap = await _firestore
        .collection('references')
        .where('isActive', isEqualTo: true)
        .where(
      'ecosystem',
      whereIn: [
        ecosystem, // "Mangrove" / "Dataran Rendah"
        'global',
      ],
    )
        .orderBy('year', descending: true)
        .get();

    return snap.docs
        .map((d) => _safeString(d.data()['citation']))
        .where((e) => e.isNotEmpty)
        .toList();
  }


  // =====================================================
  // FIRESTORE – ECOSYSTEMS
  // =====================================================
  Future<Map<String, List<Map<String, dynamic>>>> _fetchFromFirestore() async {
    final snapshot = await _firestore.collection('ecosystems').get();

    final Map<String, List<Map<String, dynamic>>> result = {
      'mangrove': [],
      'dataran_rendah': [],
    };

    for (final doc in snapshot.docs) {
      final d = doc.data();
      final ecosystem =
      _safeString(d['ecosystem']).trim().toLowerCase();

      if (ecosystem.contains('mangrove')) {
        result['mangrove']!.add(_mapMangrove(d));
      } else if (ecosystem.contains('dataran')) {
        result['dataran_rendah']!.add(_mapDataranRendah(d));
      }
    }

    return result;
  }


  Future<void> _saveCache(
      Map<String, List<Map<String, dynamic>>> data,
      ) async {
    // ⛔ JANGAN SIMPAN CACHE JIKA DATA KOSONG TOTAL
    final mangroveEmpty = data['mangrove'] == null || data['mangrove']!.isEmpty;
    final lowlandEmpty = data['dataran_rendah'] == null || data['dataran_rendah']!.isEmpty;

    if (mangroveEmpty && lowlandEmpty) {
      print('⚠️ Cache NOT saved: both ecosystems empty');
      return;
    }

    final file = await _cacheFile();
    await file.writeAsString(jsonEncode(data));
    print('✅ Cache updated successfully');
  }
  Future<void> _saveReferencesCache(
      String ecosystem,
      List<String> refs,
      ) async {
    final file = await _referencesCacheFile();

    Map<String, dynamic> data = {};
    if (await file.exists()) {
      data = jsonDecode(await file.readAsString());
    }

    data[ecosystem] = refs;
    await file.writeAsString(jsonEncode(data));
  }


  Future<Map<String, List<Map<String, dynamic>>>> _loadFromCacheOrAsset() async {
    final file = await _cacheFile();

    if (await file.exists()) {
      final content = await file.readAsString();
      return _decode(content);
    }

    final asset =
    await rootBundle.loadString('assets/mock/ecosystems.json');
    return _decode(asset);
  }
  Future<List<String>> _loadReferencesFromCache(String ecosystem) async {
    final file = await _referencesCacheFile();
    if (!await file.exists()) return [];

    final data = jsonDecode(await file.readAsString());
    return List<String>.from(data[ecosystem] ?? []);
  }


// =====================================================
// LOCAL CACHE
// =====================================================
  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/ecosystems_cache.json');
  }

  Future<File> _referencesCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/references_cache.json');
  }

  // =====================================================
  // DECODER (AMAN TERHADAP NULL)
  // =====================================================
  Map<String, List<Map<String, dynamic>>> _decode(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;

    return {
      'mangrove': List<Map<String, dynamic>>.from(
        decoded['mangrove'] ?? const [],
      ),
      'dataran_rendah': List<Map<String, dynamic>>.from(
        decoded['dataran_rendah'] ?? const [],
      ),
    };
  }

  // =====================================================
  // CONNECTIVITY
  // =====================================================
  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // =====================================================
// ✅ KHUSUS USER (AMAN, TIDAK GANGGU ADMIN)
// =====================================================
  Future<List<String>> getReferencesForUser(String ecosystem) async {
    final online = await _hasInternet();

    if (online) {
      try {
        final snap = await _firestore
            .collection('references')
            .where('isActive', isEqualTo: true)
            .where(
          'ecosystem',
          whereIn: [ecosystem, 'global'],
        )
            .get(); // ⬅️ HAPUS orderBy dulu

        final refs = snap.docs.map((d) {
          final data = d.data();

          final citation = _safeString(data['citation']);
          final year = data['year'];

          if (citation.isEmpty) return '';

          // kalau tahun ada → tampilkan
          if (year != null && year.toString().isNotEmpty) {
            return '$citation ($year)';
          }

          // kalau tidak ada tahun
          return citation;
        }).where((e) => e.isNotEmpty).toList();

        // ✅ SIMPAN CACHE HANYA JIKA ADA DATA
        if (refs.isNotEmpty) {
          await _saveReferencesCache(ecosystem, refs);
          return refs;
        }

        // ❗ FALLBACK KE CACHE JIKA FIRESTORE KOSONG
        return _loadReferencesFromCache(ecosystem);
      } catch (e) {
        return _loadReferencesFromCache(ecosystem);
      }
    }

    // OFFLINE
    return _loadReferencesFromCache(ecosystem);
  }
  String normalizeEcosystem(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('mangrove')) return 'mangrove';
    if (s.contains('dataran')) return 'dataran_rendah';
    return 'global';
  }


  // =====================================================
  // NORMALIZER DATA (ANTI NULL TOTAL)
  // =====================================================
  Map<String, dynamic> _mapMangrove(Map<String, dynamic> d) {
    return {
      'id': _safeString(d['ecoId']),
      'substrat': _safeString(d['substrat']),
      'salinitas': _safeString(d['salinitas']),
      'jenis_ekosistem_mangrove':
      _safeString(d['jenis_ekosistem_mangrove']),
      'lokasi_pasang_surut': _safeString(d['lokasi_pasang_surut']),
      'rekomendasi_jenis': _safeString(d['rekomendasi_jenis']),
    };
  }

  Map<String, dynamic> _mapDataranRendah(Map<String, dynamic> d) {
    return {
      'id': _safeString(d['ecoId']),
      'ketinggian': _safeString(d['ketinggian']),
      'curah_hujan': _safeString(d['curah_hujan']),
      'intensitas_cahaya': _safeString(d['intensitas_cahaya']),
      'suhu_udara': _safeString(d['suhu_udara']),
      'ph_tanah': _safeString(d['ph_tanah']),
      'rekomendasi_jenis': _safeString(d['rekomendasi_jenis']),
    };
  }
  // =====================================================
// =================== TESTIMONI =======================
// =====================================================
// =====================================================
// 📢 SEMUA TESTIMONI (UNTUK HALAMAN TESTIMONI)
// =====================================================
  Stream<List<TestimonialRecord>> streamTestimonials() {
    return _firestore
        .collection('testimonials')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map((doc) =>
          TestimonialRecord.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<void> updateStatsOnDelete(int rating) async {
    final ref = _firestore.collection('testimonial_stats').doc('global');

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final totalReviews = snap['totalReviews'] ?? 1;
      final totalRating = snap['totalRating'] ?? rating;

      tx.update(ref, {
        'totalReviews': totalReviews - 1,
        'totalRating': totalRating - rating,
        'average': (totalReviews - 1) <= 0
            ? 0
            : (totalRating - rating) / (totalReviews - 1),
        'star$rating': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }


// =====================================================
// 📊 RINGKASAN TESTIMONI (TOTAL, RATA-RATA, BINTANG)
// =====================================================
  Stream<Map<String, dynamic>> streamTestimonialStats() {
    return _firestore
        .collection('testimonial_stats')
        .doc('global')
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

// =====================================================
// ⭐ TESTIMONI KHUSUS HOME (BINTANG 5 SAJA)
// =====================================================
  Stream<List<TestimonialRecord>> streamTopTestimonials({
     int limit = 5,
   }) {
     return _firestore
         .collection('testimonials')
         .where('rating', isEqualTo: 5)
         .snapshots()
         .map(
           (snap) => snap.docs
           .map((doc) =>
           TestimonialRecord.fromMap(doc.id, doc.data()))
           .toList(),
     );
   }

  /// Add testimonial and return the new document id.
  /// Uses server timestamp for createdAt so offline writes are queued.
  Future<String> addTestimonial(TestimonialRecord t) async {
    final map = {
      'userId': t.userId,
      'name': t.name,
      'angkatan': t.angkatan,
      'rating': t.rating,
      'message': t.message,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = await _firestore.collection('testimonials').add(map);

    // Try to update aggregated stats; ignore errors (may fail offline)
    try {
      await updateStatsOnCreate(t.rating);
    } catch (e) {
      print('updateStatsOnCreate failed: $e');
    }

    return ref.id;
  }
   Future<void> updateStatsOnCreate(int rating) async {
     final ref = _firestore.collection('testimonial_stats').doc('global');

     await _firestore.runTransaction((tx) async {
       final snap = await tx.get(ref);

       if (!snap.exists) {
         tx.set(ref, {
           'totalReviews': 1,
           'totalRating': rating,
           'average': rating.toDouble(),
           'star1': rating == 1 ? 1 : 0,
           'star2': rating == 2 ? 1 : 0,
           'star3': rating == 3 ? 1 : 0,
           'star4': rating == 4 ? 1 : 0,
           'star5': rating == 5 ? 1 : 0,
           'updatedAt': FieldValue.serverTimestamp(),
         });
         return;
       }

       final totalReviews = snap['totalReviews'] ?? 0;
       final totalRating = snap['totalRating'] ?? 0;

       tx.update(ref, {
         'totalReviews': totalReviews + 1,
         'totalRating': totalRating + rating,
         'average': (totalRating + rating) / (totalReviews + 1),
         'star$rating': FieldValue.increment(1),
         'updatedAt': FieldValue.serverTimestamp(),
       });
     });
   }
   Future<void> updateTestimonial(
       String id,
       String message,
       int rating,
       ) async {
     await _firestore.collection('testimonials').doc(id).update({
       'message': message,
       'rating': rating,
       'updatedAt': FieldValue.serverTimestamp(),
     });
   }

   Future<void> deleteTestimonial(
       String id,
       ) async {
     await _firestore.collection('testimonials').doc(id).delete();
   }

  /// Fetch a single testimonial by id. Returns null if not found.
  Future<TestimonialRecord?> getTestimonialById(String id) async {
    try {
      final doc = await _firestore.collection('testimonials').doc(id).get();
      if (!doc.exists) return null;
      return TestimonialRecord.fromMap(doc.id, doc.data() ?? {});
    } catch (e) {
      print('getTestimonialById error: $e');
      return null;
    }
   }

  // ================= SUGGESTIONS =================
  Stream<List<SuggestionRecord>> streamSuggestions() {
    return _firestore
        .collection('suggestions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SuggestionRecord.fromMap(d.id, d.data()))
            .toList());
  }

  /// Add suggestion and return document id. Uses serverTimestamp for createdAt.
  Future<String> addSuggestion(SuggestionRecord s) async {
    final map = {
      'userId': s.userId,
      'name': s.name,
      'angkatan': s.angkatan, // WAJIB TAMBAH
      'message': s.message,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final ref = await _firestore.collection('suggestions').add(map);
    return ref.id;
  }

  Future<void> deleteSuggestion(String id) async {
    await _firestore.collection('suggestions').doc(id).delete();
  }

  Future<SuggestionRecord?> getSuggestionById(String id) async {
    try {
      final doc = await _firestore.collection('suggestions').doc(id).get();
      if (!doc.exists) return null;
      return SuggestionRecord.fromMap(doc.id, doc.data() ?? {});
    } catch (e) {
      print('getSuggestionById error: $e');
      return null;
    }
  }
 }
