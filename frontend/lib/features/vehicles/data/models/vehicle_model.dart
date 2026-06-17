import '../../../devices/data/models/device_model.dart';

class VehicleModel {
  final String id;
  final String make;
  final String model;
  final int year;
  final String plateNumber;
  final String color;
  final String? deviceId;
  final DeviceModel? device;
  final String? imageUrl;

  const VehicleModel({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.color,
    this.deviceId,
    this.device,
    this.imageUrl,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      make: json['make'] as String? ?? '',
      model: json['model'] as String? ?? '',
      year: json['year'] as int? ?? DateTime.now().year,
      plateNumber: json['plateNumber'] as String? ?? '',
      color: json['color'] as String? ?? '',
      deviceId: json['deviceId'] as String?,
      device: json['device'] != null
          ? DeviceModel.fromJson(json['device'] as Map<String, dynamic>)
          : null,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'color': color,
      'deviceId': deviceId,
    };
  }

  String get displayName => '$make $model';
  bool get hasDevice => deviceId != null;
  bool get isOnline => device?.status == 'online';
}
