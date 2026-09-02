import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../../models/evidence_model.dart';
import 'crypto_seal_badge.dart';

class EvidenceCard extends StatelessWidget {
  final EvidenceItem item;
  final VoidCallback onTap;

  const EvidenceCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          "${item.cropName} • ${item.location.fieldName}",
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
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item.timestamp.contains('T') ? item.timestamp.split('T')[0] : item.timestamp,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  if (item.productName != null) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}
