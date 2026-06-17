import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofenceModel {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radius;
  final bool isActive;
  final String vehicleId;
  final String? color;

  const GeofenceModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radius,
    required this.isActive,
    required this.vehicleId,
    this.color,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      radius: (json['radius'] as num?)?.toDouble() ?? 500.0,
      isActive: json['isActive'] as bool? ?? true,
      vehicleId: json['vehicleId'] as String? ?? '',
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'radius': radius,
      'isActive': isActive,
      'vehicleId': vehicleId,
      'color': color,
    };
  }

  LatLng get center => LatLng(lat, lng);
}
