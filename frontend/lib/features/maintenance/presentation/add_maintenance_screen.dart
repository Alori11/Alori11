import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../domain/maintenance_provider.dart';

class AddMaintenanceScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const AddMaintenanceScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<AddMaintenanceScreen> createState() =>
      _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends ConsumerState<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedType;
  DateTime _date = DateTime.now();
  DateTime? _nextDueDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickNextDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
      locale: const Locale('ar'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _nextDueDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedType == null) {
      context.showSnackBar('يرجى اختيار نوع الصيانة', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success =
        await ref.read(maintenanceProvider(widget.vehicleId).notifier).addRecord({
      'type': _selectedType,
      'date': _date.toIso8601String(),
      'mileage': int.tryParse(_mileageController.text) ?? 0,
      'cost': double.tryParse(_costController.text),
      'notes': _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      'nextDueDate': _nextDueDate?.toIso8601String(),
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.showSnackBar('تمت إضافة سجل الصيانة بنجاح');
        context.pop();
      } else {
        context.showSnackBar('حدث خطأ أثناء الإضافة', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(AppStrings.addMaintenance),
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Type selector
              const Text(
                AppStrings.maintenanceType,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                hint: const Text(
                  'اختر نوع الصيانة',
                  style: TextStyle(fontFamily: 'Cairo', color: AppColors.textSecondary),
                ),
                items: AppConstants.maintenanceTypes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            t,
                            style: const TextStyle(fontFamily: 'Cairo'),
                            textDirection: TextDirection.rtl,
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.build_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
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
              const SizedBox(height: 16),
              // Date
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: AppStrings.maintenanceDate,
                    controller: TextEditingController(
                        text: _date.toShortDate()),
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    readOnly: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Mileage
              CustomTextField(
                label: AppStrings.mileage,
                hint: '50000',
                controller: _mileageController,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                prefixIcon: const Icon(Icons.speed_rounded),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.validateMileage,
              ),
              const SizedBox(height: 16),
              // Cost (optional)
              CustomTextField(
                label: '${AppStrings.cost} (اختياري)',
                hint: '200.00',
                controller: _costController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textDirection: TextDirection.ltr,
                prefixIcon: const Icon(Icons.payments_rounded),
                validator: Validators.validateCost,
              ),
              const SizedBox(height: 16),
              // Notes
              CustomTextField(
                label: '${AppStrings.notes} (اختياري)',
                hint: 'ملاحظات إضافية...',
                controller: _notesController,
                maxLines: 3,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
              const SizedBox(height: 16),
              // Next due date
              GestureDetector(
                onTap: _pickNextDueDate,
                child: AbsorbPointer(
                  child: CustomTextField(
                    label: '${AppStrings.nextDueDate} (اختياري)',
                    controller: TextEditingController(
                        text: _nextDueDate?.toShortDate() ?? ''),
                    hint: 'اختر تاريخ الاستحقاق التالي',
                    prefixIcon: const Icon(Icons.event_rounded),
                    readOnly: true,
                  ),
                ),
              ),
              if (_nextDueDate != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _nextDueDate = null),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text(
                      'إزالة التاريخ',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12),
                    ),
                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              CustomButton(
                label: AppStrings.addMaintenance,
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.save_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
