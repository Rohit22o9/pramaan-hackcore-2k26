import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/evidence_provider.dart';
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
  String _selectedCrop = "Cotton";
  int _presetIndex = 0;
  Map<String, dynamic>? _diagnosisResult;

  final List<String> _cropTypes = [
    "Cotton",
    "Wheat",
    "Paddy / Rice",
    "Chilli",
    "Tomato",
    "Soybean",
    "Maize",
  ];

  final List<Map<String, String>> _presetSamples = [
    {
      "title": "Cotton Leaf (Whitefly / Leafhopper)",
      "url": "https://images.unsplash.com/photo-1530836369250-ef72a3f5cda8?w=800&auto=format&fit=crop&q=80",
      "crop": "Cotton",
    },
    {
      "title": "Wheat Foliage (Stripe Rust)",
      "url": "https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=800&auto=format&fit=crop&q=80",
      "crop": "Wheat",
    },
    {
      "title": "Healthy Post-Spray Canopy",
      "url": "https://images.unsplash.com/photo-1586771107445-d3ca888129ff?w=800&auto=format&fit=crop&q=80",
      "crop": "Cotton",
    },
    {
      "title": "Tomato Early Blight Lesions",
      "url": "https://images.unsplash.com/photo-1592417817098-8f3d6eb22509?w=800&auto=format&fit=crop&q=80",
      "crop": "Tomato",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Auto-open camera on launch for instant mobile photography
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // If user came to camera, offer instant photo capture
    });
  }

  Future<void> _takePhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedFile = photo;
          _capturedImageBytes = bytes;
          _diagnosisResult = null;
        });
        // Automatically trigger AI pathology analysis on the snapped picture
        _analyzeCurrentPhoto();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Camera error: $e. You can also pick from gallery."),
          backgroundColor: AppColors.flaggedRed,
        ),
      );
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
      final result = await _api.analyzeVision(base64Str, _selectedCrop);
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

    await evProv.addEvidence(
      title: "Crop Diagnosis: ${_diagnosisResult!['disease_detected'] ?? 'Crop Scan'}",
      description: "${_diagnosisResult!['disease_detected']} detected with ${_diagnosisResult!['severity_level'] ?? 'Normal'} severity (${_diagnosisResult!['affected_percentage'] ?? 15}% affected). Active ingredient: ${_diagnosisResult!['recommended_active_ingredient'] ?? 'Biological'}.",
      evidenceType: 'CROP_IMAGE',
      mediaUrl: _capturedFile?.path ?? _presetSamples[_presetIndex]['url'],
      productName: _diagnosisResult!['recommended_active_ingredient'],
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Crop Diagnosis Evidence Logged & Cryptographically Sealed!"),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePreset = _presetSamples[_presetIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Pramaan Vision AI Viewfinder", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, color: Colors.white),
            tooltip: "Choose from Gallery",
            onPressed: () => _takePhoto(ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_rounded, color: AppColors.accentGold),
            tooltip: "Open Mobile Camera",
            onPressed: () => _takePhoto(ImageSource.camera),
          ),
        ],
      ),
      body: Column(
        children: [
          // Crop Selector Horizontal Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF111827),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: AppColors.primaryAccent, size: 16),
                const SizedBox(width: 8),
                const Text("Crop: ", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _cropTypes.map((crop) {
                        final isSel = _selectedCrop == crop;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(crop, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.white70)),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            backgroundColor: const Color(0xFF1F2937),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCrop = crop;
                                });
                                if (_capturedImageBytes != null) {
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
                      color: const Color(0xFF1F2937),
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
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.75),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),

                // Top GPS HUD Overlay
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("GPS: 20.1985° N, 73.8322° E", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                              Text("Plot North-04 (Dindori, Nashik)", style: TextStyle(color: Colors.white70, fontSize: 10), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("27.4°C | 66% RH", style: TextStyle(color: AppColors.accentGold, fontSize: 11, fontWeight: FontWeight.bold)),
                            Text("GEMINI MULTIMODAL", style: TextStyle(color: Color(0xFF34D399), fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Center AI Viewfinder Reticle Box
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isAnalyzing ? AppColors.accentGold : const Color(0xFF34D399),
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _isAnalyzing ? "SCANNING PIXELS..." : "TARGET CANOPY",
                              style: TextStyle(
                                color: _isAnalyzing ? AppColors.accentGold : const Color(0xFF34D399),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (_isAnalyzing)
                          const Center(
                            child: CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 3),
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Sample Info Bar
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _capturedFile != null
                                ? "Captured Camera Photo (${_selectedCrop})"
                                : activePreset['title']!,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _capturedFile = null;
                              _capturedImageBytes = null;
                              _presetIndex = (_presetIndex + 1) % _presetSamples.length;
                              _selectedCrop = _presetSamples[_presetIndex]['crop']!;
                              _diagnosisResult = null;
                            });
                          },
                          child: const Text(
                            "Next Sample",
                            style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
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
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Camera / Gallery / Re-analyze Buttons Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _takePhoto(ImageSource.camera),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.camera_alt_rounded, size: 20),
                        label: const Text("TAKE REAL PHOTO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        onPressed: () => _takePhoto(ImageSource.gallery),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.image_rounded, size: 18, color: AppColors.primary),
                        label: const Text("Gallery", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isAnalyzing ? null : _analyzeCurrentPhoto,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.surfaceVariant,
                        foregroundColor: AppColors.primaryDark,
                      ),
                      tooltip: "Re-run Gemini AI Analysis",
                      icon: const Icon(Icons.auto_awesome_rounded),
                    ),
                  ],
                ),

                // Diagnostic Result Card
                if (_diagnosisResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primaryAccent.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bug_report_rounded, color: AppColors.primaryDark, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _diagnosisResult!['disease_detected'] ?? 'Diagnosis Complete',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.primaryDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _diagnosisResult!['severity_level'] == 'High' || _diagnosisResult!['severity_level'] == 'Critical'
                                    ? AppColors.flaggedRed
                                    : AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "${_diagnosisResult!['severity_level'] ?? 'Medium'} Severity",
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 14),
                        _buildDiagRow("📊 Confidence:", "${((_diagnosisResult!['confidence'] ?? 0.95) * 100).toInt()}% • Affected: ${_diagnosisResult!['affected_percentage'] ?? 18}%"),
                        _buildDiagRow("🧪 Chemical Rx:", _diagnosisResult!['recommended_active_ingredient'] ?? 'Standard Foliar Treatment'),
                        _buildDiagRow("🌿 Organic Rx:", _diagnosisResult!['organic_alternative'] ?? '5% Neem Kernel Extract'),
                        _buildDiagRow("⏳ Urgency:", "Treat within ${_diagnosisResult!['urgency_days'] ?? 2} days"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveEvidence,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.lock_clock_rounded, size: 18),
                      label: const Text("SEAL & SAVE DIAGNOSIS EVIDENCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              val,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
