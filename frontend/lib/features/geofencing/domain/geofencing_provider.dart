import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/geofencing_repository.dart';
import '../data/models/geofence_model.dart';

final geofencingRepositoryProvider = Provider<GeofencingRepository>((ref) {
  return GeofencingRepository();
});

class GeofencingState {
  final bool isLoading;
  final List<GeofenceModel> geofences;
  final String? error;

  const GeofencingState({
    this.isLoading = false,
    this.geofences = const [],
    this.error,
  });

  GeofencingState copyWith({
    bool? isLoading,
    List<GeofenceModel>? geofences,
    String? error,
  }) {
    return GeofencingState(
      isLoading: isLoading ?? this.isLoading,
      geofences: geofences ?? this.geofences,
      error: error,
    );
  }
}

class GeofencingNotifier extends FamilyNotifier<GeofencingState, String> {
  @override
  GeofencingState build(String vehicleId) {
    _fetch(vehicleId);
    return const GeofencingState(isLoading: true);
  }

  Future<void> _fetch(String vehicleId) async {
    final repo = ref.read(geofencingRepositoryProvider);
    try {
      final geofences = await repo.listGeofences(vehicleId);
      state = state.copyWith(isLoading: false, geofences: geofences);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> addGeofence({
    required String name,
    required double lat,
    required double lng,
    required double radius,
  }) async {
    final repo = ref.read(geofencingRepositoryProvider);
    try {
      final geofence = await repo.createGeofence({
        'name': name,
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'vehicleId': arg,
        'isActive': true,
      });
      state = state.copyWith(
        geofences: [...state.geofences, geofence],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggleGeofence(String id, bool isActive) async {
    final repo = ref.read(geofencingRepositoryProvider);
    try {
      final updated = await repo.toggleGeofence(id, isActive);
      final updatedList = state.geofences
          .map((g) => g.id == id ? updated : g)
          .toList();
      state = state.copyWith(geofences: updatedList);
    } catch (_) {}
  }

  Future<void> deleteGeofence(String id) async {
    final repo = ref.read(geofencingRepositoryProvider);
    try {
      await repo.deleteGeofence(id);
      state = state.copyWith(
        geofences: state.geofences.where((g) => g.id != id).toList(),
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _fetch(arg);
  }
}

final geofencingProvider =
    NotifierProvider.family<GeofencingNotifier, GeofencingState, String>(
  GeofencingNotifier.new,
);
