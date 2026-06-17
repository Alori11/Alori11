import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final double lat;
  final double lng;
  final double speed;
  final double heading;
  final bool ignition;
  final String timestamp;
  final String? address;

  const LocationModel({
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.ignition,
    required this.timestamp,
    this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      ignition: json['ignition'] as bool? ?? false,
      timestamp: json['timestamp'] as String? ?? '',
      address: json['address'] as String?,
    );
  }

  LatLng get latLng => LatLng(lat, lng);

  DateTime get dateTime =>
      DateTime.tryParse(timestamp) ?? DateTime.now();

  bool get isMoving => speed > 2.0;
}

class TripModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double distance;
  final int duration; // minutes
  final List<LatLng> points;
  final double maxSpeed;
  final String? startAddress;
  final String? endAddress;

  const TripModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distance,
    required this.duration,
    required this.points,
    required this.maxSpeed,
    this.startAddress,
    this.endAddress,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    List<LatLng> points = [];
    if (json['points'] is List) {
      points = (json['points'] as List).map((p) {
        if (p is Map) {
          return LatLng(
            (p['lat'] as num?)?.toDouble() ?? 0.0,
            (p['lng'] as num?)?.toDouble() ?? 0.0,
          );
        }
        return const LatLng(0, 0);
      }).toList();
    }

    return TripModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] as String? ?? '') ??
          DateTime.now(),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as int? ?? 0,
      points: points,
      maxSpeed: (json['maxSpeed'] as num?)?.toDouble() ?? 0.0,
      startAddress: json['startAddress'] as String?,
      endAddress: json['endAddress'] as String?,
    );
  }
}
