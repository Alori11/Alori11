import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AlertModel {
  final String id;
  final String type;
  final String message;
  final bool read;
  final DateTime createdAt;
  final String vehicleId;
  final String? vehicleName;

  const AlertModel({
    required this.id,
    required this.type,
    required this.message,
    required this.read,
    required this.createdAt,
    required this.vehicleId,
    this.vehicleName,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      vehicleId: json['vehicleId'] as String? ?? '',
      vehicleName: json['vehicleName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
        'vehicleId': vehicleId,
        'vehicleName': vehicleName,
      };

  AlertModel copyWith({bool? read}) {
    return AlertModel(
      id: id,
      type: type,
      message: message,
      read: read ?? this.read,
      createdAt: createdAt,
      vehicleId: vehicleId,
      vehicleName: vehicleName,
    );
  }

  IconData get icon {
    switch (type) {
      case 'speed_alert':
        return Icons.speed_rounded;
      case 'geofence_exit':
        return Icons.location_off_rounded;
      case 'geofence_enter':
        return Icons.location_on_rounded;
      case 'engine_on':
        return Icons.power_settings_new_rounded;
      case 'engine_off':
        return Icons.power_off_rounded;
      case 'low_battery':
        return Icons.battery_alert_rounded;
      case 'device_disconnected':
        return Icons.signal_wifi_off_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get color {
    switch (type) {
      case 'speed_alert':
        return AppColors.error;
      case 'geofence_exit':
        return AppColors.warning;
      case 'geofence_enter':
        return AppColors.success;
      case 'engine_on':
        return AppColors.info;
      case 'engine_off':
        return AppColors.textSecondary;
      case 'low_battery':
        return AppColors.warning;
      case 'device_disconnected':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'speed_alert':
        return 'تنبيه السرعة';
      case 'geofence_exit':
        return 'مغادرة المنطقة';
      case 'geofence_enter':
        return 'دخول المنطقة';
      case 'engine_on':
        return 'تشغيل المحرك';
      case 'engine_off':
        return 'إيقاف المحرك';
      case 'low_battery':
        return 'بطارية منخفضة';
      case 'device_disconnected':
        return 'انقطاع الاتصال';
      default:
        return 'تنبيه';
    }
  }
}
