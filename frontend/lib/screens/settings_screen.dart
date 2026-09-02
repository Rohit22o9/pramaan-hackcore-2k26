import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/constants/api_endpoints.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Application Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                  title: const Text("Voice & UI Language", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text("Current: ${auth.selectedLanguage.toUpperCase()}"),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(title: const Text("हिंदी (Hindi)"), onTap: () { auth.setLanguage('hi'); Navigator.pop(ctx); }),
                          ListTile(title: const Text("मराठी (Marathi)"), onTap: () { auth.setLanguage('mr'); Navigator.pop(ctx); }),
                          ListTile(title: const Text("English"), onTap: () { auth.setLanguage('en'); Navigator.pop(ctx); }),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync_rounded, color: AppColors.primary),
                  title: const Text("Offline Sync Cache", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Manage pending uploads and local storage"),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pushNamed(context, '/sync_center'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dns_rounded, color: AppColors.primary),
                  title: const Text("Backend Server Host", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text("Endpoint: ${ApiEndpoints.baseUrl}"),
                  trailing: const Icon(Icons.edit_rounded, size: 18),
                  onTap: () {
                    final controller = TextEditingController(text: ApiEndpoints.baseUrl);
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Configure Backend Host", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "When testing on a physical mobile phone, enter your computer's local Wi-Fi IP (e.g. http://192.168.1.5:8000). For Android emulator, use http://10.0.2.2:8000.",
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: controller,
                              decoration: const InputDecoration(hintText: "http://<ip>:8000/api/v1"),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                          ElevatedButton(
                            onPressed: () {
                              ApiEndpoints.setBaseUrl(controller.text.trim());
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Server URL updated: ${ApiEndpoints.baseUrl}"), backgroundColor: AppColors.primary),
                              );
                            },
                            child: const Text("Save"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: AppColors.primary),
                  title: const Text("Blockchain Proof Verification", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text("SHA-256 Tamper-Proof Cryptographic Anchoring"),
                  trailing: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "PRAMAAN AgTech Platform v2.0.0 (Enterprise Multi-Agent)",
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
