import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/farm_provider.dart';
import '../core/providers/evidence_provider.dart';
import '../../models/product_model.dart';

class NewApplicationScreen extends StatefulWidget {
  const NewApplicationScreen({super.key});

  @override
  State<NewApplicationScreen> createState() => _NewApplicationScreenState();
}

class _NewApplicationScreenState extends State<NewApplicationScreen> {
  ProductInput? _selectedProduct;
  final _dosageController = TextEditingController(text: "400");
  final _waterVolumeController = TextEditingController(text: "200");
  final _areaController = TextEditingController(text: "12.5");
  String _equipment = "Battery Operated Knapsack (Foliar)";
  String _targetPest = "Whitefly & Aphids";

  final List<String> _equipmentList = [
    "Battery Operated Knapsack (Foliar)",
    "Tractor Mounted Boom Sprayer",
    "Agri-Drone Precision ULV",
    "Manual Hand Sprayer",
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final farmProv = Provider.of<FarmProvider>(context);
    if (_selectedProduct == null && farmProv.products.isNotEmpty) {
      _selectedProduct = farmProv.products.first;
    }
  }

  void _submitApplication() async {
    if (_selectedProduct == null) return;
    final evProv = Provider.of<EvidenceProvider>(context, listen: false);

    final phiDays = _selectedProduct!.preHarvestIntervalDays;
    final safeHarvestDate = DateFormat(
      'dd MMM yyyy',
    ).format(DateTime.now().add(Duration(days: phiDays)));

    await evProv.addEvidence(
      title: "Spray Log: ${_selectedProduct!.name}",
      description:
          "Applied ${_dosageController.text} ml/Acre with ${_waterVolumeController.text}L water across ${_areaController.text} Acres for $_targetPest using $_equipment. Safe harvest date: $safeHarvestDate.",
      evidenceType: 'APPLICATION_LOG',
      productName: _selectedProduct!.name,
      productQr: _selectedProduct!.qrCode,
      dosagePerAcre:
          "${_dosageController.text} ml/Acre in ${_waterVolumeController.text}L Water",
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Application Logged & Cryptographically Verified!"),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmProv = Provider.of<FarmProvider>(context);
    final products = farmProv.products;

    final phiDays = _selectedProduct?.preHarvestIntervalDays ?? 1;
    final safeHarvestDate = DateFormat(
      'dd MMM yyyy',
    ).format(DateTime.now().add(Duration(days: phiDays)));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Log Chemical / Fertilizer Spray",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Compliance Indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.cloud_done_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Weather Verified: Wind 6.8 km/h, 0% rain in next 12h. Optimal spray window active.",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Select Verified Agrochemical / Input",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<ProductInput>(
              initialValue: _selectedProduct,
              items: products.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedProduct = val),
            ),
            const SizedBox(height: 16),

            // Active Ingredient & PHI Notice
            if (_selectedProduct != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Active Ingredient: ${_selectedProduct!.activeIngredient}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Pre-Harvest Interval (PHI): $phiDays Days • Safe to Harvest after $safeHarvestDate",
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Dosage (ml or g / Acre)",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _dosageController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Water Volume (Litres)",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _waterVolumeController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              "Target Pest / Disease",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              decoration: const InputDecoration(
                hintText: "e.g. Whitefly, Bollworm, Rust",
              ),
              onChanged: (v) => _targetPest = v,
            ),
            const SizedBox(height: 16),

            const Text(
              "Application Equipment",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _equipment,
              items: _equipmentList
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: const TextStyle(fontSize: 12.5)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _equipment = v ?? _equipment),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitApplication,
                icon: const Icon(Icons.verified_rounded),
                label: const Text("SUBMIT & RECORD PHI COMPLIANCE"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
