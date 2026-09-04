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
import '../widgets/custom_bottom_nav.dart';

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
      "url":
          "https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800&auto=format&fit=crop&q=80",
      "crop": "Wheat",
    },
    {
      "title": "Cotton (Whitefly)",
      "url":
          "https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=800&auto=format&fit=crop&q=80",
      "crop": "Cotton",
    },
    {
      "title": "Tomato Early Blight Lesions",
      "url":
          "https://images.unsplash.com/photo-1592417817098-8f3d6eb22509?w=800&auto=format&fit=crop&q=80",
      "crop": "Tomato",
    },
    {
      "title": "Chilli Leaf Curl & Thrips Infestation",
      "url":
          "https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=800&auto=format&fit=crop&q=80",
      "crop": "Chilli",
    },
  ];

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
      final cropHint = _selectedCrop.contains("Auto-Detect")
          ? "Auto-Detect"
          : _selectedCrop;
      final result = await _api.analyzeVision(base64Str, cropHint);
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _diagnosisResult = result;
        });
        _showDiagnosisResultModal();
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
    final chemical =
        _diagnosisResult!['recommended_active_ingredient'] ??
        'Standard Foliar Treatment';

    await evProv.addEvidence(
      title: "Crop Scan: $detectedCrop • $disease",
      description:
          "$disease identified on $detectedCrop ($severity severity). Recommendation: $chemical.",
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
                child: Text(
                  "$detectedCrop diagnostic evidence sealed & saved to Farm Journal!",
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _showDiagnosisResultModal() {
    if (_diagnosisResult == null) return;
    final lang = Provider.of<AuthProvider>(context, listen: false).selectedLanguage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF047857),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _diagnosisResult!['crop_detected'] ?? _selectedCrop,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      "${((_diagnosisResult!['confidence'] ?? 0.96) * 100).toInt()}% Confidence",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Disease Name
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _diagnosisResult!['disease_detected'] ?? 'Diagnosis Complete',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Recommended Spray Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.medication_liquid_rounded, color: Color(0xFFB45309), size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Recommended Spray:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _cleanMedicineSummary(_diagnosisResult!['recommended_active_ingredient']),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    if (_diagnosisResult!['organic_alternative'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "🌿 Desi/Organic: ${_diagnosisResult!['organic_alternative']}",
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Farmer Tip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getBiteSizedTip(_diagnosisResult!, lang),
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF334155),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save to Journal Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _saveEvidence();
                  },
                  icon: const Icon(Icons.bookmark_add_rounded, size: 20),
                  label: const Text(
                    "SAVE SPRAY RECORD IN JOURNAL",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePreset = _presetSamples[_presetIndex];
    final authProv = Provider.of<AuthProvider>(context);
    final lang = authProv.selectedLanguage;

    final targetCrops = [
      {"label": "Auto-Detect", "icon": Icons.eco_rounded},
      {"label": "Wheat", "emoji": "🌾"},
      {"label": "Cotton", "emoji": "🌿"},
      {"label": "Other", "icon": Icons.eco_rounded},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Crop Doctor AI",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17.5,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          // Language Switcher Badge Button
          InkWell(
            onTap: () => AppTranslations.showLanguageSelectorModal(
              context,
              lang,
              (newLang) => authProv.setLanguage(newLang),
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    color: Color(0xFF047857),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lang.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF047857),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Crop Horizontal Selector
            Row(
              children: [
                const Text(
                  "Target Crop:",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: targetCrops.map((tc) {
                        final isSel = _selectedCrop == tc['label'] ||
                            (_selectedCrop.contains("Auto-Detect") && tc['label'] == "Auto-Detect");
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCrop = tc['label'] as String;
                              });
                              if (_capturedImageBytes != null || _diagnosisResult != null) {
                                _analyzeCurrentPhoto();
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF047857) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel ? const Color(0xFF047857) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (tc['emoji'] != null)
                                    Text(tc['emoji'] as String, style: const TextStyle(fontSize: 12))
                                  else if (tc['icon'] != null)
                                    Icon(
                                      tc['icon'] as IconData,
                                      size: 14,
                                      color: isSel ? Colors.white : const Color(0xFF047857),
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tc['label'] as String,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                      color: isSel ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Camera Viewfinder Box
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Leaf Image Canvas
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
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF047857),
                            ),
                          );
                        },
                      ),

                    // Center White Focus Target Overlay
                    Center(
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    if (_isAnalyzing)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF10B981),
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Diagnosing pathology...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Bottom Floating Instruction Pill
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "Align crop leaf or plant inside frame",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Try Sample Banner
            InkWell(
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
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_rounded,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _capturedFile != null
                            ? "Captured Photo"
                            : activePreset['title']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      "Try Sample >",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons Row (Take Photo, Gallery, Refresh)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _takePhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text(
                        "Take Photo",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _takePhoto(ImageSource.gallery),
                      icon: const Icon(Icons.image_rounded, size: 18, color: Color(0xFF047857)),
                      label: const Text(
                        "Gallery",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: Color(0xFF047857),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF047857), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: IconButton(
                    onPressed: _isAnalyzing ? null : _analyzeCurrentPhoto,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Color(0xFF047857),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Crop Doctor AI Guide Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Row(
                    children: [
                      Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF047857),
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        "Crop Doctor AI",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    "1. Tap 'Take Photo' or choose an image from Gallery.\n2. Align camera on the crop leaf, fruit, or plant canopy.\n3. Pramaan AI will identify the crop, diagnose pathology, and prescribe treatments.",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF1E293B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Recent Analyses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Recent Analyses",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, '/evidence_review'),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
                      "View All",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Recent Analyses List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildAnalysisItem(
                    imageUrl: "https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800&auto=format&fit=crop&q=80",
                    title: "Wheat Foliar (Stripe Rust)",
                    subtitle: "Detected with 96% confidence",
                    time: "2 days ago",
                    onTap: () {
                      setState(() {
                        _presetIndex = 0;
                        _selectedCrop = "Wheat";
                      });
                      _analyzeCurrentPhoto();
                    },
                  ),
                  const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9)),
                  _buildAnalysisItem(
                    imageUrl: "https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=800&auto=format&fit=crop&q=80",
                    title: "Cotton (Whitefly)",
                    subtitle: "Detected with 92% confidence",
                    time: "5 days ago",
                    onTap: () {
                      setState(() {
                        _presetIndex = 1;
                        _selectedCrop = "Cotton";
                      });
                      _analyzeCurrentPhoto();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: -1,
      ),
    );
  }

  Widget _buildAnalysisItem({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, _) => Container(
                  width: 44,
                  height: 44,
                  color: const Color(0xFFECFDF5),
                  child: const Icon(Icons.eco_rounded, color: Color(0xFF047857)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF047857),
                    size: 12,
                  ),
                  SizedBox(width: 3),
                  Text(
                    "Identified",
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  String _cleanMedicineSummary(String? raw) {
    if (raw == null || raw.isEmpty) return "Standard foliar fungicide / insecticide spray.";
    if (raw.contains("or")) {
      return raw.split("or")[0].trim();
    }
    return raw;
  }

  String _getBiteSizedTip(Map<String, dynamic> diag, String lang) {
    final days = diag['urgency_days'] ?? 1;
    if (lang == 'hi') {
      return "जरूरी: बीमारी रोकने के लिए अगले $days दिन में सुबह शांत हवा में स्प्रे करें।";
    }
    if (lang == 'pa') {
      return "ਜ਼ਰੂਰੀ: ਬਿਮਾਰੀ ਰੋਕਣ ਲਈ ਅਗਲੇ $days ਦਿਨ ਵਿੱਚ ਸਵੇਰੇ ਸ਼ਾਂਤ ਹਵਾ ਵਿੱਚ ਸਪਰੇਅ ਕਰੋ।";
    }
    if (lang == 'mr') {
      return "तातडी: रोग पसरू नये म्हणून पुढील $days दिवसात सकाळी शांत हवेत फवारणी करा.";
    }
    return "Action Needed: Spray within $days day(s) during calm morning hours to stop disease spread.";
  }
}

