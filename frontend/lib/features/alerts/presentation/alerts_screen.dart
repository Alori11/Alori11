import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/alert_model.dart';
import '../domain/alerts_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Stack(
          alignment: Alignment.topLeft,
          children: [
            const Text(AppStrings.alerts),
            alertsAsync.when(
              data: (state) => state.unreadCount > 0
                  ? Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          state.unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          if (alertsAsync.value?.unreadCount != null &&
              alertsAsync.value!.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(alertsProvider.notifier).markAllAsRead(),
              child: const Text(
                AppStrings.markAllRead,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(alertsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: alertsAsync.when(
        loading: () => const LoadingWidget(message: AppStrings.loading),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.read(alertsProvider.notifier).refresh(),
        ),
        data: (state) {
          if (state.error != null && state.alerts.isEmpty) {
            return AppErrorWidget(
              message: state.error,
              onRetry: () => ref.read(alertsProvider.notifier).refresh(),
            );
          }
          if (state.alerts.isEmpty) {
            return const EmptyWidget(
              message: AppStrings.noAlerts,
              subtitle: 'لا توجد تنبيهات حتى الآن',
              icon: Icons.notifications_off_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(alertsProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.alerts.length,
              itemBuilder: (context, index) {
                final alert = state.alerts[index];
                return _AlertCard(
                  alert: alert,
                  onDismiss: () =>
                      ref.read(alertsProvider.notifier).deleteAlert(alert.id),
                  onTap: () {
                    if (!alert.read) {
                      ref.read(alertsProvider.notifier).markAsRead(alert.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _AlertCard({
    required this.alert,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: alert.read ? Colors.white : alert.color.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: alert.read
                ? Border.all(color: AppColors.divider)
                : Border.all(color: alert.color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      alert.createdAt.toShortTime(),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      alert.createdAt.isToday
                          ? 'اليوم'
                          : alert.createdAt.toShortDate(),
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (!alert.read)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: alert.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                const Spacer(),
                // Content
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        alert.typeLabel,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: alert.color,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.message,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (alert.vehicleName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          alert.vehicleName!,
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: alert.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(alert.icon, color: alert.color, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
