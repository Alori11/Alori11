import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicles/data/vehicles_repository.dart';
import '../../vehicles/data/models/vehicle_model.dart';
import '../../alerts/data/alerts_repository.dart';
import '../../alerts/data/models/alert_model.dart';

class DashboardState {
  final bool isLoading;
  final List<VehicleModel> vehicles;
  final List<AlertModel> recentAlerts;
  final String? error;

  const DashboardState({
    this.isLoading = false,
    this.vehicles = const [],
    this.recentAlerts = const [],
    this.error,
  });

  DashboardState copyWith({
    bool? isLoading,
    List<VehicleModel>? vehicles,
    List<AlertModel>? recentAlerts,
    String? error,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      vehicles: vehicles ?? this.vehicles,
      recentAlerts: recentAlerts ?? this.recentAlerts,
      error: error,
    );
  }

  int get onlineCount => vehicles.where((v) => v.isOnline).length;
}

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() async {
    return _fetch();
  }

  Future<DashboardState> _fetch() async {
    try {
      final vehiclesRepo = VehiclesRepository();
      final alertsRepo = AlertsRepository();

      final results = await Future.wait([
        vehiclesRepo.listVehicles(),
        alertsRepo.listAlerts(unreadOnly: false),
      ]);

      final vehicles = results[0] as List<VehicleModel>;
      final alerts = results[1] as List<AlertModel>;

      return DashboardState(
        vehicles: vehicles,
        recentAlerts: alerts.take(5).toList(),
      );
    } catch (e) {
      return DashboardState(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);
