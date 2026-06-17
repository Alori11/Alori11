import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/device_model.dart';
import '../domain/devices_provider.dart';

class DevicesListScreen extends ConsumerWidget {
  const DevicesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.devices),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(devicesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: devicesAsync.when(
        loading: () => const LoadingWidget(message: AppStrings.loading),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(devicesProvider.notifier).refresh(),
        ),
        data: (devices) {
          if (devices.isEmpty) {
            return EmptyWidget(
              message: 'لا توجد أجهزة مقترنة',
              subtitle: 'اضغط + لربط جهاز OBD-II',
              icon: Icons.device_hub_rounded,
              onAction: () => context.push(AppRoutes.pairDevice),
              actionLabel: AppStrings.pairDevice,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(devicesProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return _DeviceCard(
                  device: devices[index],
                  onUnpair: () async {
                    await ref
                        .read(devicesProvider.notifier)
                        .unpairDevice(devices[index].id);
                    if (context.mounted) {
                      context.showSnackBar('تم إلغاء ربط الجهاز');
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.pairDevice),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback onUnpair;

  const _DeviceCard({required this.device, required this.onUnpair});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(device.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text(
              'إلغاء الربط',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        onUnpair();
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'IMEI: ${device.imei}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (device.battery != null) ...[
                          Text(
                            '${device.battery}%',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.battery_full_rounded,
                              size: 16, color: AppColors.success),
                          const SizedBox(width: 12),
                        ],
                        Text(
                          '${device.signal}% ${device.signalBars}',
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.signal_cellular_alt_rounded,
                            size: 16, color: AppColors.info),
                      ],
                    ),
                    if (device.lastSeen != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${AppStrings.lastSeen}: ${device.lastSeen!.toTimeAgo()}',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Status indicator
              Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: device.isOnline
                          ? AppColors.online.withOpacity(0.1)
                          : AppColors.offline.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.router_rounded,
                      color: device.isOnline ? AppColors.online : AppColors.offline,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: device.isOnline
                          ? AppColors.online.withOpacity(0.1)
                          : AppColors.offline.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      device.isOnline
                          ? AppStrings.deviceOnline
                          : AppStrings.deviceOffline,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: device.isOnline ? AppColors.online : AppColors.offline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
