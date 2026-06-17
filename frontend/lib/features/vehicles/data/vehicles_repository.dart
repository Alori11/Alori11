import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import 'models/vehicle_model.dart';

class VehiclesRepository {
  final ApiClient _client;

  VehiclesRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  Future<List<VehicleModel>> listVehicles() async {
    try {
      final response = await _client.get<dynamic>('/vehicles');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is Map && data['vehicles'] is List) {
        return (data['vehicles'] as List)
            .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<VehicleModel> getVehicle(String vehicleId) async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/vehicles/$vehicleId');
      return VehicleModel.fromJson(response.data!);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<VehicleModel> createVehicle({
    required String make,
    required String model,
    required int year,
    required String plateNumber,
    required String color,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/vehicles',
        data: {
          'make': make,
          'model': model,
          'year': year,
          'plateNumber': plateNumber,
          'color': color,
        },
      );
      return VehicleModel.fromJson(response.data!);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<VehicleModel> updateVehicle(
    String vehicleId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client.put<Map<String, dynamic>>(
        '/vehicles/$vehicleId',
        data: data,
      );
      return VehicleModel.fromJson(response.data!);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _client.delete('/vehicles/$vehicleId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is NetworkException) return error;
    return NetworkException(message: error.toString());
  }
}
