import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/recommendation_service.dart';

final recommendationServiceProvider = Provider<RecommendationService>((ref) => RecommendationService());

final filterProvider = StateNotifierProvider<FilterController, FilterState>((ref) => FilterController());

class FilterState {
  final String? landType;
  final int? altitude;
  final double? ph;
  final int? rainfall;
  final String query;

  const FilterState({
    this.landType,
    this.altitude,
    this.ph,
    this.rainfall,
    this.query = '',
  });

  FilterState copyWith({String? landType, int? altitude, double? ph, int? rainfall, String? query}) {
    return FilterState(
      landType: landType ?? this.landType,
      altitude: altitude ?? this.altitude,
      ph: ph ?? this.ph,
      rainfall: rainfall ?? this.rainfall,
      query: query ?? this.query,
    );
  }
}

class FilterController extends StateNotifier<FilterState> {
  FilterController() : super(const FilterState());

  void setLandType(String? v) => state = state.copyWith(landType: v);
  void setAltitude(int? v) => state = state.copyWith(altitude: v);
  void setPH(double? v) => state = state.copyWith(ph: v);
  void setRainfall(int? v) => state = state.copyWith(rainfall: v);
  void setQuery(String v) => state = state.copyWith(query: v);
  void reset() => state = const FilterState();
}
