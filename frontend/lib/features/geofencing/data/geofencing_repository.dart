import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import 'models/geofence_model.dart';

class GeofencingRepository {
  final ApiClient _client;

  GeofencingRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  Future<List<GeofenceModel>> listGeofences(String vehicleId) async {
    try {
      final response =
          await _client.get<dynamic>('/geofences?vehicleId=$vehicleId');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => GeofenceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is Map && data['geofences'] is List) {
        return (data['geofences'] as List)
            .map((e) => GeofenceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<GeofenceModel> createGeofence(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.post<Map<String, dynamic>>('/geofences', data: data);
      return GeofenceModel.fromJson(response.data!);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<GeofenceModel> toggleGeofence(String id, bool isActive) async {
    try {
      final response = await _client.patch<Map<String, dynamic>>(
        '/geofences/$id',
        data: {'isActive': isActive},
      );
      return GeofenceModel.fromJson(response.data!);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteGeofence(String id) async {
    try {
      await _client.delete('/geofences/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is NetworkException) return error;
    return NetworkException(message: error.toString());
  }
}
