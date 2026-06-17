import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../vehicles/domain/vehicles_provider.dart';
import '../domain/devices_provider.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  ConsumerState<DevicePairingScreen> createState() =>
      _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _imeiController = TextEditingController();
  final _scannerController = MobileScannerController();

  String? _selectedVehicleId;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) {
        _scannerController.stop();
      } else {
        _scannerController.start();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imeiController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedVehicleId == null) {
      context.showSnackBar('يرجى اختيار المركبة', isError: true);
      return;
    }

    final success = await ref.read(devicesProvider.notifier).pairDevice(
          imei: _imeiController.text.trim(),
          vehicleId: _selectedVehicleId!,
        );

    if (mounted) {
      if (success) {
        context.showSnackBar(AppStrings.devicePaired);
        context.pop();
      } else {
        context.showSnackBar('فشل ربط الجهاز، يرجى التحقق من رقم IMEI', isError: true);
      }
    }
  }

  void _onQRScanned(String imei) {
    if (_scanned) return;
    _scanned = true;
    _imeiController.text = imei;
    _tabController.animateTo(0);
    _scannerController.stop();
    context.showSnackBar('تم مسح رمز QR: $imei');
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesProvider);
    final devicesState = ref.watch(devicesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppStrings.pairDevice),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle:
                  const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              tabs: const [
                Tab(
                  icon: Icon(Icons.keyboard_rounded),
                  text: AppStrings.manualEntry,
                ),
                Tab(
                  icon: Icon(Icons.qr_code_scanner_rounded),
                  text: AppStrings.scanQr,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Manual entry tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          label: AppStrings.imeiNumber,
                          hint: AppStrings.imeiHint,
                          controller: _imeiController,
                          keyboardType: TextInputType.number,
                          textDirection: TextDirection.ltr,
                          maxLength: 15,
                          prefixIcon: const Icon(Icons.device_hub_rounded),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: Validators.validateIMEI,
                        ),
                        const SizedBox(height: 20),
                        // Vehicle selector
                        const Text(
                          'اختر المركبة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        vehiclesAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (e, _) => Text(
                            'خطأ في تحميل المركبات',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              color: AppColors.error,
                            ),
                          ),
                          data: (vehicles) => DropdownButtonFormField<String>(
                            value: _selectedVehicleId,
                            hint: const Text(
                              'اختر المركبة',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: AppColors.textSecondary,
                              ),
                            ),
                            items: vehicles
                                .map((v) => DropdownMenuItem(
                                      value: v.id,
                                      child: Text(
                                        '${v.displayName} - ${v.plateNumber}',
                                        style: const TextStyle(fontFamily: 'Cairo'),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedVehicleId = v),
                            decoration: InputDecoration(
                              prefixIcon:
                                  const Icon(Icons.directions_car_rounded),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    const BorderSide(color: AppColors.divider),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            isExpanded: true,
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomButton(
                          label: AppStrings.pairNow,
                          onPressed: _pair,
                          isLoading: devicesState.isLoading,
                          icon: Icons.link_rounded,
                        ),
                      ],
                    ),
                  ),
                ),

                // QR Scanner tab
                Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: (capture) {
                              final barcode = capture.barcodes.firstOrNull;
                              if (barcode?.rawValue != null) {
                                _onQRScanned(barcode!.rawValue!);
                              }
                            },
                          ),
                          // Overlay
                          Center(
                            child: Container(
                              width: 230,
                              height: 230,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        AppStrings.scanQrDesc,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
