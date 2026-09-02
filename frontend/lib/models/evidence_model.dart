class EvidenceItem {
  final String id;
  final String farmId;
  final String cropName;
  final String cropStage;
  final String evidenceType;
  final String timestamp;
  final GeoLocation location;
  final WeatherSnapshot? weather;
  final String title;
  final String description;
  final String? mediaUrl;
  final String? audioTranscript;
  final String? productQr;
  final String? productName;
  final String? dosagePerAcre;
  String verificationStatus;
  double verificationScore;
  final String? verificationHash;
  final Map<String, dynamic> agentVerdicts;
  final List<String> flagReasons;

  EvidenceItem({
    required this.id,
    required this.farmId,
    required this.cropName,
    required this.cropStage,
    required this.evidenceType,
    required this.timestamp,
    required this.location,
    this.weather,
    required this.title,
    required this.description,
    this.mediaUrl,
    this.audioTranscript,
    this.productQr,
    this.productName,
    this.dosagePerAcre,
    required this.verificationStatus,
    required this.verificationScore,
    this.verificationHash,
    this.agentVerdicts = const {},
    this.flagReasons = const [],
  });

  factory EvidenceItem.fromJson(Map<String, dynamic> json) {
    return EvidenceItem(
      id: json['id'] ?? '',
      farmId: json['farm_id'] ?? '',
      cropName: json['crop_name'] ?? '',
      cropStage: json['crop_stage'] ?? '',
      evidenceType: json['evidence_type'] ?? 'FIELD_OBSERVATION',
      timestamp: json['timestamp'] ?? '',
      location: GeoLocation.fromJson(json['location'] ?? {}),
      weather: json['weather'] != null ? WeatherSnapshot.fromJson(json['weather']) : null,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      mediaUrl: json['media_url'],
      audioTranscript: json['audio_transcript'],
      productQr: json['product_qr'],
      productName: json['product_name'],
      dosagePerAcre: json['dosage_per_acre'],
      verificationStatus: json['verification_status'] ?? 'PENDING',
      verificationScore: (json['verification_score'] as num?)?.toDouble() ?? 0.0,
      verificationHash: json['verification_hash'],
      agentVerdicts: json['agent_verdicts'] != null ? Map<String, dynamic>.from(json['agent_verdicts']) : {},
      flagReasons: json['flag_reasons'] != null ? List<String>.from(json['flag_reasons']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_id': farmId,
      'crop_name': cropName,
      'crop_stage': cropStage,
      'evidence_type': evidenceType,
      'timestamp': timestamp,
      'location': location.toJson(),
      if (weather != null) 'weather': weather!.toJson(),
      'title': title,
      'description': description,
      'media_url': mediaUrl,
      'audio_transcript': audioTranscript,
      'product_qr': productQr,
      'product_name': productName,
      'dosage_per_acre': dosagePerAcre,
      'verification_status': verificationStatus,
      'verification_score': verificationScore,
      'verification_hash': verificationHash,
      'agent_verdicts': agentVerdicts,
      'flag_reasons': flagReasons,
    };
  }
}

class GeoLocation {
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final String fieldName;
  final String village;

  GeoLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters = 5.0,
    this.fieldName = 'Plot North-04',
    this.village = 'Nashik',
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 20.1985,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 73.8322,
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble() ?? 5.0,
      fieldName: json['field_name'] ?? 'Plot North-04',
      village: json['village'] ?? 'Nashik',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'field_name': fieldName,
      'village': village,
    };
  }
}

class WeatherSnapshot {
  final double temperatureC;
  final double humidityPercent;
  final double windSpeedKmh;
  final double precipitationProb;
  final String condition;
  final double spraySuitabilityScore;
  final String sprayRecommendation;
  final double? apparentTempC;
  final double? deltaTC;
  final double? dewPointC;
  final double? windGustsKmh;
  final double? cloudCoverPercent;
  final double? soilMoisturePercent;
  final String locationName;
  final String districtName;
  final String stateName;
  final bool isPunjabRegion;
  final String? pauAdvisoryText;

  WeatherSnapshot({
    required this.temperatureC,
    required this.humidityPercent,
    required this.windSpeedKmh,
    required this.precipitationProb,
    required this.condition,
    required this.spraySuitabilityScore,
    required this.sprayRecommendation,
    this.apparentTempC,
    this.deltaTC,
    this.dewPointC,
    this.windGustsKmh,
    this.cloudCoverPercent,
    this.soilMoisturePercent,
    this.locationName = "Ludhiana (ਲੁਧਿਆਣਾ)",
    this.districtName = "Ludhiana",
    this.stateName = "Punjab",
    this.isPunjabRegion = true,
    this.pauAdvisoryText,
  });

  factory WeatherSnapshot.fromJson(Map<String, dynamic> json) {
    return WeatherSnapshot(
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 28.5,
      humidityPercent: (json['humidity_percent'] as num?)?.toDouble() ?? 65.0,
      windSpeedKmh: (json['wind_speed_kmh'] as num?)?.toDouble() ?? 6.0,
      precipitationProb: (json['precipitation_prob'] as num?)?.toDouble() ?? 10.0,
      condition: json['condition'] ?? 'Clear Sunny Skies',
      spraySuitabilityScore: (json['spray_suitability_score'] as num?)?.toDouble() ?? 0.95,
      sprayRecommendation: json['spray_recommendation'] ?? 'Prime spraying conditions.',
      apparentTempC: (json['apparent_temp_c'] as num?)?.toDouble(),
      deltaTC: (json['delta_t_c'] as num?)?.toDouble() ?? 3.5,
      dewPointC: (json['dew_point_c'] as num?)?.toDouble(),
      windGustsKmh: (json['wind_gusts_kmh'] as num?)?.toDouble(),
      cloudCoverPercent: (json['cloud_cover_percent'] as num?)?.toDouble(),
      soilMoisturePercent: (json['soil_moisture_percent'] as num?)?.toDouble(),
      locationName: json['location_name'] ?? 'Ludhiana, Punjab',
      districtName: json['district_name'] ?? 'Ludhiana',
      stateName: json['state_name'] ?? 'Punjab',
      isPunjabRegion: json['is_punjab_region'] ?? true,
      pauAdvisoryText: json['pau_advisory_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature_c': temperatureC,
      'humidity_percent': humidityPercent,
      'wind_speed_kmh': windSpeedKmh,
      'precipitation_prob': precipitationProb,
      'condition': condition,
      'spray_suitability_score': spraySuitabilityScore,
      'spray_recommendation': sprayRecommendation,
      'apparent_temp_c': apparentTempC,
      'delta_t_c': deltaTC,
      'dew_point_c': dewPointC,
      'wind_gusts_kmh': windGustsKmh,
      'cloud_cover_percent': cloudCoverPercent,
      'soil_moisture_percent': soilMoisturePercent,
      'location_name': locationName,
      'district_name': districtName,
      'state_name': stateName,
      'is_punjab_region': isPunjabRegion,
      'pau_advisory_text': pauAdvisoryText,
    };
  }
}

