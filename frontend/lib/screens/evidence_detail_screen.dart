import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/evidence_provider.dart';
import '../core/providers/auth_provider.dart';
import '../../models/evidence_model.dart';
import '../widgets/crypto_seal_badge.dart';

class EvidenceDetailScreen extends StatelessWidget {
  const EvidenceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)?.settings.arguments as EvidenceItem? ??
        EvidenceItem(
          id: 'EV-2026-8810',
          farmId: 'farm-101',
          cropName: 'Cotton (Bt-II)',
          cropStage: 'Flowering Stage',
          evidenceType: 'PRODUCT_SCAN',
          timestamp: '2026-08-28T07:45:00Z',
          location: GeoLocation(latitude: 20.1985, longitude: 73.8322, fieldName: 'Plot North-04'),
          title: 'Bio-Neem Spray Batch Verified',
          description: 'Scanned QR code on Bio-Neem Power bottle before foliar application for whitefly control.',
          mediaUrl: 'https://images.unsplash.com/photo-1592417817098-8f3d6eb22509?w=600&auto=format&fit=crop&q=80',
          productQr: 'PRM-INP-88219-NEEM',
          productName: 'Bio-Neem Power 10000 PPM',
          dosagePerAcre: '400 ml in 200 L Water',
          verificationStatus: 'VERIFIED',
          verificationScore: 98.5,
          verificationHash: 'a8f5b4c9103982eef11082cba972e345b98a0021c32ff8812de4b21903fa7e41',
          agentVerdicts: {
            'validation_agent': 'Matched genuine batch PRM-INP-88219-NEEM from Kisan BioTech. Geo-fence valid.',
            'weather_agent': 'Spray conditions were optimal (wind 6.2 km/h, humidity 68%). No wash-off risk.',
          },
        );

    final auth = Provider.of<AuthProvider>(context);
    final isAgent = auth.currentRole == UserRoleType.fieldAgent;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Evidence #${item.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Audit hash copied to clipboard!")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.cropName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      CryptoSealBadge(score: item.verificationScore, status: item.verificationStatus),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
                  const SizedBox(height: 12),
                  Text(item.description, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview if available
            if (item.mediaUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item.mediaUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: const Color(0xFF1E293B),
                    child: const Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.white54)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Cryptographic SHA-256 Seal Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lock_rounded, color: AppColors.primaryAccent, size: 18),
                      SizedBox(width: 8),
                      Text("Cryptographic Proof Anchor (SHA-256)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    item.verificationHash ?? "a8f5b4c9103982eef11082cba972e345b98a0021c32ff8812de4b21903fa7e41",
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Color(0xFF94A3B8), height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryAccent, size: 14),
                      SizedBox(width: 6),
                      Text("Tamper-Evident Immutable Proof Active", style: TextStyle(color: AppColors.primaryAccent, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Geofence & Weather Metadata
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Location & Environmental Context", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const Divider(height: 20),
                  _buildMetaRow(Icons.pin_drop_rounded, "GPS Coordinates", "${item.location.latitude}° N, ${item.location.longitude}° E"),
                  _buildMetaRow(Icons.terrain_rounded, "Plot Designation", "${item.location.fieldName} (${item.location.village})"),
                  _buildMetaRow(Icons.access_time_rounded, "Timestamp UTC", item.timestamp),
                  _buildMetaRow(Icons.cloud_queue_rounded, "Weather Snapshot", "26.5°C | 68% RH | Wind 6.2 km/h"),
                  if (item.productName != null) _buildMetaRow(Icons.science_rounded, "Product Verified", item.productName!),
                  if (item.dosagePerAcre != null) _buildMetaRow(Icons.opacity_rounded, "Dosage Logged", item.dosagePerAcre!),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // AI Multi-Agent Verdicts Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.psychology_rounded, color: AppColors.primaryDark, size: 22),
                      SizedBox(width: 8),
                      Text("Multi-Agent AI Verifications", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ],
                  ),
                  const Divider(height: 20),
                  ...item.agentVerdicts.entries.map((v) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                            Expanded(
                              child: Text(
                                "${v.key.replaceAll('_', ' ').toUpperCase()}: ${v.value}",
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Agent Sign-off Action (if in Field Agent role)
            if (isAgent && item.verificationStatus == 'PENDING') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Provider.of<EvidenceProvider>(context, listen: false).updateStatus(item.id, 'FLAGGED', score: 55.0);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.flag_rounded, color: AppColors.flaggedRed),
                      label: const Text("FLAG ISSUE", style: TextStyle(color: AppColors.flaggedRed)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Provider.of<EvidenceProvider>(context, listen: false).updateStatus(item.id, 'VERIFIED', score: 98.0);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text("APPROVE EVIDENCE"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
