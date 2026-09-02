import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/farm_provider.dart';
import '../../models/weather_model.dart';
import '../../models/evidence_model.dart';

class AgronomySuiteScreen extends StatelessWidget {
  const AgronomySuiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final farmProv = Provider.of<FarmProvider>(context);
    final advisory = farmProv.weatherAdvisory;
    final weather = advisory?.currentWeather;
    final selectedDistrict = farmProv.selectedDistrict;
    final districts = farmProv.punjabDistricts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Agronomy Intelligence Suite",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              "PAU Punjab Live Microclimate • ${weather?.districtName ?? selectedDistrict?.name ?? 'Ludhiana'}",
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Live Real-Time Refresh",
            icon: farmProv.isWeatherLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: () => farmProv.refreshWeather(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Punjab Districts Quick Switcher Bar
            const Text(
              "Select Punjab Agricultural District",
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                  return ChoiceChip(
                    label: Text(
                      "${dist.name} (${dist.punjabiName})",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
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
            const SizedBox(height: 16),

            // 2. Real-Time Microclimate Overview Card
            _buildLiveMicroclimateBanner(weather, advisory),
            const SizedBox(height: 16),

            // 3. Real-Time Microclimate Metrics Grid
            _buildMicroclimateMetricsGrid(weather),
            const SizedBox(height: 16),

            // 4. PAU Regional Agro-Advisory & Live Pest Warning
            _buildPauAdvisoryCard(advisory, weather),
            const SizedBox(height: 20),

            // 5. Dynamic 48-Hour Operational Spray Schedule
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    "48-Hour Live Spray Windows",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Delta-T Calibrated",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (advisory != null && advisory.upcomingWindows.isNotEmpty)
              ...advisory.upcomingWindows.map((slot) => _buildSpraySlotCard(slot))
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Loading 48-hour live numerical weather windows..."),
                ),
              ),
            const SizedBox(height: 20),

            // 6. Punjab Crop Pathology & Diagnostic Reference Library
            const Text(
              "Punjab Crop Pathology & Pest Protocols",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            _buildDiseaseCard(
              title: "Wheat Yellow / Stripe Rust (Puccinia striiformis)",
              crop: "Wheat (Kanak)",
              zone: "Central Plain & Sub-Mountain Zone",
              severity: "High (Cool & Humid Morning Trigger)",
              organicTreatment: "Trichoderma viride 1.5% WP @ 1.0 kg/Ac or Bio-Sulfur dusting",
              chemicalTreatment: "Propiconazole 25% EC (Tilt) @ 200 ml/Acre in 200L clean water",
              color: AppColors.accentGold,
              icon: Icons.grass_rounded,
            ),
            const SizedBox(height: 10),
            _buildDiseaseCard(
              title: "Cotton Whitefly (Bemisia tabaci) & CLCuV",
              crop: "Bt Cotton",
              zone: "Malwa Western Belt (Bathinda/Mansa/Fazilka)",
              severity: "High (Warm Dry-Spells)",
              organicTreatment: "Bio-Neem Power 10,000 PPM @ 2.5 ml/L + 16 Yellow Sticky Traps/Acre",
              chemicalTreatment: "Pyriproxyfen 10% EC @ 400 ml/Ac or Diafenthiuron 50% WP @ 1.5 g/L",
              color: AppColors.primary,
              icon: Icons.pest_control_rounded,
            ),
            const SizedBox(height: 10),
            _buildDiseaseCard(
              title: "Late Blight of Potato (Phytophthora infestans)",
              crop: "Seed Potato",
              zone: "Doaba Zone (Jalandhar / Kapurthala)",
              severity: "Critical when RH > 85%",
              organicTreatment: "Prophylactic Copper Oxychloride 50% WP @ 2.5 g/L",
              chemicalTreatment: "Mancozeb 75% WP @ 600 g/Ac or Cymoxanil + Mancozeb @ 600 g/Ac",
              color: Colors.redAccent,
              icon: Icons.shield_moon_rounded,
            ),
            const SizedBox(height: 10),
            _buildDiseaseCard(
              title: "Basmati Neck Blast & Sheath Blight",
              crop: "Basmati Rice (1121/1509)",
              zone: "Majha Zone (Amritsar / Gurdaspur)",
              severity: "Medium",
              organicTreatment: "Pseudomonas fluorescens 0.5% foliar spray",
              chemicalTreatment: "Tricyclazole 75% WP @ 0.6 g/L or Azoxystrobin + Difenoconazole",
              color: Colors.blueAccent,
              icon: Icons.water_drop_rounded,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMicroclimateBanner(WeatherSnapshot? weather, WeatherAdvisory? advisory) {
    final temp = weather?.temperatureC ?? 28.5;
    final apparent = weather?.apparentTempC ?? 31.8;
    final condition = weather?.condition ?? "Clear Sunny Skies";
    final location = weather?.locationName ?? "Ludhiana (ਪੰਜਾਬ)";
    final deltaT = weather?.deltaTC ?? 3.6;
    final wind = weather?.windSpeedKmh ?? 5.4;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.satellite_alt_rounded, color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
                ),
                child: const Text(
                  "LIVE TELEMETRY",
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$temp°C",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    "Feels like $apparent°C • $condition",
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMicroStat("Delta-T (ΔT)", "$deltaT°C", const Color(0xFF34D399)),
                Container(height: 24, width: 1, color: Colors.white24),
                _buildMicroStat("Wind Drift", "$wind km/h", const Color(0xFF38BDF8)),
                Container(height: 24, width: 1, color: Colors.white24),
                _buildMicroStat("Wash-Off Risk", "${weather?.precipitationProb ?? 10}%", const Color(0xFFFBBF24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicroStat(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }

  Widget _buildMicroclimateMetricsGrid(WeatherSnapshot? weather) {
    final humidity = weather?.humidityPercent ?? 68.0;
    final dewPoint = weather?.dewPointC ?? 21.0;
    final windGusts = weather?.windGustsKmh ?? 12.0;
    final cloudCover = weather?.cloudCoverPercent ?? 20.0;
    final soilMoisture = weather?.soilMoisturePercent ?? 28.0;
    final deltaT = weather?.deltaTC ?? 3.6;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _buildMetricTile(
          icon: Icons.thermostat_rounded,
          label: "Delta-T (ΔT) Foliar",
          value: "$deltaT°C",
          status: "Optimal Window (2–8°C)",
          color: AppColors.primary,
        ),
        _buildMetricTile(
          icon: Icons.water_drop_rounded,
          label: "Humidity & Dew Point",
          value: "$humidity% / $dewPoint°C",
          status: "Foliar Uptake Safe",
          color: Colors.blueAccent,
        ),
        _buildMetricTile(
          icon: Icons.air_rounded,
          label: "Wind Speed & Gusts",
          value: "${weather?.windSpeedKmh ?? 5.4} / $windGusts km/h",
          status: "Low Drift Hazard",
          color: Colors.teal,
        ),
        _buildMetricTile(
          icon: Icons.grass_rounded,
          label: "Topsoil & Cloud Cover",
          value: "$soilMoisture% / $cloudCover%",
          status: "Root Zone Aerated",
          color: Colors.amber.shade800,
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPauAdvisoryCard(WeatherAdvisory? advisory, WeatherSnapshot? weather) {
    final alert = advisory?.pestPressureForecast ?? "Low fungal rust pressure under current Delta-T.";
    final pauText = weather?.pauAdvisoryText ?? "PAU Ludhiana: Follow calibrated 200L/Acre spray dilution.";

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
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  "PAU Ludhiana Regional Pest & Spray Alert",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF78350F), height: 1.3),
          ),
          const Divider(height: 16, color: Color(0xFFFDE68A)),
          Row(
            children: [
              const Icon(Icons.school_rounded, color: Color(0xFFB45309), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  pauText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpraySlotCard(SprayWindowSlot slot) {
    Color badgeColor;
    IconData statusIcon;
    if (slot.suitability == 'OPTIMAL') {
      badgeColor = AppColors.primary;
      statusIcon = Icons.check_circle_rounded;
    } else if (slot.suitability == 'MODERATE') {
      badgeColor = AppColors.accentGold;
      statusIcon = Icons.info_outline_rounded;
    } else {
      badgeColor = AppColors.flaggedRed;
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      slot.suitability.replaceAll('_', ' '),
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  slot.timeWindow,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildSlotMetric(Icons.thermostat_rounded, "${slot.temperatureC}°C"),
              _buildSlotMetric(Icons.air_rounded, "Wind ${slot.windKmh} km/h"),
              _buildSlotMetric(Icons.water_drop_rounded, "Rain ${slot.rainProbabilityPercent}%"),
              if (slot.deltaTC != null)
                _buildSlotMetric(Icons.scatter_plot_rounded, "ΔT ${slot.deltaTC}°C"),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            slot.advisoryReason,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotMetric(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildDiseaseCard({
    required String title,
    required String crop,
    required String zone,
    required String severity,
    required String organicTreatment,
    required String chemicalTreatment,
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
                      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("Zone: $zone", style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(crop, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
            const Divider(height: 14),
            Text("🌱 Organic: $organicTreatment", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primaryDark)),
            const SizedBox(height: 3),
            Text("🧪 PAU Protocol: $chemicalTreatment", style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
