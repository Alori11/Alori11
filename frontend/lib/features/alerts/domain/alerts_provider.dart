import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/alerts_repository.dart';
import '../data/models/alert_model.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository();
});

class AlertsState {
  final bool isLoading;
  final List<AlertModel> alerts;
  final String? error;

  const AlertsState({
    this.isLoading = false,
    this.alerts = const [],
    this.error,
  });

  AlertsState copyWith({
    bool? isLoading,
    List<AlertModel>? alerts,
    String? error,
  }) {
    return AlertsState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      error: error,
    );
  }

  int get unreadCount => alerts.where((a) => !a.read).length;
}

class AlertsNotifier extends AsyncNotifier<AlertsState> {
  @override
  Future<AlertsState> build() async {
    return _fetch();
  }

  Future<AlertsState> _fetch() async {
    final repo = ref.read(alertsRepositoryProvider);
    try {
      final alerts = await repo.listAlerts();
      return AlertsState(alerts: alerts);
    } catch (e) {
      return AlertsState(
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> markAsRead(String alertId) async {
    final repo = ref.read(alertsRepositoryProvider);
    try {
      await repo.markAsRead(alertId);
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            alerts: current.alerts
                .map((a) => a.id == alertId ? a.copyWith(read: true) : a)
                .toList(),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final repo = ref.read(alertsRepositoryProvider);
    try {
      await repo.markAllAsRead();
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            alerts: current.alerts.map((a) => a.copyWith(read: true)).toList(),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> deleteAlert(String alertId) async {
    final repo = ref.read(alertsRepositoryProvider);
    try {
      await repo.deleteAlert(alertId);
      final current = state.value;
      if (current != null) {
        state = AsyncData(
          current.copyWith(
            alerts: current.alerts.where((a) => a.id != alertId).toList(),
          ),
        );
      }
    } catch (_) {}
  }
}

final alertsProvider =
    AsyncNotifierProvider<AlertsNotifier, AlertsState>(AlertsNotifier.new);

final unreadAlertsCountProvider = Provider<int>((ref) {
  return ref.watch(alertsProvider).value?.unreadCount ?? 0;
});
