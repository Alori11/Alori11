import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import 'models/location_model.dart';

class TrackingRepository {
  final ApiClient _client;

  TrackingRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  Future<LocationModel> getLiveLocation(String vehicleId) async {
    try {
      final response = await _client
          .get<Map<String, dynamic>>('/tracking/$vehicleId/live');
      return LocationModel.fromJson(response.data!);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<TripModel>> getHistory({
    required String vehicleId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await _client.get<dynamic>(
        '/tracking/$vehicleId/history',
        queryParameters: {
          'from': from.toIso8601String(),
          'to': to.toIso8601String(),
        },
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is Map && data['trips'] is List) {
        return (data['trips'] as List)
            .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is NetworkException) return error;
    return NetworkException(message: error.toString());
  }
}
