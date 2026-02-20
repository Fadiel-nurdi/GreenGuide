class Plant {
  final String id;
  final String name;
  final String latinName;
  final String landType;
  final int minAltitude;
  final int maxAltitude;
  final double minPH;
  final double maxPH;
  final int minRainfall;
  final int maxRainfall;
  final String description;
  final String? imageUrl;

  const Plant({
    required this.id,
    required this.name,
    required this.latinName,
    required this.landType,
    required this.minAltitude,
    required this.maxAltitude,
    required this.minPH,
    required this.maxPH,
    required this.minRainfall,
    required this.maxRainfall,
    required this.description,
    this.imageUrl,
  });

  factory Plant.fromJson(Map<String, dynamic> j) => Plant(
    id: j['id'] as String,
    name: j['name'] as String,
    latinName: j['latinName'] as String,
    landType: j['landType'] as String,
    minAltitude: j['minAltitude'] as int,
    maxAltitude: j['maxAltitude'] as int,
    minPH: (j['minPH'] as num).toDouble(),
    maxPH: (j['maxPH'] as num).toDouble(),
    minRainfall: j['minRainfall'] as int,
    maxRainfall: j['maxRainfall'] as int,
    description: j['description'] as String,
    imageUrl: j['imageUrl'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'latinName': latinName,
    'landType': landType,
    'minAltitude': minAltitude,
    'maxAltitude': maxAltitude,
    'minPH': minPH,
    'maxPH': maxPH,
    'minRainfall': minRainfall,
    'maxRainfall': maxRainfall,
    'description': description,
    'imageUrl': imageUrl,
  };

  bool matches({
    String? landType,
    int? altitude,
    double? ph,
    int? rainfall,
  }) {
    final isMangrove = this.landType.toLowerCase() == 'mangrove';

    final okLand = landType == null ||
        this.landType.toLowerCase() == landType.toLowerCase();

    final okAlt = altitude == null ||
        (altitude >= minAltitude && altitude <= maxAltitude);

    // 🔥 pH hanya berlaku untuk NON-mangrove
    final okPH = isMangrove ||
        ph == null ||
        (ph >= minPH && ph <= maxPH);

    final okRain = rainfall == null ||
        (rainfall >= minRainfall && rainfall <= maxRainfall);

    return okLand && okAlt && okPH && okRain;
  }
}
