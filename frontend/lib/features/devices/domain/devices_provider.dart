import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/devices_repository.dart';
import '../data/models/device_model.dart';

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  return DevicesRepository();
});

final devicesProvider =
    AsyncNotifierProvider<DevicesNotifier, List<DeviceModel>>(
  DevicesNotifier.new,
);

class DevicesNotifier extends AsyncNotifier<List<DeviceModel>> {
  @override
  Future<List<DeviceModel>> build() async {
    return _fetch();
  }

  Future<List<DeviceModel>> _fetch() async {
    final repo = ref.read(devicesRepositoryProvider);
    return repo.listDevices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> pairDevice({
    required String imei,
    required String vehicleId,
  }) async {
    final repo = ref.read(devicesRepositoryProvider);
    try {
      final device = await repo.pairDevice(imei: imei, vehicleId: vehicleId);
      state = AsyncData([...?state.value, device]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unpairDevice(String deviceId) async {
    final repo = ref.read(devicesRepositoryProvider);
    try {
      await repo.unpairDevice(deviceId);
      final current = state.value ?? [];
      state = AsyncData(current.where((d) => d.id != deviceId).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

// Pairing state
class PairingState {
  final bool isLoading;
  final String? error;
  final bool success;

  const PairingState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });
}

final pairingStateProvider =
    StateNotifierProvider<PairingNotifier, PairingState>((ref) {
  return PairingNotifier();
});

class PairingNotifier extends StateNotifier<PairingState> {
  PairingNotifier() : super(const PairingState());

  void setLoading() => state = const PairingState(isLoading: true);
  void setSuccess() => state = const PairingState(success: true);
  void setError(String error) => state = PairingState(error: error);
  void reset() => state = const PairingState();
}
