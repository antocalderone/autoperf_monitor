// lib/models/maintenance_record.dart
import 'package:intl/intl.dart';

enum MaintenanceType {
  oilChange,
  tireRotation,
  brakeCheck,
  airFilterReplacement,
  sparkPlugReplacement,
  other,
}

class MaintenanceRecord {
  final int? id;
  final DateTime date;
  final double mileage; // Mileage at the time of maintenance
  final MaintenanceType type;
  final String description;
  final double cost; // Cost of maintenance

  MaintenanceRecord({
    this.id,
    required this.date,
    required this.mileage,
    required this.type,
    this.description = '',
    this.cost = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'mileage': mileage,
      'type': type.name,
      'description': description,
      'cost': cost,
    };
  }

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecord(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      mileage: map['mileage'],
      type: MaintenanceType.values.firstWhere((e) => e.name == map['type']),
      description: map['description'],
      cost: map['cost'],
    );
  }

  // Helper for display
  String get formattedDate => DateFormat('yyyy-MM-dd').format(date);
  String get formattedMileage => '${mileage.toStringAsFixed(0)} km';
  String get formattedCost => '€${cost.toStringAsFixed(2)}';
}

class MaintenanceReminder {
  final MaintenanceType type;
  final int intervalKm; // in km
  final int intervalMonths; // in months

  MaintenanceReminder({
    required this.type,
    this.intervalKm = 0,
    this.intervalMonths = 0,
  });
}
