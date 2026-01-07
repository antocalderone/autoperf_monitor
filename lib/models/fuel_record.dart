// lib/models/fuel_record.dart
enum FuelType { benzina, diesel, gpl, metano }

class FuelRecord {
  final int? id;
  final DateTime date;
  final double amount;
  final double liters;
  final double mileage;
  final FuelType fuelType;

  FuelRecord({
    this.id,
    required this.date,
    required this.amount,
    required this.liters,
    required this.mileage,
    required this.fuelType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'amount': amount,
      'liters': liters,
      'mileage': mileage,
      'fuelType': fuelType.name,
    };
  }

  factory FuelRecord.fromMap(Map<String, dynamic> map) {
    return FuelRecord(
      id: map['id'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      amount: map['amount'],
      liters: map['liters'],
      mileage: map['mileage'],
      fuelType: FuelType.values.firstWhere((e) => e.name == map['fuelType']),
    );
  }
}
