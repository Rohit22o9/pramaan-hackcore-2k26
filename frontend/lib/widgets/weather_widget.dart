import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../../models/weather_model.dart';

class WeatherSummaryWidget extends StatelessWidget {
  final WeatherAdvisory? advisory;
  final VoidCallback onTap;

  const WeatherSummaryWidget({
    super.key,
    required this.advisory,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weather = advisory?.currentWeather;
    final temp = weather?.temperatureC ?? 28.5;
    final condition = weather?.condition ?? "Clear Sunny Skies";
    final recommendation = weather?.sprayRecommendation ?? "Prime spraying conditions in Punjab agricultural belt.";
    final location = weather?.locationName ?? "Ludhiana (ਪੰਜਾਬ)";
    final wind = weather?.windSpeedKmh ?? 5.4;
    final humidity = weather?.humidityPercent ?? 68.0;
    final deltaT = weather?.deltaTC ?? 3.6;
    final isSafe = weather?.spraySuitabilityScore != null && weather!.spraySuitabilityScore >= 0.8;

    IconData weatherIcon = Icons.wb_sunny_rounded;
    Color iconColor = AppColors.accentGold;
    if (condition.toLowerCase().contains("rain") || condition.toLowerCase().contains("shower")) {
      weatherIcon = Icons.water_drop_rounded;
      iconColor = Colors.lightBlueAccent;
    } else if (condition.toLowerCase().contains("cloud") || condition.toLowerCase().contains("overcast")) {
      weatherIcon = Icons.cloud_rounded;
      iconColor = Colors.white70;
    } else if (condition.toLowerCase().contains("fog")) {
      weatherIcon = Icons.cloud_queue_rounded;
      iconColor = Colors.tealAccent;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF065F46)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF064E3B).withOpacity(0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Location & Live Pulsing Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFF34D399), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFA7F3D0),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF34D399).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "LIVE REAL-TIME",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle Row: Temperature & Spray Safe Tag
            Row(
              children: [
                Icon(weatherIcon, color: iconColor, size: 32),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$temp°C • $condition",
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Wind $wind km/h • $humidity% RH • ΔT $deltaT°C",
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFA7F3D0)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSafe ? const Color(0xFF059669) : const Color(0xFFD97706),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSafe ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSafe ? "SPRAY SAFE" : "CAUTION",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Alert Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF34D399), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
