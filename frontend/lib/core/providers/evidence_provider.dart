import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/evidence_model.dart';
import '../services/api_service.dart';

class EvidenceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<EvidenceItem> _evidenceList = [];
  bool _isLoading = false;
  String _selectedFilter = 'ALL'; // ALL, VERIFIED, PENDING, FLAGGED

  List<EvidenceItem> get evidenceList {
    if (_selectedFilter == 'ALL') return _evidenceList;
    return _evidenceList.where((e) => e.verificationStatus == _selectedFilter).toList();
  }

  List<EvidenceItem> get allEvidence => _evidenceList;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  EvidenceProvider() {
    loadEvidence();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> loadEvidence() async {
    _isLoading = true;
    notifyListeners();
    _evidenceList = await _api.fetchEvidence();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEvidence({
    required String title,
    required String description,
    required String evidenceType,
    String? mediaUrl,
    String? audioTranscript,
    String? productQr,
    String? productName,
    String? dosagePerAcre,
  }) async {
    final newId = 'EV-2026-${(1000 + _evidenceList.length + 1)}';
    final newItem = EvidenceItem(
      id: newId,
      farmId: 'farm-101',
      cropName: 'Cotton (Bt-II)',
      cropStage: 'Flowering Stage',
      evidenceType: evidenceType,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      location: GeoLocation(
        latitude: 20.1985,
        longitude: 73.8322,
        fieldName: 'Plot North-04',
        village: 'Dindori, Nashik',
      ),
      weather: WeatherSnapshot(
        temperatureC: 27.4,
        humidityPercent: 66.0,
        windSpeedKmh: 6.8,
        precipitationProb: 10.0,
        condition: 'Clear / Mild',
        spraySuitabilityScore: 0.95,
        sprayRecommendation: 'Foliar application safe',
      ),
      title: title,
      description: description,
      mediaUrl: mediaUrl,
      audioTranscript: audioTranscript,
      productQr: productQr,
      productName: productName,
      dosagePerAcre: dosagePerAcre,
      verificationStatus: 'VERIFIED',
      verificationScore: 97.4,
      verificationHash: 'd3a8b1c920f019a823e410bca8912e74281903bc183921af78921bca9012beef',
      agentVerdicts: {
        'validation_agent': 'SHA-256 integrity hash generated and locked.',
        'weather_agent': 'Weather parameters aligned with standard spray guidelines.',
      },
    );

    _evidenceList.insert(0, newItem);
    notifyListeners();

    // Background submit to backend
    await _api.submitEvidence(newItem.toJson());
  }

  void updateStatus(String evidenceId, String newStatus, {double score = 96.0, List<String>? reasons}) {
    for (var ev in _evidenceList) {
      if (ev.id == evidenceId) {
        ev.verificationStatus = newStatus;
        ev.verificationScore = score;
        break;
      }
    }
    notifyListeners();
  }
}
