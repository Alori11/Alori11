import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/maintenance_repository.dart';
import '../data/models/maintenance_model.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepository();
});

class MaintenanceState {
  final bool isLoading;
  final List<MaintenanceModel> records;
  final String? error;

  const MaintenanceState({
    this.isLoading = false,
    this.records = const [],
    this.error,
  });

  MaintenanceState copyWith({
    bool? isLoading,
    List<MaintenanceModel>? records,
    String? error,
  }) {
    return MaintenanceState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      error: error,
    );
  }

  List<MaintenanceModel> get overdueRecords =>
      records.where((r) => r.status == MaintenanceStatus.overdue).toList();

  List<MaintenanceModel> get dueSoonRecords =>
      records.where((r) => r.status == MaintenanceStatus.dueSoon).toList();

  List<MaintenanceModel> get upToDateRecords =>
      records.where((r) => r.status == MaintenanceStatus.upToDate).toList();
}

class MaintenanceNotifier extends FamilyNotifier<MaintenanceState, String> {
  @override
  MaintenanceState build(String vehicleId) {
    _fetch(vehicleId);
    return const MaintenanceState(isLoading: true);
  }

  Future<void> _fetch(String vehicleId) async {
    final repo = ref.read(maintenanceRepositoryProvider);
    try {
      final records = await repo.listMaintenance(vehicleId);
      state = state.copyWith(isLoading: false, records: records);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> addRecord(Map<String, dynamic> data) async {
    final repo = ref.read(maintenanceRepositoryProvider);
    try {
      final record = await repo.createMaintenance({...data, 'vehicleId': arg});
      state = state.copyWith(records: [record, ...state.records]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteRecord(String id) async {
    final repo = ref.read(maintenanceRepositoryProvider);
    try {
      await repo.deleteMaintenance(id);
      state = state.copyWith(
        records: state.records.where((r) => r.id != id).toList(),
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _fetch(arg);
  }
}

final maintenanceProvider =
    NotifierProvider.family<MaintenanceNotifier, MaintenanceState, String>(
  MaintenanceNotifier.new,
);
