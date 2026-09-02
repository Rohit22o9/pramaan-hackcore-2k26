import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/farm_provider.dart';
import '../core/providers/evidence_provider.dart';
import '../widgets/weather_widget.dart';
import '../widgets/evidence_card.dart';
import '../widgets/custom_bottom_nav.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final farmProv = Provider.of<FarmProvider>(context);
    final evProv = Provider.of<EvidenceProvider>(context);
    final farm = farmProv.selectedFarm;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: InkWell(
          onTap: () => _showFarmSelector(context, farmProv),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      farm?.village ?? auth.userVillage,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                  ],
                ),
                Text(
                  farm?.name ?? "Punjab Kisan Adarsh Farm",
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, '/sync_center'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                auth.userName.isNotEmpty ? auth.userName[0] : 'R',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ),
            onSelected: (val) {
              if (val == 'switch_role') {
                Navigator.pushNamed(context, '/profile_selection');
              } else if (val == 'settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (val == 'profile') {
                Navigator.pushNamed(context, '/profile');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'profile', child: Text("Profile: ${auth.userName}")),
              const PopupMenuItem(value: 'switch_role', child: Text("Switch Role")),
              const PopupMenuItem(value: 'settings', child: Text("Settings")),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await farmProv.init();
          await evProv.loadEvidence();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Crop Banner
              _buildCropHeroBanner(farm),
              const SizedBox(height: 14),

              // Weather & Spray Window Advisory Widget
              WeatherSummaryWidget(
                advisory: farmProv.weatherAdvisory,
                onTap: () => Navigator.pushNamed(context, '/agronomy_suite'),
              ),
              const SizedBox(height: 16),

              // Quick Actions Grid
              const Text(
                "Quick Evidence Capture",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      title: "Voice Log",
                      subtitle: "Speak in Hindi/Marathi",
                      icon: Icons.mic_rounded,
                      color: Colors.purple,
                      onTap: () => Navigator.pushNamed(context, '/voice_log'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      title: "Crop Camera",
                      subtitle: "AI Disease Diagnosis",
                      icon: Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      onTap: () => Navigator.pushNamed(context, '/crop_camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildActionTile(
                      title: "Scan Bottle",
                      subtitle: "QR Authenticity Check",
                      icon: Icons.qr_code_scanner_rounded,
                      color: Colors.blue,
                      onTap: () => Navigator.pushNamed(context, '/scan_product'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionTile(
                      title: "New Spray Log",
                      subtitle: "Record Dosage & PHI",
                      icon: Icons.science_rounded,
                      color: AppColors.accentAmber,
                      onTap: () => Navigator.pushNamed(context, '/new_application'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Evidence Activity Feed Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Verified Field Evidence",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/evidence_review'),
                    child: const Text("View All", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Evidence Items List
              if (evProv.isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (evProv.evidenceList.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("No evidence items yet.")))
              else
                ...evProv.evidenceList.take(3).map((item) => EvidenceCard(
                      item: item,
                      onTap: () => Navigator.pushNamed(context, '/evidence_detail', arguments: item),
                    )),

              const SizedBox(height: 12),

              // Season Journal Callout Card
              Card(
                color: AppColors.surfaceVariant,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: const Icon(Icons.timeline_rounded, color: AppColors.primaryDark, size: 28),
                  title: const Text("Kharif Season Journal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text("Timeline of sowing, sprays, and AI verified events.", style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  onTap: () => Navigator.pushNamed(context, '/season_journal'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _navIndex,
        onTap: (index) {
          setState(() => _navIndex = index);
          if (index == 1) {
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

  Widget _buildCropHeroBanner(dynamic farm) {
    final crop = farm?.activeCrop ?? "Cotton (Bt-II)";
    final stage = farm?.cropStage ?? "Boll Formation / Flowering";
    final acres = farm?.totalAcres ?? 12.5;
    final score = farm?.complianceScore ?? 96.4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        crop,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(6)),
                      child: Text("$score% Compliance", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text("Stage: $stage • $acres Acres", style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFarmSelector(BuildContext context, FarmProvider farmProv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Switch Agricultural Plot / Farm",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...farmProv.farms.map((f) {
                final isCurrent = farmProv.selectedFarm?.id == f.id;
                final isPunjab = f.state.toLowerCase() == 'punjab';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.primarySurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : const Color(0xFFE2E8F0),
                      width: isCurrent ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPunjab ? AppColors.primary : AppColors.accentGold,
                      child: Icon(
                        isPunjab ? Icons.eco_rounded : Icons.agriculture_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      f.name,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text("${f.village}, ${f.state} • ${f.activeCrop}", style: const TextStyle(fontSize: 11.5)),
                    trailing: isCurrent
                        ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                        : null,
                    onTap: () {
                      farmProv.selectFarm(f);
                      Navigator.pop(ctx);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

