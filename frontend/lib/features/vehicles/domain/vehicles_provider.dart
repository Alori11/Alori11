import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/vehicles_repository.dart';
import '../data/models/vehicle_model.dart';

final vehiclesRepositoryProvider = Provider<VehiclesRepository>((ref) {
  return VehiclesRepository();
});

final vehiclesProvider =
    AsyncNotifierProvider<VehiclesNotifier, List<VehicleModel>>(
  VehiclesNotifier.new,
);

class VehiclesNotifier extends AsyncNotifier<List<VehicleModel>> {
  @override
  Future<List<VehicleModel>> build() async {
    return _fetch();
  }

  Future<List<VehicleModel>> _fetch() async {
    final repo = ref.read(vehiclesRepositoryProvider);
    return repo.listVehicles();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> addVehicle({
    required String make,
    required String model,
    required int year,
    required String plateNumber,
    required String color,
  }) async {
    final repo = ref.read(vehiclesRepositoryProvider);
    try {
      final vehicle = await repo.createVehicle(
        make: make,
        model: model,
        year: year,
        plateNumber: plateNumber,
        color: color,
      );
      state = AsyncData([...?state.value, vehicle]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteVehicle(String vehicleId) async {
    final repo = ref.read(vehiclesRepositoryProvider);
    try {
      await repo.deleteVehicle(vehicleId);
      final current = state.value ?? [];
      state = AsyncData(current.where((v) => v.id != vehicleId).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final selectedVehicleProvider = StateProvider<VehicleModel?>((ref) => null);
