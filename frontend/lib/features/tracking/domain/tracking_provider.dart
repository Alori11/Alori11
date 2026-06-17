import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tracking_repository.dart';
import '../data/models/location_model.dart';
import '../../../core/constants/app_constants.dart';

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepository();
});

// ---------------------------------------------------------------------------
// Live location provider - auto-refreshes every 30 seconds
// ---------------------------------------------------------------------------

final liveLocationProvider = StreamProvider.family<LocationModel, String>(
  (ref, vehicleId) {
    final repo = ref.read(trackingRepositoryProvider);
    final controller = StreamController<LocationModel>();

    Future<void> fetch() async {
      try {
        final location = await repo.getLiveLocation(vehicleId);
        if (!controller.isClosed) {
          controller.add(location);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Initial fetch
    fetch();

    // Periodic refresh
    final timer = Timer.periodic(
      const Duration(seconds: AppConstants.liveTrackingRefreshSeconds),
      (_) => fetch(),
    );

    ref.onDispose(() {
      timer.cancel();
      controller.close();
    });

    return controller.stream;
  },
);

// ---------------------------------------------------------------------------
// Trip history state
// ---------------------------------------------------------------------------

class TripHistoryState {
  final bool isLoading;
  final List<TripModel> trips;
  final String? error;
  final DateTime from;
  final DateTime to;

  TripHistoryState({
    this.isLoading = false,
    this.trips = const [],
    this.error,
    DateTime? from,
    DateTime? to,
  })  : from = from ?? DateTime.now().subtract(const Duration(days: 7)),
        to = to ?? DateTime.now();

  TripHistoryState copyWith({
    bool? isLoading,
    List<TripModel>? trips,
    String? error,
    DateTime? from,
    DateTime? to,
  }) {
    return TripHistoryState(
      isLoading: isLoading ?? this.isLoading,
      trips: trips ?? this.trips,
      error: error,
      from: from ?? this.from,
      to: to ?? this.to,
    );
  }
}

class TripHistoryNotifier extends FamilyNotifier<TripHistoryState, String> {
  @override
  TripHistoryState build(String vehicleId) {
    _fetch(vehicleId);
    return TripHistoryState();
  }

  Future<void> _fetch(String vehicleId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(trackingRepositoryProvider);
      final trips = await repo.getHistory(
        vehicleId: vehicleId,
        from: state.from,
        to: state.to,
      );
      state = state.copyWith(isLoading: false, trips: trips);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> setDateRange(DateTime from, DateTime to) async {
    state = state.copyWith(from: from, to: to);
    await _fetch(arg);
  }

  Future<void> refresh() async {
    await _fetch(arg);
  }
}

final tripHistoryProvider =
    NotifierProvider.family<TripHistoryNotifier, TripHistoryState, String>(
  TripHistoryNotifier.new,
);
