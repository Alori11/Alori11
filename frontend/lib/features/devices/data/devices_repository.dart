import '../../../core/network/api_client.dart';
import '../../../core/network/network_exceptions.dart';
import 'models/device_model.dart';

class DevicesRepository {
  final ApiClient _client;

  DevicesRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  Future<DeviceModel> pairDevice({
    required String imei,
    required String vehicleId,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/devices/pair',
        data: {'imei': imei, 'vehicleId': vehicleId},
      );
      return DeviceModel.fromJson(response.data!);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> unpairDevice(String deviceId) async {
    try {
      await _client.delete('/devices/$deviceId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<DeviceModel>> listDevices() async {
    try {
      final response = await _client.get<dynamic>('/devices');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (data is Map && data['devices'] is List) {
        return (data['devices'] as List)
            .map((e) => DeviceModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<DeviceModel> getDeviceStatus(String deviceId) async {
    try {
      final response = await _client
          .get<Map<String, dynamic>>('/devices/$deviceId/status');
      return DeviceModel.fromJson(response.data!);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is NetworkException) return error;
    return NetworkException(message: error.toString());
  }
}
