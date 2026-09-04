import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/evidence_provider.dart';
import '../core/localization/app_translations.dart';
import '../widgets/evidence_card.dart';

class EvidenceReviewScreen extends StatelessWidget {
  const EvidenceReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final evProv = Provider.of<EvidenceProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final lang = auth.selectedLanguage;

    final filterKeys = [
      {'code': 'ALL', 'label': AppTranslations.tr(lang, 'filter_all')},
      {'code': 'VERIFIED', 'label': AppTranslations.tr(lang, 'filter_verified')},
      {'code': 'PENDING', 'label': AppTranslations.tr(lang, 'filter_pending')},
      {'code': 'FLAGGED', 'label': AppTranslations.tr(lang, 'filter_flagged')},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppTranslations.tr(lang, 'evidence_pipeline_title', "Evidence Verification Pipeline"),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            tooltip: "Audit Report",
            onPressed: () => Navigator.pushNamed(context, '/evidence_report'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Strip
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterKeys.map((f) {
                  final code = f['code']!;
                  final label = f['label']!;
                  final isSelected = evProv.selectedFilter == code;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: AppColors.primarySurface,
                      checkmarkColor: AppColors.primary,
                      onSelected: (val) {
                        if (val) evProv.setFilter(code);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Evidence List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await evProv.loadEvidenceForFarmer(phone: auth.userPhone, name: auth.userName);
              },
              child: evProv.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : evProv.evidenceList.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 12),
                                  Text(
                                    lang == 'mr'
                                        ? "कोणतीही नोंद आढळली नाही."
                                        : lang == 'hi'
                                            ? "कोई रिकॉर्ड नहीं मिला।"
                                            : lang == 'pa'
                                                ? "ਕੋਈ ਰਿਕਾਰਡ ਨਹੀਂ ਮਿਲਿਆ।"
                                                : "No ${evProv.selectedFilter} evidence items found.",
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: evProv.evidenceList.length,
                          itemBuilder: (context, index) {
                            final item = evProv.evidenceList[index];
                            return EvidenceCard(
                              item: item,
                              onTap: () => Navigator.pushNamed(context, '/evidence_detail', arguments: item),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

