import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../domain/vehicles_provider.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();

  String? _selectedMake;
  String? _selectedColor;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedMake == null) {
      context.showSnackBar('يرجى اختيار الشركة المصنّعة', isError: true);
      return;
    }
    if (_selectedColor == null) {
      context.showSnackBar('يرجى اختيار اللون', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(vehiclesProvider.notifier).addVehicle(
          make: _selectedMake!,
          model: _modelController.text.trim(),
          year: _selectedYear,
          plateNumber: _plateController.text.trim(),
          color: _selectedColor!,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.showSnackBar('تمت إضافة المركبة بنجاح');
        context.pop();
      } else {
        context.showSnackBar('حدث خطأ أثناء إضافة المركبة', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppStrings.addVehicle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Make dropdown
              _DropdownField(
                label: AppStrings.vehicleMake,
                hint: 'اختر الشركة المصنّعة',
                value: _selectedMake,
                items: AppConstants.carMakes,
                onChanged: (v) => setState(() => _selectedMake = v),
                icon: Icons.directions_car_rounded,
              ),
              const SizedBox(height: 16),
              // Model
              CustomTextField(
                label: AppStrings.vehicleModel,
                hint: 'مثال: كامري، باجيرو',
                controller: _modelController,
                prefixIcon: const Icon(Icons.car_repair_rounded),
                validator: Validators.validateRequired,
              ),
              const SizedBox(height: 16),
              // Year picker
              _YearPickerField(
                selectedYear: _selectedYear,
                onChanged: (y) => setState(() => _selectedYear = y),
              ),
              const SizedBox(height: 16),
              // Plate number
              CustomTextField(
                label: AppStrings.plateNumber,
                hint: 'أ ب ج 1234',
                controller: _plateController,
                prefixIcon: const Icon(Icons.credit_card_rounded),
                validator: Validators.validateRequired,
              ),
              const SizedBox(height: 16),
              // Color
              _ColorDropdown(
                selectedColor: _selectedColor,
                onChanged: (c) => setState(() => _selectedColor = c),
              ),
              const SizedBox(height: 32),
              CustomButton(
                label: AppStrings.addVehicle,
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.add_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(
              fontFamily: 'Cairo',
              color: AppColors.textSecondary,
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: const TextStyle(fontFamily: 'Cairo'),
                      textDirection: TextDirection.rtl,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          isExpanded: true,
        ),
      ],
    );
  }
}

class _YearPickerField extends StatelessWidget {
  final int selectedYear;
  final ValueChanged<int> onChanged;

  const _YearPickerField({
    required this.selectedYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(
      currentYear - 1990 + 1,
      (i) => currentYear - i,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          AppStrings.vehicleYear,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: selectedYear,
          items: years
              .map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(
                      y.toString(),
                      style: const TextStyle(fontFamily: 'Cairo'),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.calendar_today_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorDropdown extends StatelessWidget {
  final String? selectedColor;
  final ValueChanged<String?> onChanged;

  const _ColorDropdown({
    required this.selectedColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text(
          AppStrings.vehicleColor,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedColor,
          hint: const Text(
            'اختر اللون',
            style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
          ),
          items: AppConstants.vehicleColors
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      style: const TextStyle(fontFamily: 'Cairo'),
                      textDirection: TextDirection.rtl,
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.palette_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
