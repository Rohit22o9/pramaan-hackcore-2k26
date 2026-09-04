import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/farm_provider.dart';
import '../core/providers/evidence_provider.dart';
import '../core/services/google_sheets_service.dart';

class FarmerAuthScreen extends StatefulWidget {
  const FarmerAuthScreen({super.key});

  @override
  State<FarmerAuthScreen> createState() => _FarmerAuthScreenState();
}

class _FarmerAuthScreenState extends State<FarmerAuthScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _villageController = TextEditingController(text: "Nashik");
  final _stateController = TextEditingController(text: "Maharashtra");
  final _cropController = TextEditingController(text: "Cotton");
  final _acresController = TextEditingController(text: "10.0");

  bool _isLoading = false;
  bool _showExtraDetails = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _villageController.dispose();
    _stateController.dispose();
    _cropController.dispose();
    _acresController.dispose();
    super.dispose();
  }

  void _loginFarmerAccount() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("कृपया आपले नाव आणि मोबाईल नंबर टाका (Please enter your name & mobile number)"),
          backgroundColor: AppColors.flaggedRed,
        ),
      );
      return;
    }

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("कृपया १० अंकी वैध मोबाईल नंबर टाका (Please enter valid 10-digit mobile number)"),
          backgroundColor: AppColors.flaggedRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final finalVillage = _villageController.text.trim().isNotEmpty ? _villageController.text.trim() : "Nashik";
    final finalState = _stateController.text.trim().isNotEmpty ? _stateController.text.trim() : "Maharashtra";
    final finalCrop = _cropController.text.trim().isNotEmpty ? _cropController.text.trim() : "Cotton";
    final finalAcres = double.tryParse(_acresController.text.trim()) ?? 10.0;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final evProv = Provider.of<EvidenceProvider>(context, listen: false);
    final farmProv = Provider.of<FarmProvider>(context, listen: false);

    // 1. Live Google Sheets Webhook Sync (Farmers Tab)
    try {
      final res = await GoogleSheetsService().loginOrRegisterFarmer(
        name: name,
        phone: phone,
        village: finalVillage,
        state: finalState,
        crop: finalCrop,
        acres: finalAcres,
      );

      debugPrint("[Farmer Auth] Google Sheets result: $res");

      // Check if server returned NAME_MISMATCH error
      if (res['status'] == 'error' && (res['error_type'] == 'NAME_MISMATCH' || res['registered_name'] != null)) {
        if (mounted) {
          setState(() => _isLoading = false);
          final registeredName = res['registered_name']?.toString() ?? "";
          _showNameMismatchDialog(registeredName, phone);
        }
        return;
      }

      if (res['farmer'] != null) {
        final f = res['farmer'];
        final actualName = f['name']?.toString() ?? name;
        final actualPhone = f['phone']?.toString() ?? phone;
        final actualVillage = f['village']?.toString() ?? finalVillage;
        final actualState = f['state']?.toString() ?? finalState;
        final actualCrop = f['crop']?.toString() ?? finalCrop;
        final actualAcres = (f['acres'] as num?)?.toDouble() ?? finalAcres;

        auth.loginFarmer(
          name: actualName,
          phone: actualPhone,
          village: actualVillage,
          state: actualState,
          crop: actualCrop,
          acres: actualAcres,
        );

        evProv.setActiveFarmer(phone: actualPhone, name: actualName);
      } else {
        auth.loginFarmer(
          name: name,
          phone: phone,
          village: finalVillage,
          state: finalState,
          crop: finalCrop,
          acres: finalAcres,
        );
        evProv.setActiveFarmer(phone: phone, name: name);
      }
    } catch (e) {
      debugPrint("[Farmer Auth] Sync warning: $e");
      auth.loginFarmer(
        name: name,
        phone: phone,
        village: finalVillage,
        state: finalState,
        crop: finalCrop,
        acres: finalAcres,
      );
      evProv.setActiveFarmer(phone: phone, name: name);
    }

    // Match farm if available
    try {
      final matchedFarm = farmProv.farms.firstWhere(
        (f) => f.state.toLowerCase() == finalState.toLowerCase(),
        orElse: () => farmProv.farms.first,
      );
      farmProv.selectFarm(matchedFarm);
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("स्वागत आहे ${auth.userName}! आपले खाते यशस्वीरीत्या उघडले."),
          backgroundColor: const Color(0xFF047857),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushReplacementNamed(context, '/farmer_dashboard');
    }
  }

  void _showNameMismatchDialog(String registeredName, String phone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 24),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "नाव जुळत नाही\n(Name Mismatch)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "मोबाईल नंबर +91 $phone हा आधीच खालील नोंदणीकृत नावावर सुरक्षित आहे:",
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF047857), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      registeredName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "डेटा सुरक्षिततेसाठी, खात्याचे नोंदणीकृत नाव बदलता येत नाही. कृपया लॉगिन करण्यासाठी अचूक नोंदणीकृत नाव वापरा.",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("नाव दुरुस्त करा (Edit Name)", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: Text("हे नाव वापरा ('$registeredName')"),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _nameController.text = registeredName;
              });
              _loginFarmerAccount();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryDark),
          onPressed: () => Navigator.pushReplacementNamed(context, '/profile_selection'),
        ),
        title: const Text(
          "Farmer Login / शेतकरी लॉगिन",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security / OTP-Free Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        "Live Google Sheets Database Connected",
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Brand Icon & Welcome Title
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                      ),
                      child: const Icon(Icons.agriculture_rounded, color: AppColors.primary, size: 44),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "PRAMAAN AGTECH",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "नाव व मोबाईल नंबर टाकून प्रवेश करा",
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                    ),
                    const Text(
                      "Enter Name & Mobile Number to Register / Login",
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Main Simple Login Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Field 1: Farmer Full Name
                    const Row(
                      children: [
                        Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Farmer Full Name (शेतकऱ्याचे नाव)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: "उदा. रमेश पाटील / Gurpreet Singh",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Field 2: Mobile Number
                    const Row(
                      children: [
                        Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 18),
                        SizedBox(width: 6),
                        Text(
                          "Mobile Number (मोबाईल नंबर)",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      decoration: InputDecoration(
                        prefixText: "+91 ",
                        prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        hintText: "१० अंकी मोबाईल नंबर टाका",
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, letterSpacing: 0),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Optional Expandable Location & Farm details
                    InkWell(
                      onTap: () => setState(() => _showExtraDetails = !_showExtraDetails),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              _showExtraDetails ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                "गाव व पीक माहिती जोडा (Village & Crop Details)",
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showExtraDetails) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmallField("गाव (Village)", _villageController, Icons.location_on_rounded),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSmallField("राज्य (State)", _stateController, Icons.map_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmallField("मुख्य पीक (Crop)", _cropController, Icons.eco_rounded),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildSmallField("क्षेत्र एकर (Acres)", _acresController, Icons.straighten_rounded, keyboardType: TextInputType.number),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Big Action Button: Enter Farm
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _loginFarmerAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF047857),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.login_rounded, size: 22),
                        label: Text(
                          _isLoading ? "CONNECTING TO GOOGLE SHEET..." : "ENTER MY FARM (प्रवेश करा)",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Info Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "आपला डेटा थेट Google Sheets मध्ये सुरक्षित सेव्ह होतो. कोणतीही खोटी माहिती साठवली जात नाही.",
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallField(String label, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: AppColors.primary),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }
}
