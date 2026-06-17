import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import 'models/maintenance_model.dart';

class MaintenanceRepository {
  final ApiClient _client;

  MaintenanceRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  Future<List<MaintenanceModel>> listMaintenance(String vehicleId) async {
    try {
      final response =
          await _client.get<dynamic>('/maintenance?vehicleId=$vehicleId');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => MaintenanceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is Map && data['records'] is List) {
        return (data['records'] as List)
            .map((e) => MaintenanceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<MaintenanceModel> createMaintenance(Map<String, dynamic> data) async {
    try {
      final response =
          await _client.post<Map<String, dynamic>>('/maintenance', data: data);
      return MaintenanceModel.fromJson(response.data!);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteMaintenance(String id) async {
    try {
      await _client.delete('/maintenance/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is NetworkException) return error;
    return NetworkException(message: error.toString());
  }
}
