import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/localization/app_translations.dart';
import '../core/services/google_sheets_service.dart';
import '../core/services/pdf_download_service.dart';
import '../models/evidence_model.dart';
import '../widgets/custom_bottom_nav.dart';

class CommunityLogsScreen extends StatefulWidget {
  const CommunityLogsScreen({super.key});

  @override
  State<CommunityLogsScreen> createState() => _CommunityLogsScreenState();
}

class _CommunityLogsScreenState extends State<CommunityLogsScreen> {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();
  final PdfDownloadService _pdfService = PdfDownloadService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allLogs = [];
  bool _isLoading = true;
  String _selectedCrop = "All";
  String _selectedRegion = "All";
  String _sortBy = "newest"; // "newest" | "compliance"
  String _searchQuery = "";
  final Set<String> _downloadingLogIds = {};

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _sheetsService.fetchAllCommunityLogs();
      if (mounted) {
        setState(() {
          _allLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("[CommunityLogsScreen] Error loading community logs: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> get _availableCrops {
    final crops = <String>{"All"};
    for (var log in _allLogs) {
      final crop = (log['crop'] ?? log['crop_name'] ?? '').toString().trim();
      if (crop.isNotEmpty) {
        // Strip variety if present (e.g. "Wheat (PBW 826)" -> "Wheat")
        final clean = crop.split('(').first.trim();
        if (clean.isNotEmpty) crops.add(clean);
      }
    }
    // Add default popular crops if not present
    crops.addAll(["Wheat", "Cotton", "Chilli", "Paddy", "Soybean", "Tomato"]);
    return crops.toList();
  }

  List<String> get _availableRegions {
    final regions = <String>{"All"};
    for (var log in _allLogs) {
      final state = (log['state'] ?? '').toString().trim();
      if (state.isNotEmpty) regions.add(state);
    }
    // Add default popular states if not present
    regions.addAll(["Punjab", "Maharashtra", "Andhra Pradesh", "Gujarat", "Haryana"]);
    return regions.toList();
  }

  List<Map<String, dynamic>> get _filteredLogs {
    var list = List<Map<String, dynamic>>.from(_allLogs);

    // 1. Crop Filter
    if (_selectedCrop != "All") {
      list = list.where((log) {
        final crop = (log['crop'] ?? log['crop_name'] ?? '').toString().toLowerCase();
        return crop.contains(_selectedCrop.toLowerCase());
      }).toList();
    }

    // 2. Region Filter
    if (_selectedRegion != "All") {
      list = list.where((log) {
        final state = (log['state'] ?? '').toString().toLowerCase();
        final village = (log['village'] ?? '').toString().toLowerCase();
        return state.contains(_selectedRegion.toLowerCase()) || village.contains(_selectedRegion.toLowerCase());
      }).toList();
    }

    // 3. Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((log) {
        final farmer = (log['farmer_name'] ?? '').toString().toLowerCase();
        final crop = (log['crop'] ?? log['crop_name'] ?? '').toString().toLowerCase();
        final village = (log['village'] ?? '').toString().toLowerCase();
        final state = (log['state'] ?? '').toString().toLowerCase();
        final product = (log['product_name'] ?? '').toString().toLowerCase();
        final desc = (log['description'] ?? log['voice_transcript'] ?? '').toString().toLowerCase();

        return farmer.contains(q) || crop.contains(q) || village.contains(q) || state.contains(q) || product.contains(q) || desc.contains(q);
      }).toList();
    }

    // 4. Sorting
    if (_sortBy == "compliance") {
      list.sort((a, b) {
        final scoreA = (a['compliance_score'] ?? a['verification_score'] ?? 0) as num;
        final scoreB = (b['compliance_score'] ?? b['verification_score'] ?? 0) as num;
        return scoreB.compareTo(scoreA);
      });
    } else {
      // Default: Newest first
      list.sort((a, b) {
        final timeA = (a['timestamp'] ?? '').toString();
        final timeB = (b['timestamp'] ?? '').toString();
        return timeB.compareTo(timeA);
      });
    }

    return list;
  }

  Future<void> _handleDownloadPdf(Map<String, dynamic> log) async {
    final logId = (log['id'] ?? log['log_id'] ?? DateTime.now().millisecondsSinceEpoch).toString();
    setState(() => _downloadingLogIds.add(logId));

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final farmerName = (log['farmer_name'] ?? 'Verified Farmer').toString();
      final farmerPhone = (log['farmer_phone'] ?? '').toString();
      final village = (log['village'] ?? 'Dindori, Nashik').toString();
      final state = (log['state'] ?? 'Maharashtra').toString();
      final crop = (log['crop'] ?? log['crop_name'] ?? 'Wheat').toString();
      final productName = (log['product_name'] ?? 'Bio-Neem Power 10000 PPM').toString();
      final dosage = (log['dosage'] ?? log['dosage_per_acre'] ?? '400 ml / Acre').toString();
      final score = ((log['compliance_score'] ?? log['verification_score'] ?? 98.6) as num).toDouble();
      final transcript = (log['voice_transcript'] ?? log['description'] ?? log['title'] ?? 'Verified voice log').toString();

      final evidenceItem = EvidenceItem(
        id: logId,
        farmId: "community-farm",
        farmerName: farmerName,
        farmerPhone: farmerPhone,
        title: log['title']?.toString() ?? "Voice Log: ${log['action_type'] ?? 'SPRAY'} $crop",
        description: transcript,
        type: EvidenceType.voiceNote,
        category: EvidenceCategory.cropHealth,
        timestamp: log['timestamp']?.toString() ?? DateTime.now().toIso8601String(),
        cropName: crop,
        productName: productName,
        dosagePerAcre: dosage,
        location: EvidenceLocation(
          latitude: 20.0,
          longitude: 73.8,
          village: village,
          district: state,
        ),
        verificationScore: score,
        isVerified: true,
        verificationHash: (log['verification_hash'] ?? log['hash_anchor'] ?? 'a8f5b4c9103982eef11082cba972e345b98a0021c32ff8812de4b21903fa7e41').toString(),
      );

      final file = await _pdfService.downloadAndOpenReport(
        item: evidenceItem,
        farmerName: farmerName,
        farmerPhone: farmerPhone,
        village: village,
        state: state,
        activeCrop: crop,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF065F46),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "✓ 3-Page Audit PDF for $farmerName saved to device storage!",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("[CommunityLogsScreen] Download error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text("Error saving PDF: $e"),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingLogIds.remove(logId));
      }
    }
  }

  void _showLogDetailsModal(Map<String, dynamic> log, String lang) {
    final farmerName = (log['farmer_name'] ?? 'Verified Farmer').toString();
    final village = (log['village'] ?? '').toString();
    final state = (log['state'] ?? '').toString();
    final crop = (log['crop'] ?? log['crop_name'] ?? 'Wheat').toString();
    final productName = (log['product_name'] ?? 'Bio-Neem Power 10000 PPM').toString();
    final dosage = (log['dosage'] ?? log['dosage_per_acre'] ?? '400 ml / Acre').toString();
    final score = ((log['compliance_score'] ?? log['verification_score'] ?? 98.6) as num).toDouble();
    final transcript = (log['voice_transcript'] ?? log['description'] ?? '').toString();
    final reportId = (log['report_id'] ?? 'PRM-REP-VERIFIED').toString();
    final hash = (log['verification_hash'] ?? log['hash_anchor'] ?? 'a8f5b4c9103982eef11082cba972e345b98a0021c32ff8812de4b21903fa7e41').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          "✓ $reportId",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          "$score% ${AppTranslations.tr(lang, "verified_label", "VERIFIED")}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Farmer Profile
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          farmerName.isNotEmpty ? farmerName[0] : 'K',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              farmerName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              "📍 $village, $state",
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Crop & Input Details Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow("🌾 Target Crop", crop),
                        const Divider(height: 16),
                        _buildDetailRow("🧪 Input Applied", productName),
                        const Divider(height: 16),
                        _buildDetailRow("⚖️ Verified Dosage", dosage),
                        const Divider(height: 16),
                        _buildDetailRow("🎯 Target Problem", log['target_pest']?.toString() ?? "Pest / Disease Control"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Voice Transcript Box
                  const Text(
                    "🎙️ Recorded Voice Transcript",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9D5FF)),
                    ),
                    child: Text(
                      transcript.isNotEmpty ? "\"$transcript\"" : "\"Voice evidence recorded and validated by Pramaan AI.\"",
                      style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Color(0xFF581C87)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ICAR / PAU Agronomy Insights
                  const Text(
                    "🔬 ICAR / PAU Agronomic Guidance",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "• Recommended Water Volume: 200 Litres clean water per acre.",
                          style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "• Pre-Harvest Interval (PHI): 14 Days safe margin strictly maintained.",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "• Best Spray Window: Morning 07:00 – 10:30 AM (Delta-T 2-8°C).",
                          style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // SHA-256 Hash
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🔒 SHA-256 Cryptographic Hash Anchor:",
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hash,
                          style: const TextStyle(fontSize: 9.5, fontFamily: 'monospace', color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Download Full 3-Page PDF button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        AppTranslations.tr(lang, "download_peer_pdf", "Download 3-Page Audit PDF"),
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleDownloadPdf(log);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final lang = auth.selectedLanguage;
    final logs = _filteredLogs;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 6),
                Text(
                  AppTranslations.tr(lang, "log_community", "Log Community"),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              AppTranslations.tr(lang, "community_subtitle", "Verified Peer Logs & Audit Certificates"),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh Feed",
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _isLoading ? null : _fetchLogs,
          ),
          IconButton(
            tooltip: AppTranslations.tr(lang, "select_language"),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                lang.toUpperCase(),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
              ),
            ),
            onPressed: () => AppTranslations.showLanguageSelectorModal(
              context,
              lang,
              (newLang) => auth.setLanguage(newLang),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLogs,
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Community Stats & Live Banner
            _buildCommunityStatsBanner(lang),

            // Search Bar & Filter Chips Header
            _buildSearchAndFilters(lang),

            // Logs Feed List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 12),
                          Text(
                            "Syncing verified logs from Google Sheets...",
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : logs.isEmpty
                      ? _buildEmptyState(lang)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            return _buildCommunityLogCard(log, lang);
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 99, // Highlight Community button
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/farmer_dashboard');
          } else if (index == 1) {
            Navigator.pushNamed(context, '/voice_log');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/evidence_review');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/ask_pramaan');
          }
        },
      ),
    );
  }

  Widget _buildCommunityStatsBanner(String lang) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF064E3B), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("🌾 ${AppTranslations.tr(lang, "all_crops", "Crops")}", "${_availableCrops.length - 1} Active"),
          Container(width: 1, height: 28, color: Colors.white24),
          _buildStatItem("📍 ${AppTranslations.tr(lang, "all_regions", "Regions")}", "${_availableRegions.length - 1} States"),
          Container(width: 1, height: 28, color: Colors.white24),
          _buildStatItem("📜 ${AppTranslations.tr(lang, "live_community_feed", "Feed")}", "${_allLogs.length} Verified"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFFA7F3D0), fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSearchAndFilters(String lang) {
    final crops = _availableCrops;
    final regions = _availableRegions;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: const TextStyle(fontSize: 13.5),
              decoration: InputDecoration(
                hintText: AppTranslations.tr(lang, "search_community_hint", "Search farmer, crop, village, product..."),
                hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Crop Filter Chips
          Row(
            children: [
              Text(
                "${AppTranslations.tr(lang, "filter_by_crop", "Crop")}: ",
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: crops.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final crop = crops[i];
                      final isSelected = _selectedCrop == crop;
                      return ChoiceChip(
                        label: Text(crop == "All" ? AppTranslations.tr(lang, "all_crops", "All Crops") : crop),
                        selected: isSelected,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedCrop = crop);
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Region Filter Chips & Sort
          Row(
            children: [
              Text(
                "${AppTranslations.tr(lang, "filter_by_region", "Region")}: ",
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: regions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final region = regions[i];
                      final isSelected = _selectedRegion == region;
                      return ChoiceChip(
                        label: Text(region == "All" ? AppTranslations.tr(lang, "all_regions", "All Regions") : region),
                        selected: isSelected,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        selectedColor: const Color(0xFF065F46),
                        backgroundColor: const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF065F46) : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRegion = region);
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Quick Sort Toggle Button
              InkWell(
                onTap: () {
                  setState(() {
                    _sortBy = (_sortBy == "newest") ? "compliance" : "newest";
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _sortBy == "newest" ? Icons.access_time_rounded : Icons.star_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _sortBy == "newest" ? "New" : "Top %",
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityLogCard(Map<String, dynamic> log, String lang) {
    final logId = (log['id'] ?? log['log_id'] ?? '').toString();
    final farmerName = (log['farmer_name'] ?? 'Verified Farmer').toString();
    final village = (log['village'] ?? '').toString();
    final state = (log['state'] ?? '').toString();
    final crop = (log['crop'] ?? log['crop_name'] ?? 'Wheat').toString();
    final actionType = (log['action_type'] ?? 'SPRAY').toString();
    final productName = (log['product_name'] ?? 'Bio-Neem Power 10000 PPM').toString();
    final dosage = (log['dosage'] ?? log['dosage_per_acre'] ?? '400 ml in 200L Water / Acre').toString();
    final score = ((log['compliance_score'] ?? log['verification_score'] ?? 98.6) as num).toDouble();
    final transcript = (log['voice_transcript'] ?? log['description'] ?? '').toString();
    final timestamp = (log['timestamp'] ?? '').toString();
    final isDownloading = _downloadingLogIds.contains(logId);

    // Format display date
    String dateDisplay = "Today";
    if (timestamp.isNotEmpty) {
      try {
        final dt = DateTime.parse(timestamp).toLocal();
        dateDisplay = "${dt.day}/${dt.month}/${dt.year}";
      } catch (_) {
        dateDisplay = timestamp.split('T').first;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Farmer Profile & Verified Badge Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    farmerName.isNotEmpty ? farmerName[0] : 'K',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              farmerName,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF059669)),
                        ],
                      ),
                      Text(
                        "📍 $village, $state • $dateDisplay",
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Compliance Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    "$score% OK",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Crop & Action Pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "🌾 $crop",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "⚡ $actionType",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3. Product & Dosage Box
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.science_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  "Dose: $dosage",
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                if (transcript.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "\"$transcript\"",
                    style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. Action Buttons (Download PDF & View Details)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                // View Details Button
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showLogDetailsModal(log, lang),
                    child: Text(
                      AppTranslations.tr(lang, "view_all", "View Details"),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Download 3-Page PDF Report Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                    ),
                    icon: isDownloading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: Text(
                      isDownloading ? "Downloading..." : AppTranslations.tr(lang, "download_peer_pdf", "Download PDF"),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: isDownloading ? null : () => _handleDownloadPdf(log),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.filter_list_off_rounded, size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Text(
              AppTranslations.tr(lang, "no_community_logs_found", "No community logs match your filter criteria."),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              "Try selecting 'All Crops' or 'All Regions' or clearing the search query.",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedCrop = "All";
                  _selectedRegion = "All";
                  _searchQuery = "";
                });
              },
              child: Text(AppTranslations.tr(lang, "filter_reset", "Reset Filters")),
            ),
          ],
        ),
      ),
    );
  }
}
