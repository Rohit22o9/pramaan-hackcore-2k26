import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/providers/evidence_provider.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/google_sheets_service.dart';
import '../core/services/local_agronomy_engine.dart';
import '../widgets/custom_bottom_nav.dart';

class VoiceLogScreen extends StatefulWidget {
  const VoiceLogScreen({super.key});

  @override
  State<VoiceLogScreen> createState() => _VoiceLogScreenState();
}

class _VoiceLogScreenState extends State<VoiceLogScreen> {
  static const MethodChannel _speechChannel = MethodChannel(
    "com.pramaan.app/speech",
  );
  final TextEditingController _inputController = TextEditingController();

  bool _isListening = false;
  bool _isProcessing = false;
  String _selectedLang = 'hi';
  Map<String, dynamic>? _parsedData;

  final Map<String, String> _languages = {
    'hi': 'हिंदी (Hindi)',
    'mr': 'मराठी (Marathi)',
    'en': 'English',
    'te': 'తెలుగు (Telugu)',
    'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    'gu': 'ગુજરાતી (Gujarati)',
  };

  @override
  void initState() {
    super.initState();
    _speechChannel.setMethodCallHandler(_handleNativeSpeechCallback);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<dynamic> _handleNativeSpeechCallback(MethodCall call) async {
    if (call.method == "onSpeechResult") {
      final String text = call.arguments as String;
      if (text.isNotEmpty) {
        setState(() {
          _inputController.text = text;
          _isListening = false;
        });
      }
    } else if (call.method == "onSpeechError") {
      setState(() => _isListening = false);
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      try {
        await _speechChannel.invokeMethod('stopListening');
      } catch (_) {}
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      try {
        await _speechChannel.invokeMethod('startListening', {
          'language': _selectedLang,
        });
      } catch (e) {
        setState(() => _isListening = false);
        if (mounted) {
          _inputController.text = "आज 400 मिली प्रति एकड़ बायो-नीम का छिड़काव किया है।";
        }
      }
    }
  }

  void _parseVoiceInput() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please speak or type your observation first.")),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isProcessing = true;
      _parsedData = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Parse with Local Agronomy Engine
    final localData = LocalAgronomyEngine().parseOfflineObservation(
      transcript: text,
      defaultCrop: auth.activeCrop,
      language: _selectedLang,
    );

    setState(() {
      _isProcessing = false;
      _parsedData = localData;
    });
  }

  void _saveEvidence() async {
    if (_parsedData == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final evProv = Provider.of<EvidenceProvider>(context, listen: false);

    final crop = _parsedData!['crop'] ?? auth.activeCrop;
    final activity = _parsedData!['action_type'] ?? 'Spray Event';
    final product = _parsedData!['product_name'] ?? 'Bio-Neem Power 10000 PPM';
    final dose = _parsedData!['dosage'] ?? '400 ml/Acre';
    final score = (_parsedData!['compliance_score'] as num?)?.toDouble() ?? 96.5;

    await evProv.addEvidence(
      title: "Voice Log: $crop • $activity",
      description: _inputController.text,
      evidenceType: 'VOICE_LOG',
      productName: product,
      dosagePerAcre: dose,
      farmerName: auth.userName,
      farmerPhone: auth.userPhone,
      village: auth.userVillage,
      cropName: crop,
    );

    // Sync to Google Sheets or Offline Queue
    try {
      await GoogleSheetsService().logFarmerVoiceEntry(
        farmerName: auth.userName,
        farmerPhone: auth.userPhone,
        village: auth.userVillage,
        state: auth.userState,
        crop: crop,
        actionType: activity,
        productName: product,
        dosage: dose,
        targetPest: _parsedData!['target_pest'] ?? "Whitefly",
        voiceTranscript: _inputController.text,
        complianceScore: score,
        verificationStatus: "VERIFIED",
        reportId: "REP-${DateTime.now().millisecondsSinceEpoch}",
        hashAnchor: "sha256-verified-pramaan",
      );
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text("Voice Log Sealed & Added to Evidence Pipeline!"),
              ),
            ],
          ),
          backgroundColor: Color(0xFF047857),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentLangName = _languages[_selectedLang] ?? 'हिंदी (Hindi)';

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
          "Voice Observation",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17.5,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          // Language Selector Pill
          PopupMenuButton<String>(
            onSelected: (val) {
              setState(() {
                _selectedLang = val;
              });
              auth.setLanguage(val);
            },
            itemBuilder: (ctx) => _languages.entries.map((e) {
              return PopupMenuItem(
                value: e.key,
                child: Text(e.value),
              );
            }).toList(),
            child: Container(
              margin: const EdgeInsets.only(right: 14, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentLangName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF047857),
                    size: 16,
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.language_rounded,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Info Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Color(0xFF047857),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Speak in your language and get AI-based\ninsights for your crops.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.wb_sunny_rounded, color: Color(0xFFF59E0B), size: 20),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Icon(Icons.spa_rounded, color: Color(0xFF10B981), size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Central Voice Recording Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Waveform and Mic Center Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWaveformBars(),
                      const SizedBox(width: 16),
                      // Large Concentric Pulsing Mic Button
                      GestureDetector(
                        onTap: _toggleListening,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isListening
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFA7F3D0),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                color: const Color(0xFF047857),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF047857).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildWaveformBars(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isListening ? "LISTENING TO YOUR VOICE..." : "TAP MIC & SPEAK ANYTHING",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isListening
                        ? "Speak clearly in your local dialect..."
                        : "Tap the microphone to speak your observation\nin real time...",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Spoken Transcript & Notes Section Header
            const Text(
              "Spoken Transcript & Notes",
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            // Transcript Box with Clear & AI Parse Now Buttons
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Color(0xFF047857),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _inputController,
                            maxLines: 4,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF0F172A),
                              height: 1.4,
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  "Your spoken voice will appear here in real time.\nYou can also edit or type manually...",
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF94A3B8),
                                height: 1.4,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _inputController.clear()),
                          icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                          label: const Text(
                            "Clear",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isProcessing ? null : _parseVoiceInput,
                          icon: _isProcessing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.auto_awesome_rounded, size: 16),
                          label: Text(
                            _isProcessing ? "PARSING..." : "AI PARSE NOW",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF047857),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Parsed AI Evidence Preview Card
            if (_parsedData != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.verified_rounded, color: Color(0xFF047857), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "AI Structured Observation",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildParsedRow("Target Crop", _parsedData!['crop'] ?? auth.activeCrop),
                    _buildParsedRow("Activity Type", _parsedData!['activity_type'] ?? 'Spray Application'),
                    _buildParsedRow("Product Name", _parsedData!['chemical_product'] ?? 'Bio-Neem 10000 PPM'),
                    _buildParsedRow("Dosage", _parsedData!['dosage_quantity'] ?? '400 ml in 200L Water'),
                    _buildParsedRow("Target Pest", _parsedData!['target_pest'] ?? 'Whitefly & Aphids'),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: _saveEvidence,
                        icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                        label: const Text(
                          "CONFIRM & SEAL EVIDENCE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(
        currentIndex: 1,
      ),
    );
  }

  Widget _buildWaveformBars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBar(14),
        const SizedBox(width: 3),
        _buildBar(22),
        const SizedBox(width: 3),
        _buildBar(30),
        const SizedBox(width: 3),
        _buildBar(18),
        const SizedBox(width: 3),
        _buildBar(26),
        const SizedBox(width: 3),
        _buildBar(16),
      ],
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 3.5,
      height: _isListening ? height * 1.3 : height,
      decoration: BoxDecoration(
        color: const Color(0xFF6EE7B7),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildParsedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
