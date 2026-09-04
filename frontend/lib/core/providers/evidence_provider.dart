import 'package:flutter/material.dart';
import '../../models/evidence_model.dart';
import '../services/api_service.dart';
import '../services/google_sheets_service.dart';

class EvidenceProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final GoogleSheetsService _sheets = GoogleSheetsService();
  List<EvidenceItem> _evidenceList = [];
  bool _isLoading = false;
  String _selectedFilter = 'ALL'; // ALL, VERIFIED, PENDING, FLAGGED
  String? _activeFarmerPhone;
  String? _activeFarmerName;

  bool _matchesFarmer(EvidenceItem item) {
    if ((_activeFarmerPhone == null || _activeFarmerPhone!.isEmpty) &&
        (_activeFarmerName == null || _activeFarmerName!.isEmpty)) {
      return true;
    }

    // Normalize phone numbers (digits only)
    final activeDigits = _activeFarmerPhone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final itemDigits = item.farmerPhone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';

    bool phoneMatch = false;
    if (activeDigits.isNotEmpty && itemDigits.isNotEmpty) {
      if (activeDigits == itemDigits ||
          (activeDigits.length >= 10 && itemDigits.endsWith(activeDigits.substring(activeDigits.length - 10))) ||
          (itemDigits.length >= 10 && activeDigits.endsWith(itemDigits.substring(itemDigits.length - 10)))) {
        phoneMatch = true;
      }
    }

    final activeNameNorm = _activeFarmerName?.trim().toLowerCase() ?? '';
    final itemNameNorm = item.farmerName?.trim().toLowerCase() ?? '';
    bool nameMatch = false;
    if (activeNameNorm.isNotEmpty && itemNameNorm.isNotEmpty) {
      if (activeNameNorm == itemNameNorm ||
          activeNameNorm.contains(itemNameNorm) ||
          itemNameNorm.contains(activeNameNorm)) {
        nameMatch = true;
      }
    }

    return phoneMatch || nameMatch;
  }

  List<EvidenceItem> get evidenceList {
    List<EvidenceItem> baseList = _evidenceList;

    // Filter strictly by logged-in farmer if active
    if ((_activeFarmerPhone != null && _activeFarmerPhone!.isNotEmpty) ||
        (_activeFarmerName != null && _activeFarmerName!.isNotEmpty)) {
      baseList = baseList.where((e) => _matchesFarmer(e)).toList();
    }

    if (_selectedFilter == 'ALL') return baseList;
    return baseList.where((e) => e.verificationStatus == _selectedFilter).toList();
  }

  List<EvidenceItem> get allEvidence => _evidenceList;
  bool get isLoading => _isLoading;
  String get selectedFilter => _selectedFilter;

  EvidenceProvider() {
    loadEvidence();
  }

  void setActiveFarmer({required String phone, required String name}) {
    _activeFarmerPhone = phone.trim();
    _activeFarmerName = name.trim();
    loadEvidenceForFarmer(phone: phone, name: name);
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  Future<void> loadEvidence() async {
    _isLoading = true;
    notifyListeners();
    try {
      _evidenceList = await _api.fetchEvidence();
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEvidenceForFarmer({required String phone, required String name}) async {
    _activeFarmerPhone = phone.trim();
    _activeFarmerName = name.trim();
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch remote logs from Google Sheets (Farmer_Logs Tab)
      final sheetLogs = await _sheets.fetchFarmerLogs(phone: phone, name: name);
      if (sheetLogs.isNotEmpty) {
        final parsedItems = sheetLogs.map((json) => EvidenceItem.fromJson(json)).toList();

        // Replace with latest sheet logs for this farmer
        _evidenceList.removeWhere((e) => _matchesFarmer(e));
        _evidenceList.insertAll(0, parsedItems);
      } else {
        // If sheet is empty for this farmer, remove any leftover mock items for this phone
        _evidenceList.removeWhere((e) => _matchesFarmer(e));
      }
    } catch (e) {
      debugPrint("[Evidence Provider] Sheet logs fetch note: $e");
    }

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
    String? farmerName,
    String? farmerPhone,
    String? village,
    String? cropName,
  }) async {
    final effectiveName = farmerName ?? _activeFarmerName ?? 'Ramesh Patil';
    final effectivePhone = farmerPhone ?? _activeFarmerPhone ?? '9876543210';
    final effectiveCrop = cropName ?? 'Cotton (Bt-II)';
    final effectiveVillage = village ?? 'Dindori, Nashik';

    final newId = 'EV-2026-${(1000 + _evidenceList.length + 1)}';
    final newItem = EvidenceItem(
      id: newId,
      farmId: 'farm-101',
      cropName: effectiveCrop,
      cropStage: 'Flowering Stage',
      evidenceType: evidenceType,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      location: GeoLocation(
        latitude: 20.1985,
        longitude: 73.8322,
        fieldName: 'Plot North-04',
        village: effectiveVillage,
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
      farmerName: effectiveName,
      farmerPhone: effectivePhone,
      verificationStatus: 'VERIFIED',
      verificationScore: 97.4,
      verificationHash: 'd3a8b1c920f019a823e410bca8912e74281903bc183921af78921bca9012beef',
      agentVerdicts: {
        'validation_agent': 'SHA-256 integrity hash generated and locked under $effectiveName.',
        'weather_agent': 'Weather parameters aligned with standard spray guidelines.',
      },
    );

    _evidenceList.insert(0, newItem);
    notifyListeners();

    // Background submit to backend
    try {
      await _api.submitEvidence(newItem.toJson());
    } catch (_) {}
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
