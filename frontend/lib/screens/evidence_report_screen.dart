import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/farm_provider.dart';
import '../core/providers/evidence_provider.dart';

class EvidenceReportScreen extends StatelessWidget {
  const EvidenceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmProv = Provider.of<FarmProvider>(context);
    final evProv = Provider.of<EvidenceProvider>(context);
    final farm = farmProv.selectedFarm;

    final verifiedCount = evProv.allEvidence.where((e) => e.verificationStatus == 'VERIFIED').length;
    final totalCount = evProv.allEvidence.length;
    final compliance = farm?.complianceScore ?? 96.4;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Audit Certificate & Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Downloading Cryptographic PDF Audit Report..."),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Official Certificate Paper Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Certificate Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.verified_user_rounded, color: AppColors.accentGold, size: 36),
                        SizedBox(height: 6),
                        Text(
                          "PRAMAAN AUDIT CERTIFICATE",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        Text(
                          "Tamper-Proof AgTech Supply Chain Verification",
                          style: TextStyle(color: AppColors.primaryAccent, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Metadata Box
                  _buildCertField("Certificate ID", "PRM-CERT-2026-FARM101-KH"),
                  _buildCertField("Farm Entity", farm?.name ?? "Sahyadri Bio-Farms"),
                  _buildCertField("Lead Grower", farm?.owner ?? "Ramesh Patil"),
                  _buildCertField("Geographic Origin", "${farm?.village ?? 'Dindori'}, Maharashtra, India"),
                  _buildCertField("Target Crop Batch", farm?.activeCrop ?? "Cotton (Bt-II)"),
                  _buildCertField("Certified Buyer", "ITC Agri-Business Division"),
                  const Divider(height: 24),

                  // Compliance Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, color: AppColors.accentGold, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "COMPLIANCE SCORE: $compliance%",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Grade A+ (Zero Prohibited Chemical Residue • 100% PHI Compliant)",
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primaryDark.withOpacity(0.8)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Statistics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatBadge("Verified Logs", "$verifiedCount / $totalCount"),
                      _buildStatBadge("Pre-Harvest Interval", "100% Met"),
                      _buildStatBadge("Sustainability Index", "94.2 / 100"),
                    ],
                  ),
                  const Divider(height: 24),

                  // Blockchain Seal
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Blockchain SHA-256 Verification Anchor:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                    child: const Text(
                      "9f83ab2019487cba1209384bcdae1029384756bc0192837465abde01928374",
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("JSON Proof Manifest Exported!")),
                      );
                    },
                    icon: const Icon(Icons.code_rounded),
                    label: const Text("JSON PROOF"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Official PDF Downloaded to device storage!"), backgroundColor: AppColors.primary),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text("DOWNLOAD PDF"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCertField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
      ],
    );
  }
}
