import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/evidence_provider.dart';
import '../core/localization/app_translations.dart';
import '../core/services/api_service.dart';

class CropCameraScreen extends StatefulWidget {
  const CropCameraScreen({super.key});

  @override
  State<CropCameraScreen> createState() => _CropCameraScreenState();
}

class _CropCameraScreenState extends State<CropCameraScreen> {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  XFile? _capturedFile;
  Uint8List? _capturedImageBytes;
  bool _isAnalyzing = false;
  String _selectedCrop = "Auto-Detect";
  int _presetIndex = 0;
  Map<String, dynamic>? _diagnosisResult;

  final List<Map<String, String>> _presetSamples = [
    {
      "title": "Wheat Foliage (Stripe Rust)",
      "url": "https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800&auto=format&fit=crop&q=80",
      "crop": "Wheat",
    },
    {
      "title": "Cotton Crop Ready for Picking",
      "url": "https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=800&auto=format&fit=crop&q=80",
      "crop": "Cotton",
    },
    {
      "title": "Tomato Early Blight Lesions",
      "url": "https://images.unsplash.com/photo-1592417817098-8f3d6eb22509?w=800&auto=format&fit=crop&q=80",
      "crop": "Tomato",
    },
    {
      "title": "Chilli Leaf Curl & Thrips Infestation",
      "url": "https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&auto=format&fit=crop&q=80",
      "crop": "Chilli",
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  List<Map<String, String>> _getCropOptions(String lang) {
    if (lang == 'hi') {
      return [
        {"label": "🔍 ऑटो-डिटेक्ट", "key": "Auto-Detect"},
        {"label": "🌾 गेहूं", "key": "Wheat"},
        {"label": "🌿 कपास", "key": "Cotton"},
        {"label": "🍅 टमाटर", "key": "Tomato"},
        {"label": "🌶️ मिर्च", "key": "Chilli"},
        {"label": "🌾 धान / चावल", "key": "Paddy / Rice"},
        {"label": "🥔 आलू", "key": "Potato"},
        {"label": "🌽 मक्का", "key": "Maize"},
        {"label": "🌻 सरसों", "key": "Mustard"},
        {"label": "🌱 सोयाबीन", "key": "Soybean"},
      ];
    } else if (lang == 'pa') {
      return [
        {"label": "🔍 ਖੁਦ ਪਛਾਣੋ", "key": "Auto-Detect"},
        {"label": "🌾 ਕਣਕ", "key": "Wheat"},
        {"label": "🌿 ਕਪਾਹ / ਨਰਮਾ", "key": "Cotton"},
        {"label": "🍅 ਟਮਾਟਰ", "key": "Tomato"},
        {"label": "🌶️ ਮਿਰਚ", "key": "Chilli"},
        {"label": "🌾 ਝੋਨਾ / ਬਾਸਮਤੀ", "key": "Paddy / Rice"},
        {"label": "🥔 ਆਲੂ", "key": "Potato"},
        {"label": "🌽 ਮੱਕੀ", "key": "Maize"},
        {"label": "🌻 ਸਰ੍ਹੋਂ", "key": "Mustard"},
        {"label": "🌱 ਸੋਇਆਬੀਨ", "key": "Soybean"},
      ];
    } else if (lang == 'mr') {
      return [
        {"label": "🔍 स्वयंचलित शोध", "key": "Auto-Detect"},
        {"label": "🌾 गहू", "key": "Wheat"},
        {"label": "🌿 कापूस", "key": "Cotton"},
        {"label": "🍅 टोमॅटो", "key": "Tomato"},
        {"label": "🌶️ मिरची", "key": "Chilli"},
        {"label": "🌾 भात / धान", "key": "Paddy / Rice"},
        {"label": "🥔 बटाटा", "key": "Potato"},
        {"label": "🌽 मका", "key": "Maize"},
        {"label": "🌻 मोहरी", "key": "Mustard"},
        {"label": "🌱 सोयाबीन", "key": "Soybean"},
      ];
    }
    return [
      {"label": "🔍 Auto-Detect", "key": "Auto-Detect"},
      {"label": "🌾 Wheat", "key": "Wheat"},
      {"label": "🌿 Cotton", "key": "Cotton"},
      {"label": "🍅 Tomato", "key": "Tomato"},
      {"label": "🌶️ Chilli", "key": "Chilli"},
      {"label": "🌾 Paddy / Rice", "key": "Paddy / Rice"},
      {"label": "🥔 Potato", "key": "Potato"},
      {"label": "🌽 Maize", "key": "Maize"},
      {"label": "🌻 Mustard", "key": "Mustard"},
      {"label": "🌱 Soybean", "key": "Soybean"},
    ];
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 75,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedFile = photo;
          _capturedImageBytes = bytes;
          _diagnosisResult = null;
        });
        _analyzeCurrentPhoto();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Camera error: $e"),
            backgroundColor: AppColors.flaggedRed,
          ),
        );
      }
    }
  }

  void _analyzeCurrentPhoto() async {
    setState(() {
      _isAnalyzing = true;
      _diagnosisResult = null;
    });

    String? base64Str;
    if (_capturedImageBytes != null) {
      base64Str = base64Encode(_capturedImageBytes!);
    }

    try {
      final cropHint = _selectedCrop.contains("Auto-Detect") ? "Auto-Detect" : _selectedCrop;
      final result = await _api.analyzeVision(base64Str, cropHint);
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _diagnosisResult = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  void _saveEvidence() async {
    if (_diagnosisResult == null) return;
    final evProv = Provider.of<EvidenceProvider>(context, listen: false);

    final detectedCrop = _diagnosisResult!['crop_detected'] ?? _selectedCrop;
    final disease = _diagnosisResult!['disease_detected'] ?? 'Crop Foliar Scan';
    final severity = _diagnosisResult!['severity_level'] ?? 'Normal';
    final chemical = _diagnosisResult!['recommended_active_ingredient'] ?? 'Standard Foliar Treatment';

    await evProv.addEvidence(
      title: "Crop Scan: $detectedCrop • $disease",
      description: "$disease identified on $detectedCrop ($severity severity). Recommendation: $chemical.",
      evidenceType: 'CROP_IMAGE',
      mediaUrl: _capturedFile?.path ?? _presetSamples[_presetIndex]['url'],
      productName: chemical,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text("$detectedCrop diagnostic evidence sealed & saved to Farm Journal!"),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryDark,
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePreset = _presetSamples[_presetIndex];
    final authProv = Provider.of<AuthProvider>(context);
    final lang = authProv.selectedLanguage;
    final cropOptions = _getCropOptions(lang);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.tr(lang, "crop_doctor_title", "Crop Doctor AI"),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              AppTranslations.tr(lang, "crop_doctor_sub", "Pramaan AI • Real-Time Plant Pathology"),
              style: const TextStyle(fontSize: 11, color: AppColors.primaryAccent),
            ),
          ],
        ),
        actions: [
          // Language Switcher Badge Button
          TextButton.icon(
            onPressed: () => AppTranslations.showLanguageSelectorModal(
              context,
              lang,
              (newLang) => authProv.setLanguage(newLang),
            ),
            icon: const Icon(Icons.language_rounded, color: AppColors.accentGold, size: 18),
            label: Text(
              lang.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
            tooltip: AppTranslations.tr(lang, "gallery", "Gallery"),
            onPressed: () => _takePhoto(ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.accentGold, size: 24),
            tooltip: AppTranslations.tr(lang, "take_photo", "Take Photo"),
            onPressed: () => _takePhoto(ImageSource.camera),
          ),
        ],
      ),
      body: Column(
        children: [
          // Crop Selector Horizontal Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Text(
                  AppTranslations.tr(lang, "target_crop", "Target Crop:"),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: cropOptions.map((opt) {
                        final isSel = _selectedCrop == opt['key'] || (_selectedCrop.contains("Auto-Detect") && opt['key'] == "Auto-Detect");
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              opt['label']!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? Colors.white : Colors.white70,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            backgroundColor: const Color(0xFF334155),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCrop = opt['key']!;
                                });
                                if (_capturedImageBytes != null || _diagnosisResult != null) {
                                  _analyzeCurrentPhoto();
                                }
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Viewfinder HUD
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image Canvas (Real captured photo or preset sample)
                if (_capturedImageBytes != null)
                  kIsWeb
                      ? Image.memory(_capturedImageBytes!, fit: BoxFit.cover)
                      : Image.file(File(_capturedFile!.path), fit: BoxFit.cover)
                else
                  Image.network(
                    activePreset['url']!,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    },
                    errorBuilder: (ctx, _, __) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(Icons.image_not_supported_rounded, color: Colors.white54, size: 48),
                      ),
                    ),
                  ),

                // Dark Gradient Vignette
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.0, 0.15, 0.75, 1.0],
                    ),
                  ),
                ),

                // Center Clean Viewfinder Frame
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isAnalyzing ? AppColors.accentGold : const Color(0xFF34D399),
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isAnalyzing ? "AI DIAGNOSING..." : AppTranslations.tr(lang, "align_camera", "📷 Align crop leaf or plant inside frame"),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isAnalyzing ? AppColors.accentGold : Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (_isAnalyzing)
                          const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 3.5),
                                SizedBox(height: 12),
                                Text(
                                  "Pramaan Vision AI Examining...",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Sample Info Bar
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.photo_camera_back_rounded, color: AppColors.accentGold, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _capturedFile != null
                                ? "Captured Photo (${_diagnosisResult?['crop_detected'] ?? _selectedCrop})"
                                : activePreset['title']!,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _capturedFile = null;
                              _capturedImageBytes = null;
                              _presetIndex = (_presetIndex + 1) % _presetSamples.length;
                              _selectedCrop = _presetSamples[_presetIndex]['crop']!;
                              _diagnosisResult = null;
                            });
                            _analyzeCurrentPhoto();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "${AppTranslations.tr(lang, 'try_sample', 'Try Sample')} ⏭️",
                              style: const TextStyle(color: Color(0xFF34D399), fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Panel & AI Diagnostic Results
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.46,
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: () => _takePhoto(ImageSource.camera),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF15803D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: Text(
                            AppTranslations.tr(lang, "take_photo", "Take Photo"),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => _takePhoto(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF15803D), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.image_rounded, size: 18, color: Color(0xFF15803D)),
                          label: Text(
                            AppTranslations.tr(lang, "gallery", "Gallery"),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        onPressed: _isAnalyzing ? null : _analyzeCurrentPhoto,
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF15803D),
                        ),
                        tooltip: "Re-analyze",
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                      ),
                    ],
                  ),

                  // Initial Welcome Card (When no photo taken yet)
                  if (_diagnosisResult == null && !_isAnalyzing) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.eco_rounded, color: Color(0xFF15803D), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                AppTranslations.tr(lang, "crop_doctor_title", "Crop Doctor AI"),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            lang == 'hi'
                                ? "1. 'फोटो लें' बटन दबाएं।\n2. फसल के पत्ते या पौधे की साफ तस्वीर लें।\n3. Pramaan AI तुरंत रोग पहचानकर सही दवा की मात्रा बताएगा।"
                                : lang == 'pa'
                                    ? "1. 'ਫੋਟੋ ਲਓ' ਬਟਨ ਦਬਾਓ।\n2. ਫ਼ਸਲ ਦੇ ਪੱਤੇ ਜਾਂ ਬੂਟੇ ਦੀ ਸਾਫ਼ ਫ਼ੋਟੋ ਖਿੱਚੋ।\n3. Pramaan AI ਤੁਰੰਤ ਬਿਮਾਰੀ ਦੱਸ ਕੇ ਸਹੀ ਦਵਾਈ ਦੱਸੇਗਾ।"
                                    : lang == 'mr'
                                        ? "1. 'फोटो काढा' बटण दाबा.\n2. पिकाच्या पानाचा किंवा झाडाचा स्पष्ट फोटो घ्या.\n3. Pramaan AI त्वरित रोग ओळखून योग्य औषध सुचवेल."
                                        : "1. Tap 'Take Photo' or choose an image from Gallery.\n2. Align camera on the crop leaf, fruit, or plant canopy.\n3. Pramaan AI will identify the crop, diagnose pathology, and prescribe treatments.",
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Diagnostic Result Card (Farmer-First & Bite-Sized)
                  if (_diagnosisResult != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Crop Name & Disease Alert Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF15803D),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _diagnosisResult!['crop_detected'] ?? _selectedCrop,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              _buildStatusBadge(_diagnosisResult!['health_status'], _diagnosisResult!['severity_level'], lang),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 2. Condition / Problem in Bold Large Text
                          Row(
                            children: [
                              Icon(
                                _isHealthy(_diagnosisResult!) ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                                color: _isHealthy(_diagnosisResult!) ? const Color(0xFF15803D) : AppColors.flaggedRed,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _diagnosisResult!['disease_detected'] ?? 'Diagnosis Complete',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: _isHealthy(_diagnosisResult!) ? const Color(0xFF15803D) : const Color(0xFF991B1B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // 3. Quick 3-Tile Status Bar
                          Row(
                            children: [
                              _buildQuickTile(
                                AppTranslations.tr(lang, "match_label", "Match"),
                                "${((_diagnosisResult!['confidence'] ?? 0.95) * 100).toInt()}%",
                                Icons.verified_user_rounded,
                                const Color(0xFF15803D),
                              ),
                              const SizedBox(width: 6),
                              _buildQuickTile(
                                AppTranslations.tr(lang, "damage_label", "Damage"),
                                "${_diagnosisResult!['affected_percentage'] ?? 0}%",
                                Icons.pie_chart_rounded,
                                Colors.orange.shade800,
                              ),
                              const SizedBox(width: 6),
                              _buildQuickTile(
                                AppTranslations.tr(lang, "urgency_label", "Urgency"),
                                _isHealthy(_diagnosisResult!) ? "Ready" : "${_diagnosisResult!['urgency_days'] ?? 1}d",
                                Icons.alarm_rounded,
                                _isHealthy(_diagnosisResult!) ? const Color(0xFF15803D) : AppColors.flaggedRed,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // 4. Primary Medicine & Spray Prescription Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _isHealthy(_diagnosisResult!) ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isHealthy(_diagnosisResult!) ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _isHealthy(_diagnosisResult!) ? Icons.eco_rounded : Icons.medication_liquid_rounded,
                                      color: _isHealthy(_diagnosisResult!) ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isHealthy(_diagnosisResult!)
                                          ? AppTranslations.tr(lang, "field_action", "Field Action:")
                                          : AppTranslations.tr(lang, "recommended_spray", "Recommended Spray:"),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: _isHealthy(_diagnosisResult!) ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _cleanMedicineSummary(_diagnosisResult!['recommended_active_ingredient']),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                                ),
                                if (_diagnosisResult!['organic_alternative'] != null && _diagnosisResult!['organic_alternative'] != "None needed") ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    "🌿 ${AppTranslations.tr(lang, 'desi_organic', 'Desi/Organic:')} ${_cleanOrganicSummary(_diagnosisResult!['organic_alternative'])}",
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 5. Short Action Tip (1-liner, no paragraphs)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_rounded, color: AppColors.accentGold, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _getBiteSizedTip(_diagnosisResult!, lang),
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),

                          // 6. Optional Collapsible Scientific Details
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(
                                AppTranslations.tr(lang, "view_scientific", "🔬 View Scientific & Prevention Details"),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                              ),
                              children: [
                                if (_diagnosisResult!['scientific_name'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Botanical Name: ${_diagnosisResult!['scientific_name']}",
                                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                if (_diagnosisResult!['symptoms'] is List)
                                  ...(_diagnosisResult!['symptoms'] as List).map(
                                    (s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("• ", style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                                          Expanded(child: Text(s.toString(), style: const TextStyle(fontSize: 11, color: Color(0xFF334155)))),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (_diagnosisResult!['prevention_tips'] is List)
                                  ...(_diagnosisResult!['prevention_tips'] as List).map(
                                    (t) => Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text("🛡️ ", style: TextStyle(fontSize: 10)),
                                          Expanded(child: Text(t.toString(), style: const TextStyle(fontSize: 10.5, color: Color(0xFF475569)))),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveEvidence,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                        label: Text(
                          AppTranslations.tr(lang, "save_spray_record", "SAVE SPRAY RECORD IN JOURNAL"),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanMedicineSummary(String? raw) {
    if (raw == null || raw.isEmpty) return "No chemical spray needed.";
    if (raw.contains("or")) {
      return raw.split("or")[0].trim();
    }
    return raw;
  }

  String _cleanOrganicSummary(String? raw) {
    if (raw == null || raw.isEmpty) return "Neem Oil 10,000 PPM (5 ml/L)";
    if (raw.contains("+")) {
      return raw.split("+")[0].trim();
    }
    return raw;
  }

  String _getBiteSizedTip(Map<String, dynamic> diag, String lang) {
    final isHealthy = _isHealthy(diag);
    final days = diag['urgency_days'] ?? 1;

    if (isHealthy) {
      if (lang == 'hi') return "फसल तंदुरुस्त है! साफ और सूखे मौसम में सुबह कटाई/तुड़ाई करें।";
      if (lang == 'pa') return "ਫ਼ਸਲ ਤੰਦਰੁਸਤ ਹੈ! ਸਾਫ਼ ਅਤੇ ਸੁੱਕੇ ਮੌਸਮ ਵਿੱਚ ਸਵੇਰੇ ਕਟਾਈ/ਚੁਗਾਈ ਕਰੋ।";
      if (lang == 'mr') return "पीक निरोगी आहे! स्वच्छ व कोरड्या हवामानात सकाळी काढणी करा.";
      return "Crop is healthy! Harvest during dry sunny morning hours.";
    }

    if (lang == 'hi') return "जरूरी: बीमारी रोकने के लिए अगले $days दिन में सुबह शांत हवा में स्प्रे करें।";
    if (lang == 'pa') return "ਜ਼ਰੂਰੀ: ਬਿਮਾਰੀ ਰੋਕਣ ਲਈ ਅਗਲੇ $days ਦਿਨ ਵਿੱਚ ਸਵੇਰੇ ਸ਼ਾਂਤ ਹਵਾ ਵਿੱਚ ਸਪਰੇਅ ਕਰੋ।";
    if (lang == 'mr') return "तातडी: रोग पसरू नये म्हणून पुढील $days दिवसात सकाळी शांत हवेत फवारणी करा.";
    return "Action Needed: Spray within $days day(s) during calm morning hours to stop disease spread.";
  }

  bool _isHealthy(Map<String, dynamic> diag) {
    final disease = (diag['disease_detected'] ?? '').toString().toLowerCase();
    final status = (diag['health_status'] ?? '').toString().toLowerCase();
    return disease.contains("healthy") || status.contains("healthy");
  }

  Widget _buildStatusBadge(String? status, String? severity, String lang) {
    final s = (status ?? '').toLowerCase();
    final sev = (severity ?? '').toLowerCase();

    Color bgColor = const Color(0xFF15803D);
    String label = AppTranslations.tr(lang, "healthy_crop", "Healthy Crop");

    if (s.contains("pest") || sev == "critical") {
      bgColor = const Color(0xFFDC2626);
      label = AppTranslations.tr(lang, "pest_alert", "Pest Alert");
    } else if (s.contains("disease") || sev == "high") {
      bgColor = AppColors.flaggedRed;
      label = AppTranslations.tr(lang, "disease_alert", "Disease Alert");
    } else if (sev == "medium") {
      bgColor = const Color(0xFFD97706);
      label = AppTranslations.tr(lang, "moderate_risk", "Moderate Risk");
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildQuickTile(String label, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: col),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(val, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: col)),
            ),
          ],
        ),
      ),
    );
  }
}
