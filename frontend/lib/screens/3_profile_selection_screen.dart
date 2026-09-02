import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';

class ProfileSelectionScreen extends StatelessWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "STEP 1 OF 1",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Choose Your Role",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select your account persona to customize workflows, data views, and verification tools.",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              _buildRoleCard(
                context,
                title: "Farmer / Grower",
                subtitle: "Voice logging, crop camera diagnosis, spray windows & season journal.",
                icon: Icons.agriculture_rounded,
                role: UserRoleType.farmer,
                isSelected: auth.currentRole == UserRoleType.farmer,
                color: AppColors.primary,
                onTap: () {
                  auth.switchRole(UserRoleType.farmer);
                  Navigator.pushReplacementNamed(context, '/farmer_dashboard');
                },
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                title: "Field Agent / Agronomist",
                subtitle: "Multi-farm review queue, audit sign-off, geospatial maps & model feedback loop.",
                icon: Icons.assignment_turned_in_rounded,
                role: UserRoleType.fieldAgent,
                isSelected: auth.currentRole == UserRoleType.fieldAgent,
                color: AppColors.primaryDark,
                onTap: () {
                  auth.switchRole(UserRoleType.fieldAgent);
                  Navigator.pushReplacementNamed(context, '/field_agent_dashboard');
                },
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                title: "Buyer / Agri-Input Partner",
                subtitle: "Lot valuation pricing, chemical compliance reports & verifiable proof certificates.",
                icon: Icons.storefront_rounded,
                role: UserRoleType.buyer,
                isSelected: auth.currentRole == UserRoleType.buyer,
                color: AppColors.accentAmber,
                onTap: () {
                  auth.switchRole(UserRoleType.buyer);
                  Navigator.pushReplacementNamed(context, '/buyer_pricing');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required UserRoleType role,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : const Color(0xFFE2E8F0),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
