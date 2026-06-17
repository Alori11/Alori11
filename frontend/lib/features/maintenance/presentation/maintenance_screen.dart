import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/maintenance_model.dart';
import '../domain/maintenance_provider.dart';

class MaintenanceScreen extends ConsumerWidget {
  final String vehicleId;

  const MaintenanceScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(maintenanceProvider(vehicleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.maintenance),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(maintenanceProvider(vehicleId).notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading
          ? const LoadingWidget()
          : state.error != null && state.records.isEmpty
              ? AppErrorWidget(
                  message: state.error,
                  onRetry: () => ref
                      .read(maintenanceProvider(vehicleId).notifier)
                      .refresh(),
                )
              : state.records.isEmpty
                  ? const EmptyWidget(
                      message: AppStrings.noMaintenance,
                      icon: Icons.build_circle_rounded,
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(maintenanceProvider(vehicleId).notifier)
                          .refresh(),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          if (state.overdueRecords.isNotEmpty) ...[
                            _SectionHeader(
                              label: AppStrings.overdue,
                              color: AppColors.error,
                              count: state.overdueRecords.length,
                            ),
                            ...state.overdueRecords.map(
                              (r) => _MaintenanceTile(
                                record: r,
                                onDelete: () => ref
                                    .read(maintenanceProvider(vehicleId)
                                        .notifier)
                                    .deleteRecord(r.id),
                              ),
                            ),
                          ],
                          if (state.dueSoonRecords.isNotEmpty) ...[
                            _SectionHeader(
                              label: AppStrings.dueSoon,
                              color: AppColors.warning,
                              count: state.dueSoonRecords.length,
                            ),
                            ...state.dueSoonRecords.map(
                              (r) => _MaintenanceTile(
                                record: r,
                                onDelete: () => ref
                                    .read(maintenanceProvider(vehicleId)
                                        .notifier)
                                    .deleteRecord(r.id),
                              ),
                            ),
                          ],
                          if (state.upToDateRecords.isNotEmpty) ...[
                            _SectionHeader(
                              label: AppStrings.upToDate,
                              color: AppColors.success,
                              count: state.upToDateRecords.length,
                            ),
                            ...state.upToDateRecords.map(
                              (r) => _MaintenanceTile(
                                record: r,
                                onDelete: () => ref
                                    .read(maintenanceProvider(vehicleId)
                                        .notifier)
                                    .deleteRecord(r.id),
                              ),
                            ),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/maintenance/$vehicleId/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontFamily: 'Cairo',
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceTile extends StatelessWidget {
  final MaintenanceModel record;
  final VoidCallback onDelete;

  const _MaintenanceTile({required this.record, required this.onDelete});

  Color get _statusColor {
    switch (record.status) {
      case MaintenanceStatus.overdue:
        return AppColors.error;
      case MaintenanceStatus.dueSoon:
        return AppColors.warning;
      case MaintenanceStatus.upToDate:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: _statusColor.withOpacity(0.3), width: 1),
        ),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Cost
              if (record.cost != null)
                Text(
                  '${record.cost!.toStringAsFixed(0)} ر',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              const Spacer(),
              // Info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      record.type,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.date.toShortDate()} - ${record.mileage.toString()} كم',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (record.nextDueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'الاستحقاق: ${record.nextDueDate!.toShortDate()}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11,
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (record.notes != null && record.notes!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.notes!,
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Status icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.build_rounded, color: _statusColor, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
