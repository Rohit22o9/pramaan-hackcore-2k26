import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/farm_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final farmProv = Provider.of<FarmProvider>(context);
    final farm = farmProv.selectedFarm;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("User Profile & Parameters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Avatar Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primarySurface,
                    child: Text(
                      auth.userName.isNotEmpty ? auth.userName[0] : 'R',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(auth.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Text(auth.roleName, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(auth.userVillage, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Farm Details
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
                  const Text("Registered Farm Parameters", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  _buildProfileRow("Farm Name", farm?.name ?? "Sahyadri Bio-Farms"),
                  _buildProfileRow("Total Area", "${farm?.totalAcres ?? 12.5} Acres"),
                  _buildProfileRow("Primary Active Crop", farm?.activeCrop ?? "Cotton (Bt-II)"),
                  _buildProfileRow("Compliance Score", "${farm?.complianceScore ?? 96.4}% (Grade A+)"),
                  _buildProfileRow("Location Coordinates", "${farm?.latitude ?? 20.1985}° N, ${farm?.longitude ?? 73.8322}° E"),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/profile_selection'),
                child: const Text("SWITCH ROLE / PERSONA"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
