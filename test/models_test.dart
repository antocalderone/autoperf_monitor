// test/models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:autoperf_monitor/models/driving_session.dart';
import 'package:autoperf_monitor/models/fuel_record.dart';
import 'package:autoperf_monitor/models/gps_point.dart';
import 'package:autoperf_monitor/models/performance_metrics.dart';

void main() {
  group('GPSPoint', () {
    test('GPSPoint can be instantiated', () {
      final now = DateTime.now();
      final gpsPoint = GPSPoint(
        latitude: 10.0,
        longitude: 20.0,
        altitude: 100.0,
        speed: 50.0,
        accuracy: 5.0,
        timestamp: now,
      );

      expect(gpsPoint.latitude, 10.0);
      expect(gpsPoint.longitude, 20.0);
      expect(gpsPoint.altitude, 100.0);
      expect(gpsPoint.speed, 50.0);
      expect(gpsPoint.accuracy, 5.0);
      expect(gpsPoint.timestamp, now);
    });

    test('GPSPoint toMap converts correctly', () {
      final now = DateTime.now();
      final gpsPoint = GPSPoint(
        latitude: 10.0,
        longitude: 20.0,
        altitude: 100.0,
        speed: 50.0,
        accuracy: 5.0,
        timestamp: now,
      );

      final map = gpsPoint.toMap();
      expect(map['latitude'], 10.0);
      expect(map['longitude'], 20.0);
      expect(map['altitude'], 100.0);
      expect(map['speed'], 50.0);
      expect(map['accuracy'], 5.0);
      expect(map['timestamp'], now.millisecondsSinceEpoch);
    });
  });

  group('PerformanceMetrics', () {
    test('PerformanceMetrics can be instantiated with default values', () {
      final metrics = PerformanceMetrics();
      expect(metrics.minSpeed, double.infinity);
      expect(metrics.maxSpeed, 0.0);
      expect(metrics.averageSpeed, 0.0);
      expect(metrics.distanceTraveled, 0.0);
      expect(metrics.altitude, 0.0);
    });

    test('PerformanceMetrics can be instantiated with custom values', () {
      final metrics = PerformanceMetrics(
        minSpeed: 10.0,
        maxSpeed: 100.0,
        averageSpeed: 50.0,
        distanceTraveled: 1000.0,
        altitude: 200.0,
      );
      expect(metrics.minSpeed, 10.0);
      expect(metrics.maxSpeed, 100.0);
      expect(metrics.averageSpeed, 50.0);
      expect(metrics.distanceTraveled, 1000.0);
      expect(metrics.altitude, 200.0);
    });

    test('PerformanceMetrics copyWith creates a new instance with updated values', () {
      final original = PerformanceMetrics(minSpeed: 10, maxSpeed: 50);
      final updated = original.copyWith(maxSpeed: 60, altitude: 300);

      expect(updated.minSpeed, 10); // Unchanged
      expect(updated.maxSpeed, 60); // Changed
      expect(updated.altitude, 300); // Changed
      expect(original == updated, false); // Should be a new instance
    });

    test('PerformanceMetrics toMap converts correctly', () {
      final metrics = PerformanceMetrics(
        minSpeed: 10.0,
        maxSpeed: 100.0,
        averageSpeed: 50.0,
        distanceTraveled: 1000.0,
        altitude: 200.0,
      );

      final map = metrics.toMap();
      expect(map['minSpeed'], 10.0);
      expect(map['maxSpeed'], 100.0);
      expect(map['averageSpeed'], 50.0);
      expect(map['distanceTraveled'], 1000.0);
      expect(map['altitude'], 200.0);
    });
  });

  group('FuelRecord', () {
    test('FuelRecord can be instantiated', () {
      final now = DateTime.now();
      final fuelRecord = FuelRecord(
        id: 1,
        date: now,
        amount: 50.0,
        liters: 40.0,
        mileage: 10000.0,
        fuelType: FuelType.petrol,
      );

      expect(fuelRecord.id, 1);
      expect(fuelRecord.date, now);
      expect(fuelRecord.amount, 50.0);
      expect(fuelRecord.liters, 40.0);
      expect(fuelRecord.mileage, 10000.0);
      expect(fuelRecord.fuelType, FuelType.petrol);
    });

    test('FuelRecord toMap converts correctly', () {
      final now = DateTime.now();
      final fuelRecord = FuelRecord(
        id: 1,
        date: now,
        amount: 50.0,
        liters: 40.0,
        mileage: 10000.0,
        fuelType: FuelType.petrol,
      );

      final map = fuelRecord.toMap();
      expect(map['id'], 1);
      expect(map['date'], now.millisecondsSinceEpoch);
      expect(map['amount'], 50.0);
      expect(map['liters'], 40.0);
      expect(map['mileage'], 10000.0);
      expect(map['fuelType'], 'petrol');
    });
  });

  group('DrivingSession', () {
    test('DrivingSession can be instantiated', () {
      final startTime = DateTime.now();
      final endTime = startTime.add(const Duration(hours: 1));
      final metrics = PerformanceMetrics();
      final gpsPoint = GPSPoint(
          latitude: 10,
          longitude: 20,
          altitude: 100,
          speed: 60,
          accuracy: 5,
          timestamp: startTime);
      final fuelRecord = FuelRecord(
          id: 1,
          date: startTime,
          amount: 50,
          liters: 40,
          mileage: 10000,
          fuelType: FuelType.petrol);

      final session = DrivingSession(
        id: 1,
        startTime: startTime,
        endTime: endTime,
        trajectory: [gpsPoint],
        metrics: metrics,
        refueling: fuelRecord,
      );

      expect(session.id, 1);
      expect(session.startTime, startTime);
      expect(session.endTime, endTime);
      expect(session.trajectory.length, 1);
      expect(session.metrics, metrics);
      expect(session.refueling, fuelRecord);
    });

    test('DrivingSession copyWith creates a new instance with updated values', () {
      final startTime = DateTime.now();
      final original = DrivingSession(
        startTime: startTime,
        trajectory: [],
        metrics: PerformanceMetrics(),
      );
      final updatedEndTime = startTime.add(const Duration(hours: 2));
      final updated = original.copyWith(endTime: updatedEndTime);

      expect(updated.endTime, updatedEndTime);
      expect(original.startTime, updated.startTime); // Unchanged
    });
  });
}
