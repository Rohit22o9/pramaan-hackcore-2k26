import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/farm_provider.dart';
import '../core/providers/evidence_provider.dart';
import '../../models/product_model.dart';

class ScanProductScreen extends StatefulWidget {
  const ScanProductScreen({super.key});

  @override
  State<ScanProductScreen> createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  ProductInput? _scannedProduct;
  bool _isScanning = false;

  void _simulateScan(ProductInput product) async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      setState(() {
        _isScanning = false;
        _scannedProduct = product;
      });
    }
  }

  void _saveProductEvidence() async {
    if (_scannedProduct == null) return;
    final evProv = Provider.of<EvidenceProvider>(context, listen: false);

    await evProv.addEvidence(
      title: "Input Verified: ${_scannedProduct!.name}",
      description:
          "Scanned QR ${_scannedProduct!.qrCode}. Batch ${_scannedProduct!.verifiedBatchNo} verified authentic with ${_scannedProduct!.manufacturer}.",
      evidenceType: 'PRODUCT_SCAN',
      productQr: _scannedProduct!.qrCode,
      productName: _scannedProduct!.name,
      dosagePerAcre: _scannedProduct!.recommendedDose,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Input Product Verified & Added to Evidence Chain!"),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Scan Input Bottle / Seed QR",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Scanner Viewport Box
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70, width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_2_rounded,
                          size: 100,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                  ),
                  if (_isScanning)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Align QR / Barcode within frame",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Selectable Demo QR Samples
            const Text(
              "Select Bottle / Package to Scan:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: products.map((prod) {
                final isSelected = _scannedProduct?.qrCode == prod.qrCode;
                return ChoiceChip(
                  label: Text(
                    prod.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primarySurface,
                  onSelected: (selected) {
                    if (selected) _simulateScan(prod);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Verification Result Card
            if (_scannedProduct != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.primaryDark,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "GENUINE BATCH VERIFIED",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _scannedProduct!.toxicityBand,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildDetailRow("Product Name", _scannedProduct!.name),
                    _buildDetailRow(
                      "Manufacturer",
                      _scannedProduct!.manufacturer,
                    ),
                    _buildDetailRow(
                      "Active Ingredient",
                      _scannedProduct!.activeIngredient,
                    ),
                    _buildDetailRow(
                      "Batch Number",
                      _scannedProduct!.verifiedBatchNo,
                    ),
                    _buildDetailRow(
                      "Recommended Dose",
                      _scannedProduct!.recommendedDose,
                    ),
                    _buildDetailRow(
                      "Safe Pre-Harvest Interval (PHI)",
                      "${_scannedProduct!.preHarvestIntervalDays} Days",
                    ),
                    _buildDetailRow("Expiry Date", _scannedProduct!.expiryDate),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveProductEvidence,
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text("LINK PRODUCT TO FIELD EVIDENCE"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
