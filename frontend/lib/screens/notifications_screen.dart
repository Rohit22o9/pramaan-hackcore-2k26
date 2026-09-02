import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifs = [
      {
        "title": "Spray Window Alert: Clear Skies Next 6 Hours",
        "message": "Wind speed 5.4 km/h, humidity 64%. Optimal window for foliar nutrient sprays in Dindori.",
        "type": "WEATHER",
        "timestamp": "10 mins ago",
        "icon": Icons.wb_sunny_rounded,
        "color": AppColors.accentGold,
      },
      {
        "title": "Evidence EV-2026-8812 Cryptographically Verified",
        "message": "Field Agent approved Post-Treatment Efficacy record. Blockchain anchor SHA-256 updated.",
        "type": "VERIFICATION",
        "icon": Icons.verified_user_rounded,
        "color": AppColors.primary,
        "timestamp": "1 hour ago",
      },
      {
        "title": "Buyer Quote Request: ITC Agri-Business",
        "message": "ITC Agri offered ₹7,850/Qtl (+₹450 Pramaan Organic Verified Premium) for Lot #CT-881.",
        "type": "BUYER",
        "icon": Icons.storefront_rounded,
        "color": AppColors.primaryDark,
        "timestamp": "3 hours ago",
      },
      {
        "title": "Regional Pest Outbreak Warning: Pink Bollworm",
        "message": "Neighbouring plots reported light moth trap activity. Check pheromone traps daily.",
        "type": "PEST_ALERT",
        "icon": Icons.bug_report_rounded,
        "color": AppColors.flaggedRed,
        "timestamp": "1 day ago",
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("System Alerts & Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifs.length,
        itemBuilder: (context, index) {
          final n = notifs[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (n['color'] as Color).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(n['icon'] as IconData, color: n['color'] as Color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(n['type'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: n['color'] as Color)),
                            Text(n['timestamp'] as String, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(n['title'] as String, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(n['message'] as String, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
