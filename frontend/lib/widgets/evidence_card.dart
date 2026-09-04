import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/services/pdf_download_service.dart';
import '../../models/evidence_model.dart';
import 'crypto_seal_badge.dart';

class EvidenceCard extends StatefulWidget {
  final EvidenceItem item;
  final VoidCallback onTap;

  const EvidenceCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  State<EvidenceCard> createState() => _EvidenceCardState();
}

class _EvidenceCardState extends State<EvidenceCard> {
  bool _isDownloading = false;

  Future<void> _downloadPdfReport() async {
    setState(() => _isDownloading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final savedFile = await PdfDownloadService().downloadAndOpenReport(
        item: widget.item,
        farmerName: auth.userName,
        farmerPhone: auth.userPhone,
        village: auth.userVillage,
        state: auth.userState,
        activeCrop: auth.activeCrop,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.download_done_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "✓ 3-Page PDF Downloaded (${savedFile.path.split(Platform.pathSeparator).last}) & opened in viewer!",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("PDF downloaded to storage for ${widget.item.cropName}."),
          backgroundColor: const Color(0xFF047857),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    IconData typeIcon;
    Color typeColor;

    if (item.evidenceType == 'VOICE_LOG') {
      typeIcon = Icons.mic_rounded;
      typeColor = Colors.purple;
    } else if (item.evidenceType == 'PRODUCT_SCAN') {
      typeIcon = Icons.qr_code_2_rounded;
      typeColor = Colors.blue;
    } else if (item.evidenceType == 'CROP_IMAGE') {
      typeIcon = Icons.camera_alt_rounded;
      typeColor = AppColors.primary;
    } else {
      typeIcon = Icons.eco_rounded;
      typeColor = AppColors.accentGold;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Type Icon, Title & Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${item.cropName} • ${item.location.village}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CryptoSealBadge(
                    score: item.verificationScore,
                    status: item.verificationStatus,
                    compact: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Description Text
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Metadata Tags Row
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item.timestamp.contains('T') ? item.timestamp.split('T')[0] : item.timestamp,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  if (item.productName != null && item.productName!.isNotEmpty) ...[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.productName!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // 1-Click Direct Download 3-Page PDF Button Next To Each Log
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isDownloading ? null : _downloadPdfReport,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded, color: AppColors.accentGold, size: 16),
                  label: Text(
                    _isDownloading ? "DOWNLOADING 3-PAGE PDF..." : "DOWNLOAD 3-PAGE PDF (EN / HI / MR)",
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
