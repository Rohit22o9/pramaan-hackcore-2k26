import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/farm_provider.dart';
import '../core/providers/evidence_provider.dart';
import '../widgets/custom_bottom_nav.dart';
import '../core/localization/app_translations.dart';

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  final int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveFarmerLogs();
    });
  }

  void _loadActiveFarmerLogs() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final evProv = Provider.of<EvidenceProvider>(context, listen: false);
    evProv.loadEvidenceForFarmer(phone: auth.userPhone, name: auth.userName);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final farmProv = Provider.of<FarmProvider>(context);
    final evProv = Provider.of<EvidenceProvider>(context);
    final farm = farmProv.selectedFarm;
    final lang = auth.selectedLanguage;

    final locationText = farm?.village.isNotEmpty == true 
        ? "${farm!.village}, ${farm.state.isNotEmpty ? farm.state : 'Punjab'}"
        : (auth.userVillage.isNotEmpty ? "${auth.userVillage}, Punjab" : "Ludhiana, Punjab");

    return Scaffold(
      backgroundColor: const Color(0xFFFBFDFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
          onPressed: () => _showSideOptionsSheet(context, auth, farmProv),
        ),
        centerTitle: true,
        title: InkWell(
          onTap: () => _showFarmSelector(context, farmProv),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF047857),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  locationText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF0F172A),
                  size: 24,
                ),
                onPressed: () => Navigator.pushNamed(context, '/notifications'),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF047857),
        onRefresh: () async {
          await farmProv.init();
          await evProv.loadEvidenceForFarmer(
            phone: auth.userPhone,
            name: auth.userName,
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Greeting & Weather Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            lang == 'pa' ? "Sat Sri Akal" : (lang == 'hi' ? "Namaste" : "Sat Sri Akal"),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "🙏",
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.userName.isNotEmpty 
                            ? "Welcome back, ${auth.userName} ji!"
                            : "Welcome back, Kisan ji!",
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wb_sunny_rounded,
                        color: Color(0xFFF59E0B),
                        size: 26,
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text(
                            "28°C",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF047857),
                            ),
                          ),
                          Text(
                            "Partly Cloudy",
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Active Crop Summary Card
              _buildCropCard(context, farm, auth),
              const SizedBox(height: 14),

              // Field Weather Green Banner
              _buildFieldWeatherBanner(context),
              const SizedBox(height: 18),

              // Quick Actions Section
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: "Voice Log",
                      subtitle: "Speak & record\nyour activity",
                      icon: Icons.mic_rounded,
                      onTap: () => Navigator.pushNamed(context, '/voice_log'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: "Crop Camera",
                      subtitle: "Check crop\nhealth with AI",
                      icon: Icons.camera_alt_rounded,
                      onTap: () => Navigator.pushNamed(context, '/crop_camera'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      title: "Scan Bottle",
                      subtitle: "Scan & verify\nproduct",
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () => Navigator.pushNamed(context, '/scan_product'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionCard(
                      title: "New Spray Log",
                      subtitle: "Record new\nspray activity",
                      icon: Icons.science_rounded,
                      onTap: () => Navigator.pushNamed(context, '/new_application'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Recent Activities Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Activities",
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/evidence_review'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        "View All",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Recent Activities List
              _buildRecentActivitiesList(evProv),
              const SizedBox(height: 16),

              // Kisan Tip of the Day Card
              _buildKisanTipCard(lang),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _navIndex,
      ),
    );
  }

  Widget _buildCropCard(BuildContext context, dynamic farm, AuthProvider auth) {
    final cropName = farm?.activeCrop ?? auth.activeCrop;
    final stage = farm?.cropStage ?? "Boll Formation / Flowering";
    final acres = farm?.totalAcres ?? 12.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Crop Illustration Icon Container
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.spa_rounded,
                color: Color(0xFF047857),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cropName.isNotEmpty ? cropName : "Cotton (Bt-II)",
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Text(
                        "96% Compliance",
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  "Stage: $stage",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  "Area: $acres Acres",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldWeatherBanner(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/agronomy_suite'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D6E4F), Color(0xFF15803D), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF047857).withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.eco_rounded, color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text(
                              "Field Weather",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "28.5°C",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Row(
                                  children: [
                                    Icon(Icons.air_rounded, color: Colors.white70, size: 13),
                                    SizedBox(width: 3),
                                    Text(
                                      "Wind: 5.4 km/h",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1),
                                Text(
                                  "Calm winds and\nideal for spraying",
                                  style: TextStyle(
                                    color: Color(0xFFD1FAE5),
                                    fontSize: 10.5,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Sun & field landscape artwork graphic
                  Container(
                    width: 76,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 8,
                          child: Icon(
                            Icons.wb_sunny_rounded,
                            color: Color(0xFFFDE047),
                            size: 26,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          child: Icon(
                            Icons.grass_rounded,
                            color: Color(0xFF86EFAC),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom banner pill
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF047857),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Great conditions for better results!",
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF047857),
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesList(EvidenceProvider evProv) {
    if (evProv.evidenceList.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            _buildActivityItem(
              title: "Voice Log Added",
              subtitle: "Insecticide spray on cotton field",
              time: "Today, 8:30 AM",
              icon: Icons.mic_rounded,
              onTap: () => Navigator.pushNamed(context, '/evidence_review'),
            ),
            const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
            _buildActivityItem(
              title: "Crop Photo Captured",
              subtitle: "AI analysis completed",
              time: "Today, 7:45 AM",
              icon: Icons.camera_alt_rounded,
              onTap: () => Navigator.pushNamed(context, '/evidence_review'),
            ),
          ],
        ),
      );
    }

    final displayItems = evProv.evidenceList.take(3).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: List.generate(displayItems.length, (idx) {
          final item = displayItems[idx];
          IconData itemIcon = Icons.note_alt_rounded;
          if (item.evidenceType == 'VOICE_RECORDING' || item.evidenceType == 'OBSERVATION') {
            itemIcon = Icons.mic_rounded;
          } else if (item.evidenceType == 'CROP_IMAGE') {
            itemIcon = Icons.camera_alt_rounded;
          } else if (item.evidenceType == 'PRODUCT_SCAN') {
            itemIcon = Icons.qr_code_scanner_rounded;
          } else if (item.evidenceType == 'APPLICATION_LOG') {
            itemIcon = Icons.science_rounded;
          }

          return Column(
            children: [
              _buildActivityItem(
                title: item.title,
                subtitle: item.description,
                time: item.timestamp.isNotEmpty ? item.timestamp : "Today",
                icon: itemIcon,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/evidence_detail',
                  arguments: item,
                ),
              ),
              if (idx < displayItems.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required String time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF047857),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              time,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF047857),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKisanTipCard(String lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          // Farmer cartoon avatar illustration
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Center(
              child: Text(
                "👨‍🌾",
                style: TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Kisan Tip of the Day",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "छिड़काव सुबह या शाम के समय करें, बेहतर परिणाम के लिए।",
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1AF59E0B),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: Color(0xFFF59E0B),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  void _showSideOptionsSheet(BuildContext context, AuthProvider auth, FarmProvider farmProv) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sync_rounded, color: Color(0xFF047857)),
              title: const Text("Sync Center & Google Sheets"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/sync_center');
              },
            ),
            ListTile(
              leading: const Icon(Icons.groups_rounded, color: Color(0xFF047857)),
              title: const Text("Community Logs"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/community_logs');
              },
            ),
            ListTile(
              leading: const Icon(Icons.language_rounded, color: Color(0xFF047857)),
              title: Text("Language: ${auth.selectedLanguage.toUpperCase()}"),
              onTap: () {
                Navigator.pop(ctx);
                AppTranslations.showLanguageSelectorModal(
                  context,
                  auth.selectedLanguage,
                  (newLang) => auth.setLanguage(newLang),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.switch_account_rounded, color: Color(0xFF047857)),
              title: const Text("Switch Profile / Role"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/profile_selection');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: Color(0xFF047857)),
              title: const Text("Settings"),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFFECFDF5) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCurrent
                          ? const Color(0xFF047857)
                          : const Color(0xFFE2E8F0),
                      width: isCurrent ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF047857),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      f.name,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    subtitle: Text(
                      "${f.village}, ${f.state} • ${f.activeCrop}",
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    trailing: isCurrent
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF047857),
                          )
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

