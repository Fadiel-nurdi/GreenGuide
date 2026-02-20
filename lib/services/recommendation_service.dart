import '../models/plant.dart';
import 'data_service.dart';

class RecommendationService {
  final DataService _dataService = DataService.instance;

  List<Plant>? _cache;

  // ================= LOAD DATA =================
  Future<List<Plant>> _load() async {
    if (_cache != null) return _cache!;

    final data = await _dataService.getPlants();
    _cache = data;
    return _cache!;
  }

  // ================= RECOMMEND =================
  Future<List<Plant>> recommend({
    String? landType,
    int? altitude,
    double? ph,
    int? rainfall,
    String? query,
  }) async {
    final all = await _load();

    // ⛔ TANPA EKOSISTEM = TIDAK BOLEH LANJUT
    if (landType == null || landType.trim().isEmpty) {
      return [];
    }

    final land = landType.toLowerCase();

    var filtered = all.where((p) {
      // ✅ KUNCI EKOSISTEM (ANTI CAMPUR DATA)
      if (p.landType.toLowerCase() != land) return false;

      // ✅ GUNAKAN METHOD YANG SUDAH ADA
      return p.matches(
        landType: landType,
        altitude: altitude,
        ph: ph,
        rainfall: rainfall,
      );
    }).toList();

    // ================= SEARCH =================
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.latinName.toLowerCase().contains(q);
      }).toList();
    }

    return filtered;
  }

  // ================= GET BY ID =================
  Future<Plant?> getById(String id) async {
    final all = await _load();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ================= CLEAR CACHE =================
  /// Dipanggil saat user logout / force refresh
  void clearCache() {
    _cache = null;
  }
}
