// test/performance_monitor_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:autoperf_monitor/services/performance_monitor.dart';
import 'package:autoperf_monitor/models/gps_point.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'dart:async';

// Import generated mock
import 'mocks/mock_geolocator_platform.mocks.dart';
import 'package:autoperf_monitor/models/performance_metrics.dart'; // Explicitly import PerformanceMetrics
import 'package:autoperf_monitor/database/database_helper.dart'; // Import DatabaseHelper
import 'package:autoperf_monitor/models/driving_session.dart'; // Import DrivingSession

void main() {
  group('PerformanceMonitor', () {
    late PerformanceMonitor performanceMonitor;
    late MockGeolocatorPlatform mockGeolocatorPlatform;
    late MockDatabaseHelper mockDatabaseHelper;
    late StreamController<Position> positionStreamController;

    setUp(() {
      mockGeolocatorPlatform = MockGeoloculatorPlatform();
      mockDatabaseHelper = MockDatabaseHelper();

      // Stub GeolocatorPlatform instance
      GeolocatorPlatform.instance = mockGeoloculatorPlatform;

      positionStreamController = StreamController<Position>();
      when(mockGeoloculatorPlatform.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);
      when(mockGeoloculatorPlatform.requestPermission())
          .thenAnswer((_) async => LocationPermission.always);
      when(mockGeoloculatorPlatform.getPositionStream(
        locationSettings: anyNamed('locationSettings'),
      )).thenAnswer((_) => positionStreamController.stream);

      // Mock distanceBetween
      when(mockGeolocatorPlatform.distanceBetween(
        any, any, any, any,
      )).thenReturn(100.0); // Assume 100 meters distance for every step for simplicity

      // Mock DatabaseHelper methods
      when(mockDatabaseHelper.insertDrivingSession(any))
          .thenAnswer((_) async => DrivingSession(
                id: 1, // Dummy ID
                startTime: DateTime.now(),
                trajectory: [],
                metrics: PerformanceMetrics(),
              ));
      when(mockDatabaseHelper.insertFuelRecord(any))
          .thenAnswer((_) async => 1); // Return a dummy ID

      performanceMonitor = PerformanceMonitor(databaseHelper: mockDatabaseHelper);
    });

    tearDown(() {
      positionStreamController.close();
      performanceMonitor.dispose();
    });

    test('Initial metrics are set correctly', () {
      final initialMetrics = PerformanceMetrics();
      expect(initialMetrics.minSpeed, double.infinity);
      expect(initialMetrics.maxSpeed, 0.0);
    });

    test('Speed stream emits correct values', () async {
      await performanceMonitor.startMonitoring();

      final positions = [
        _createMockPosition(speed: 0.0 / 3.6, timestamp: DateTime.now()), // 0 km/h
        _createMockPosition(speed: 10.0 / 3.6, timestamp: DateTime.now().add(const Duration(milliseconds: 500))), // 10 km/h
        _createMockPosition(speed: 20.0 / 3.6, timestamp: DateTime.now().add(const Duration(milliseconds: 1000))), // 20 km/h
        _createMockPosition(speed: 30.0 / 3.6, timestamp: DateTime.now().add(const Duration(milliseconds: 1500))), // 30 km/h
      ];

      expectLater(
        performanceMonitor.speedStream,
        emitsInOrder([
          0.0,
          10.0,
          20.0,
          30.0,
        ]),
      );

      for (var pos in positions) {
        positionStreamController.add(pos);
        await Future.delayed(const Duration(milliseconds: 10)); // Allow stream to process
      }
      positionStreamController.close();

      await Future.delayed(const Duration(milliseconds: 100)); // Wait for stream to be done
    });

    test('Metrics stream emits updated values', () async {
      await performanceMonitor.startMonitoring();

      final startTime = DateTime.now();
      final positions = [
        _createMockPosition(speed: 0.0 / 3.6, altitude: 100, timestamp: startTime),
        _createMockPosition(speed: 10.0 / 3.6, altitude: 101, timestamp: startTime.add(const Duration(milliseconds: 500))),
        _createMockPosition(speed: 20.0 / 3.6, altitude: 102, timestamp: startTime.add(const Duration(milliseconds: 1000))),
      ];

      expectLater(
        performanceMonitor.metricsStream,
        emitsInOrder([
          // Initial metrics (after first position processed, distance is 0)
          isA<PerformanceMetrics>()
              .having((m) => (m as PerformanceMetrics).minSpeed, 'minSpeed', 0.0)
              .having((m) => (m as PerformanceMetrics).maxSpeed, 'maxSpeed', 0.0)
              .having((m) => (m as PerformanceMetrics).averageSpeed, 'averageSpeed', 0.0)
              .having((m) => (m as PerformanceMetrics).distanceTraveled, 'distanceTraveled', 0.0)
              .having((m) => (m as PerformanceMetrics).altitude, 'altitude', 100.0),
          isA<PerformanceMetrics>()
              .having((m) => (m as PerformanceMetrics).minSpeed, 'minSpeed', 0.0)
              .having((m) => (m as PerformanceMetrics).maxSpeed, 'maxSpeed', 10.0)
              .having((m) => (m as PerformanceMetrics).averageSpeed, 'averageSpeed', closeTo(5.0, 0.1)) // (0+10)/2
              .having((m) => (m as PerformanceMetrics).distanceTraveled, 'distanceTraveled', 0.1) // 100m = 0.1km
              .having((m) => (m as PerformanceMetrics).altitude, 'altitude', 101.0),
          isA<PerformanceMetrics>()
              .having((m) => (m as PerformanceMetrics).minSpeed, 'minSpeed', 0.0)
              .having((m) => (m as PerformanceMetrics).maxSpeed, 'maxSpeed', 20.0)
              .having((m) => (m as PerformanceMetrics).averageSpeed, 'averageSpeed', closeTo(10.0, 0.1)) // (0+10+20)/3
              .having((m) => (m as PerformanceMetrics).distanceTraveled, 'distanceTraveled', 0.2)
              .having((m) => (m as PerformanceMetrics).altitude, 'altitude', 102.0),
        ]),
      );

      for (var pos in positions) {
        positionStreamController.add(pos);
        await Future.delayed(const Duration(milliseconds: 10));
      }
      positionStreamController.close();

      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('GPS Accuracy stream emits values', () async {
      await performanceMonitor.startMonitoring();

      final positions = [
        _createMockPosition(accuracy: 10.0, timestamp: DateTime.now()),
        _createMockPosition(accuracy: 5.0, timestamp: DateTime.now().add(const Duration(milliseconds: 500))),
      ];

      expectLater(
        performanceMonitor.gpsAccuracyStream,
        emitsInOrder([
          10.0,
          5.0,
        ]),
      );

      for (var pos in positions) {
        positionStreamController.add(pos);
        await Future.delayed(const Duration(milliseconds: 10));
      }
      positionStreamController.close();

      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('stopMonitoring saves session to database and resets state', () async {
      await performanceMonitor.startMonitoring();
      positionStreamController.add(_createMockPosition(speed: 50 / 3.6, altitude: 100));
      await Future.delayed(const Duration(milliseconds: 10));
      positionStreamController.add(_createMockPosition(speed: 60 / 3.6, altitude: 105));
      await Future.delayed(const Duration(milliseconds: 10));

      await performanceMonitor.stopMonitoring();

      verify(mockDatabaseHelper.insertDrivingSession(any)).called(1);
    });
  });
}

Position _createMockPosition({
  double latitude = 0.0,
  double longitude = 0.0,
  double altitude = 0.0,
  double speed = 0.0, // m/s
  double accuracy = 0.0,
  DateTime? timestamp,
  double altitudeAccuracy = 0.0,
  double heading = 0.0,
  double speedAccuracy = 0.0,
  int? floor,
  bool isMocked = false,
  double headingAccuracy = 0.0,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime.now(),
    accuracy: accuracy,
    altitude: altitude,
    heading: heading,
    speed: speed,
    speedAccuracy: speedAccuracy,
    altitudeAccuracy: altitudeAccuracy,
    headingAccuracy: headingAccuracy,
  );
}