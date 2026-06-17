import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import 'models/alert_model.dart';

class AlertsRepository {
  final ApiClient _client;

  AlertsRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  Future<List<AlertModel>> listAlerts({bool? unreadOnly}) async {
    try {
      final response = await _client.get<dynamic>(
        '/alerts',
        queryParameters: {
          if (unreadOnly != null) 'unread': unreadOnly,
        },
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is Map && data['alerts'] is List) {
        return (data['alerts'] as List)
            .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAsRead(String alertId) async {
    try {
      await _client.patch('/alerts/$alertId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _client.post('/alerts/read-all');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteAlert(String alertId) async {
    try {
      await _client.delete('/alerts/$alertId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is NetworkException) return error;
    return NetworkException(message: error.toString());
  }
}
