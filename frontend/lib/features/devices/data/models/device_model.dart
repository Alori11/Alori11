class DeviceModel {
  final String id;
  final String imei;
  final String status; // online / offline
  final DateTime? lastSeen;
  final int signal;
  final int? battery;
  final String? vehicleId;

  const DeviceModel({
    required this.id,
    required this.imei,
    required this.status,
    this.lastSeen,
    required this.signal,
    this.battery,
    this.vehicleId,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      imei: json['imei'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'] as String)
          : null,
      signal: json['signal'] as int? ?? 0,
      battery: json['battery'] as int?,
      vehicleId: json['vehicleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imei': imei,
      'status': status,
      'lastSeen': lastSeen?.toIso8601String(),
      'signal': signal,
      'battery': battery,
      'vehicleId': vehicleId,
    };
  }

  bool get isOnline => status == 'online';

  String get signalBars {
    if (signal >= 80) return 'ممتاز';
    if (signal >= 60) return 'جيد';
    if (signal >= 40) return 'متوسط';
    if (signal >= 20) return 'ضعيف';
    return 'لا إشارة';
  }
}
