import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/vehicle_model.dart';
import '../domain/vehicles_provider.dart';

class VehiclesListScreen extends ConsumerWidget {
  const VehiclesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.vehicles),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(vehiclesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: vehiclesAsync.when(
        loading: () => const LoadingWidget(message: AppStrings.loading),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(vehiclesProvider.notifier).refresh(),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyWidget(
              message: AppStrings.noVehiclesYet,
              subtitle: AppStrings.addVehicleHint,
              icon: Icons.directions_car_rounded,
              onAction: () => context.push(AppRoutes.addVehicle),
              actionLabel: AppStrings.addVehicle,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(vehiclesProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                return _VehicleListTile(
                  vehicle: vehicles[index],
                  onDelete: () async {
                    final confirmed = await _confirmDelete(context);
                    if (confirmed) {
                      await ref
                          .read(vehiclesProvider.notifier)
                          .deleteVehicle(vehicles[index].id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addVehicle),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              'حذف المركبة',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
              textDirection: TextDirection.rtl,
            ),
            content: const Text(
              'هل تريد حذف هذه المركبة؟ لا يمكن التراجع عن هذا الإجراء.',
              style: TextStyle(fontFamily: 'Cairo'),
              textDirection: TextDirection.rtl,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(AppStrings.cancel,
                    style: TextStyle(fontFamily: 'Cairo')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text(AppStrings.delete,
                    style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _VehicleListTile extends StatelessWidget {
  final VehicleModel vehicle;
  final VoidCallback onDelete;

  const _VehicleListTile({
    required this.vehicle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(vehicle.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // Deletion handled by onDelete callback
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/tracking/${vehicle.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Actions column
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.my_location_rounded,
                          color: AppColors.primary, size: 22),
                      onPressed: () =>
                          context.push('/tracking/${vehicle.id}'),
                      tooltip: AppStrings.liveTracking,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: const Icon(Icons.build_rounded,
                          color: AppColors.warning, size: 22),
                      onPressed: () =>
                          context.push('/maintenance/${vehicle.id}'),
                      tooltip: AppStrings.maintenance,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const Spacer(),
                // Vehicle info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          vehicle.displayName,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: vehicle.isOnline
                                ? AppColors.online
                                : AppColors.offline,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.plateNumber,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Tag(label: vehicle.color, color: AppColors.info),
                        const SizedBox(width: 6),
                        _Tag(
                          label: vehicle.year.toString(),
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                // Vehicle icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
