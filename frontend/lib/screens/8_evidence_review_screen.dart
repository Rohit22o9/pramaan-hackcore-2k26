import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/evidence_provider.dart';
import '../widgets/evidence_card.dart';

class EvidenceReviewScreen extends StatelessWidget {
  const EvidenceReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final evProv = Provider.of<EvidenceProvider>(context);

    final filters = ['ALL', 'VERIFIED', 'PENDING', 'FLAGGED'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Evidence Verification Pipeline", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                children: filters.map((f) {
                  final isSelected = evProv.selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      selected: isSelected,
                      selectedColor: AppColors.primarySurface,
                      checkmarkColor: AppColors.primary,
                      onSelected: (val) {
                        if (val) evProv.setFilter(f);
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
                final auth = Provider.of<AuthProvider>(context, listen: false);
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
                                  Text("No ${evProv.selectedFilter} evidence items found.", style: const TextStyle(color: AppColors.textSecondary)),
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
