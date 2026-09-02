import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/farm_provider.dart';
import '../core/localization/app_translations.dart';
import '../../models/weather_model.dart';

class AgronomySuiteScreen extends StatelessWidget {
  const AgronomySuiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final farmProv = Provider.of<FarmProvider>(context);
    final lang = auth.selectedLanguage;
    final advisory = farmProv.weatherAdvisory;
    final weather = advisory?.currentWeather;
    final selectedDistrict = farmProv.selectedDistrict;
    final districts = farmProv.punjabDistricts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppTranslations.tr(lang, "weather_guide"),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Color(0xFF0F172A)),
            ),
            Text(
              "Punjab Live Microclimate • ${weather?.districtName ?? selectedDistrict?.name ?? 'Ludhiana'}",
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Language Switcher Button
          IconButton(
            tooltip: AppTranslations.tr(lang, "select_language"),
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.translate_rounded, color: Color(0xFF059669), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    lang.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
            onPressed: () => AppTranslations.showLanguageSelectorModal(
              context,
              lang,
              (newLang) => auth.setLanguage(newLang),
            ),
          ),
          IconButton(
            tooltip: AppTranslations.tr(lang, "refresh"),
            icon: farmProv.isWeatherLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => farmProv.refreshWeather(),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Punjab Districts Quick Switcher Bar
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Text(
                  AppTranslations.tr(lang, "select_district"),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: districts.length,
                separatorBuilder: (context, idx) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final dist = districts[idx];
                  final isSelected = (selectedDistrict?.id == dist.id) ||
                      (weather?.districtName.toLowerCase() == dist.name.toLowerCase());
                  final displayName = lang == 'pa' ? dist.punjabiName : dist.name;
                  return ChoiceChip(
                    label: Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    elevation: isSelected ? 2 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                      ),
                    ),
                    onSelected: (_) => farmProv.selectPunjabDistrict(dist),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // 2. Simple Traffic-Light Main Decision Banner
            _buildFarmerDecisionBanner(weather, advisory, lang),
            const SizedBox(height: 14),

            // 3. Simple 4-Factor Metric Grid
            _buildSimpleMetricsGrid(weather, lang),
            const SizedBox(height: 16),

            // 4. Farmer Action Advisory (PAU Guidelines)
            _buildFarmerActionCard(advisory, weather, lang),
            const SizedBox(height: 20),

            // 5. Simple 48-Hour Spray Timetable
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppTranslations.tr(lang, "best_spray_timings"),
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    "48h",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (advisory != null && advisory.upcomingWindows.isNotEmpty)
              ...advisory.upcomingWindows.map((slot) => _buildSimpleSpraySlot(slot, lang))
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Loading weather forecast windows..."),
                ),
              ),
            const SizedBox(height: 20),

            // 6. Simplified Crop Diseases & Medicine Guide
            Text(
              AppTranslations.tr(lang, "crop_diseases"),
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            _buildSimpleDiseaseCard(
              cropName: AppTranslations.tr(lang, "wheat"),
              diseaseName: AppTranslations.tr(lang, "wheat_disease"),
              symptoms: AppTranslations.tr(lang, "wheat_symptoms"),
              chemicalMedicine: AppTranslations.tr(lang, "wheat_medicine"),
              organicSolution: AppTranslations.tr(lang, "wheat_organic"),
              doseLabel: AppTranslations.tr(lang, "dose_label"),
              organicLabel: AppTranslations.tr(lang, "organic_label"),
              color: const Color(0xFFD97706),
              icon: Icons.grass_rounded,
            ),
            const SizedBox(height: 10),
            _buildSimpleDiseaseCard(
              cropName: AppTranslations.tr(lang, "cotton"),
              diseaseName: AppTranslations.tr(lang, "cotton_disease"),
              symptoms: AppTranslations.tr(lang, "cotton_symptoms"),
              chemicalMedicine: AppTranslations.tr(lang, "cotton_medicine"),
              organicSolution: AppTranslations.tr(lang, "cotton_organic"),
              doseLabel: AppTranslations.tr(lang, "dose_label"),
              organicLabel: AppTranslations.tr(lang, "organic_label"),
              color: const Color(0xFF059669),
              icon: Icons.pest_control_rounded,
            ),
            const SizedBox(height: 10),
            _buildSimpleDiseaseCard(
              cropName: AppTranslations.tr(lang, "potato"),
              diseaseName: AppTranslations.tr(lang, "potato_disease"),
              symptoms: AppTranslations.tr(lang, "potato_symptoms"),
              chemicalMedicine: AppTranslations.tr(lang, "potato_medicine"),
              organicSolution: AppTranslations.tr(lang, "potato_organic"),
              doseLabel: AppTranslations.tr(lang, "dose_label"),
              organicLabel: AppTranslations.tr(lang, "organic_label"),
              color: const Color(0xFFDC2626),
              icon: Icons.shield_moon_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 1. Simple Traffic-Light Decision Banner
  Widget _buildFarmerDecisionBanner(WeatherSnapshot? weather, WeatherAdvisory? advisory, String lang) {
    final temp = weather?.temperatureC ?? 28.5;
    final location = weather?.districtName ?? "Ludhiana";
    final wind = weather?.windSpeedKmh ?? 5.4;
    final deltaT = weather?.deltaTC ?? 3.6;

    final isOptimal = wind <= 14.0 && deltaT >= 2.0 && deltaT <= 8.5 && temp <= 33.0;
    final isCaution = !isOptimal && (wind <= 18.0 || temp <= 35.0);

    Color bannerBg;
    String statusTitle;
    String statusSubtitle;
    IconData statusIcon;

    if (isOptimal) {
      bannerBg = const Color(0xFF065F46); // Emerald Green
      statusTitle = AppTranslations.tr(lang, "safe_to_spray");
      statusSubtitle = AppTranslations.tr(lang, "safe_to_spray_sub");
      statusIcon = Icons.check_circle_rounded;
    } else if (isCaution) {
      bannerBg = const Color(0xFF92400E); // Amber Warm
      statusTitle = AppTranslations.tr(lang, "spray_caution");
      statusSubtitle = AppTranslations.tr(lang, "spray_caution_sub");
      statusIcon = Icons.warning_amber_rounded;
    } else {
      bannerBg = const Color(0xFF991B1B); // Crimson Red
      statusTitle = AppTranslations.tr(lang, "do_not_spray");
      statusSubtitle = AppTranslations.tr(lang, "do_not_spray_sub");
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bannerBg.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // District Name + Live Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "$location, Punjab",
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "● ${AppTranslations.tr(lang, "live_weather")}",
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Decision Badge
          Row(
            children: [
              Icon(statusIcon, color: Colors.white, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusTitle,
                  style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            statusSubtitle,
            style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
          ),
          const Divider(height: 20, color: Colors.white24),

          // Bottom Quick Snapshot: Temp, Wind, Rain, Absorption
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBannerMicroStat("🌡️ ${AppTranslations.tr(lang, "temp")}", "$temp°C"),
              _buildBannerMicroStat("💨 ${AppTranslations.tr(lang, "wind")}", "$wind km/h"),
              _buildBannerMicroStat("💧 ${AppTranslations.tr(lang, "rain_risk")}", "${weather?.precipitationProb ?? 0}%"),
              _buildBannerMicroStat("🌿 ${AppTranslations.tr(lang, "absorption")}", isOptimal ? AppTranslations.tr(lang, "pleasant") : AppTranslations.tr(lang, "moderate")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerMicroStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  /// 2. Simple 4-Factor Metric Grid
  Widget _buildSimpleMetricsGrid(WeatherSnapshot? weather, String lang) {
    final temp = weather?.temperatureC ?? 28.5;
    final wind = weather?.windSpeedKmh ?? 5.4;
    final rainProb = weather?.precipitationProb ?? 10.0;
    final deltaT = weather?.deltaTC ?? 3.6;

    final isDeltaTOptimal = deltaT >= 2.0 && deltaT <= 8.5;
    final isWindCalm = wind <= 12.0;
    final isRainSafe = rainProb <= 20.0;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        // 1. Spray Absorption
        _buildSimpleFactorCard(
          icon: Icons.eco_rounded,
          title: AppTranslations.tr(lang, "spray_absorption"),
          value: isDeltaTOptimal ? AppTranslations.tr(lang, "absorption_val_optimal") : AppTranslations.tr(lang, "absorption_val_moderate"),
          subtitle: isDeltaTOptimal ? AppTranslations.tr(lang, "absorption_desc_optimal") : AppTranslations.tr(lang, "absorption_desc_moderate"),
          color: const Color(0xFF059669),
        ),

        // 2. Wind Speed
        _buildSimpleFactorCard(
          icon: Icons.air_rounded,
          title: AppTranslations.tr(lang, "wind_speed"),
          value: "${isWindCalm ? AppTranslations.tr(lang, "wind_calm") : AppTranslations.tr(lang, "wind_breezy")} ($wind km/h)",
          subtitle: isWindCalm ? AppTranslations.tr(lang, "wind_desc_calm") : AppTranslations.tr(lang, "wind_desc_breezy"),
          color: isWindCalm ? const Color(0xFF0284C7) : const Color(0xFFD97706),
        ),

        // 3. Rain Risk
        _buildSimpleFactorCard(
          icon: Icons.water_drop_rounded,
          title: AppTranslations.tr(lang, "rain_risk"),
          value: "${rainProb.round()}% ${AppTranslations.tr(lang, "rain_chance")}",
          subtitle: isRainSafe ? AppTranslations.tr(lang, "rain_desc_safe") : AppTranslations.tr(lang, "rain_desc_unsafe"),
          color: isRainSafe ? const Color(0xFF0D9488) : const Color(0xFFDC2626),
        ),

        // 4. Heat & Sun
        _buildSimpleFactorCard(
          icon: Icons.wb_sunny_rounded,
          title: AppTranslations.tr(lang, "heat_sun"),
          value: "$temp°C (${temp <= 32 ? AppTranslations.tr(lang, "pleasant") : AppTranslations.tr(lang, "too_hot")})",
          subtitle: temp <= 32 ? AppTranslations.tr(lang, "heat_desc_safe") : AppTranslations.tr(lang, "heat_desc_hot"),
          color: const Color(0xFFD97706),
        ),
      ],
    );
  }

  Widget _buildSimpleFactorCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4.5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 3. Farmer Action Card (PAU Guidelines)
  Widget _buildFarmerActionCard(WeatherAdvisory? advisory, WeatherSnapshot? weather, String lang) {
    final district = weather?.districtName ?? "Ludhiana";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "${AppTranslations.tr(lang, "farmer_advisory")} ($district)",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildActionBullet(AppTranslations.tr(lang, "advisory_bullet_1")),
          const SizedBox(height: 5),
          _buildActionBullet(AppTranslations.tr(lang, "advisory_bullet_2")),
          const SizedBox(height: 5),
          _buildActionBullet(AppTranslations.tr(lang, "advisory_bullet_3")),
        ],
      ),
    );
  }

  Widget _buildActionBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("• ", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F), height: 1.3),
          ),
        ),
      ],
    );
  }

  /// 4. Simple Spray Slot Timings
  Widget _buildSimpleSpraySlot(SprayWindowSlot slot, String lang) {
    bool isGood = slot.suitability == 'OPTIMAL';
    bool isModerate = slot.suitability == 'MODERATE';

    Color badgeColor = isGood
        ? const Color(0xFF059669)
        : (isModerate ? const Color(0xFFD97706) : const Color(0xFFDC2626));

    String statusText = isGood
        ? AppTranslations.tr(lang, "best_time")
        : (isModerate ? AppTranslations.tr(lang, "moderate") : AppTranslations.tr(lang, "no_spray"));

    String slotTitle = slot.timeWindow;
    String slotReason = slot.advisoryReason;
    if (slot.timeWindow.contains("Morning") && !slot.timeWindow.contains("Tomorrow")) {
      slotTitle = AppTranslations.tr(lang, "morning_slot");
      slotReason = AppTranslations.tr(lang, "morning_reason");
    } else if (slot.timeWindow.contains("Midday")) {
      slotTitle = AppTranslations.tr(lang, "midday_slot");
      slotReason = AppTranslations.tr(lang, "midday_reason");
    } else if (slot.timeWindow.contains("Evening")) {
      slotTitle = AppTranslations.tr(lang, "evening_slot");
      slotReason = AppTranslations.tr(lang, "evening_reason");
    } else if (slot.timeWindow.contains("Tomorrow")) {
      slotTitle = AppTranslations.tr(lang, "tomorrow_slot");
      slotReason = AppTranslations.tr(lang, "tomorrow_reason");
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isGood ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  statusText,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  slotTitle,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            slotReason,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  /// 5. Simplified Disease & Medicine Card
  Widget _buildSimpleDiseaseCard({
    required String cropName,
    required String diseaseName,
    required String symptoms,
    required String chemicalMedicine,
    required String organicSolution,
    required String doseLabel,
    required String organicLabel,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(diseaseName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      Text(symptoms, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(cropName, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
            const Divider(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("🧪 ", style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(
                    "$doseLabel $chemicalMedicine",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("🌿 ", style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Text(
                    "$organicLabel $organicSolution",
                    style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
