class MaintenanceModel {
  final String id;
  final String type;
  final DateTime date;
  final int mileage;
  final String? notes;
  final double? cost;
  final DateTime? nextDueDate;
  final String vehicleId;

  const MaintenanceModel({
    required this.id,
    required this.type,
    required this.date,
    required this.mileage,
    this.notes,
    this.cost,
    this.nextDueDate,
    required this.vehicleId,
  });

  factory MaintenanceModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      mileage: json['mileage'] as int? ?? 0,
      notes: json['notes'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.tryParse(json['nextDueDate'] as String)
          : null,
      vehicleId: json['vehicleId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'notes': notes,
      'cost': cost,
      'nextDueDate': nextDueDate?.toIso8601String(),
      'vehicleId': vehicleId,
    };
  }

  MaintenanceStatus get status {
    if (nextDueDate == null) return MaintenanceStatus.upToDate;
    final now = DateTime.now();
    final daysUntilDue = nextDueDate!.difference(now).inDays;
    if (daysUntilDue < 0) return MaintenanceStatus.overdue;
    if (daysUntilDue <= 30) return MaintenanceStatus.dueSoon;
    return MaintenanceStatus.upToDate;
  }
}

enum MaintenanceStatus { overdue, dueSoon, upToDate }
