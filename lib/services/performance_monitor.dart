// lib/services/performance_monitor.dart
import 'dart:async';
import 'dart:math';

import 'package:autoperf_monitor/database/database_helper.dart';
import 'package:autoperf_monitor/models/driving_session.dart';
import 'package:autoperf_monitor/models/gps_point.dart';
import 'package:autoperf_monitor/models/performance_metrics.dart';
import 'package:autoperf_monitor/services/settings_service.dart';
import 'package:autoperf_monitor/utils/douglas_peucker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PerformanceMonitor {
  final DatabaseHelper _databaseHelper;
  final SettingsService _settingsService;
  final DouglasPeucker _douglasPeucker = DouglasPeucker();
  final KalmanFilter _kalmanFilter = KalmanFilter();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  final StreamController<double> _speedController =
      StreamController<double>.broadcast();
  final StreamController<double> _altitudeController =
      StreamController<double>.broadcast();
  final StreamController<double> _distanceController =
      StreamController<double>.broadcast();
  final StreamController<GPSPoint> _currentGpsPointController =
      StreamController<GPSPoint>.broadcast();
  final StreamController<PerformanceMetrics> _metricsController =
      StreamController<PerformanceMetrics>.broadcast();
  final StreamController<double> _gpsAccuracyController =
      StreamController<double>.broadcast();

  Stream<double> get speedStream => _speedController.stream;
  Stream<double> get altitudeStream => _altitudeController.stream;
  Stream<double> get distanceStream => _distanceController.stream;
  Stream<GPSPoint> get currentGpsPointStream => _currentGpsPointController.stream;
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;
  Stream<double> get gpsAccuracyStream => _gpsAccuracyController.stream;

  DrivingSession? _currentDrivingSession;
  List<GPSPoint> _currentTrajectory = [];
  PerformanceMetrics _currentMetrics = PerformanceMetrics();
  Position? _lastPosition;
  double _totalDistance = 0.0;
  List<double> _speedReadings = [];

  Duration _currentSamplingInterval = const Duration(milliseconds: 500);

  PerformanceMonitor(
      {DatabaseHelper? databaseHelper, SettingsService? settingsService})
      : _databaseHelper = databaseHelper ?? DatabaseHelper(),
        _settingsService = settingsService ?? SettingsService();

  Future<void> startMonitoring() async {
    await _handleLocationPermission();

    _currentSamplingInterval = await _settingsService.getSamplingInterval();

    _currentDrivingSession = DrivingSession(
      startTime: DateTime.now(),
      trajectory: [],
      metrics: PerformanceMetrics(),
    );

    _currentTrajectory = [];
    _totalDistance = 0.0;
    _speedReadings = [];
    _lastPosition = null;
    _currentMetrics = PerformanceMetrics(
      minSpeed: double.infinity,
      maxSpeed: 0.0,
      averageSpeed: 0.0,
      distanceTraveled: 0.0,
      altitude: 0.0,
    );

    _startPositionStream();

    _accelerometerSubscription =
        accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen((event) {});
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _speedController.addError('Location services are disabled.');
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _speedController
            .addError('Location permissions are denied (or denied forever).');
        throw Exception('Location permissions are denied (or denied forever).');
      }
    }
  }

  void _startPositionStream() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        forceLocationManager: true,
        intervalDuration: _currentSamplingInterval,
      ),
    ).listen(_processPosition);
  }

  void _processPosition(Position position) {
    final speedKmH = position.speed * 3.6;
    final smoothedSpeedKmH = _kalmanFilter.filter(speedKmH);

    _updateMetrics(smoothedSpeedKmH, position);
    _updateTrajectory(smoothedSpeedKmH, position);

    _speedController.add(smoothedSpeedKmH);
    _altitudeController.add(position.altitude);
    _distanceController.add(_totalDistance);
    _gpsAccuracyController.add(position.accuracy);
    _metricsController.add(_currentMetrics);
  }

  void _updateMetrics(double smoothedSpeedKmH, Position position) {
    _speedReadings.add(smoothedSpeedKmH);
    if (_speedReadings.length > 120) {
      _speedReadings.removeAt(0);
    }

    final minSpeed = min(
        _currentMetrics.minSpeed, smoothedSpeedKmH);
    final maxSpeed = max(
        _currentMetrics.maxSpeed, smoothedSpeedKmH);
    final averageSpeed = _speedReadings.isNotEmpty
        ? _speedReadings.reduce((a, b) => a + b) / _speedReadings.length
        : 0.0;

    if (_lastPosition != null) {
      _totalDistance += Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          ) /
          1000;
    }
    _lastPosition = position;

    _currentMetrics = _currentMetrics.copyWith(
      minSpeed: minSpeed,
      maxSpeed: maxSpeed,
      averageSpeed: averageSpeed,
      distanceTraveled: _totalDistance,
      altitude: position.altitude,
    );
  }

  void _updateTrajectory(double smoothedSpeedKmH, Position position) {
    final gpsPoint = GPSPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      speed: smoothedSpeedKmH,
      accuracy: position.accuracy,
      timestamp: position.timestamp ?? DateTime.now().toUtc(),
    );
    _currentTrajectory.add(gpsPoint);
    _currentGpsPointController.add(gpsPoint);
  }

  Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    await _accelerometerSubscription?.cancel();

    if (_currentDrivingSession != null) {
      final compressedTrajectory =
          _douglasPeucker.simplify(_currentTrajectory, 0.0001);

      _currentDrivingSession = _currentDrivingSession!.copyWith(
        endTime: DateTime.now(),
        trajectory: compressedTrajectory,
        metrics: _currentMetrics,
      );

      await _databaseHelper.insertDrivingSession(_currentDrivingSession!);
    }

    _currentDrivingSession = null;
    _currentTrajectory = [];
    _currentMetrics = PerformanceMetrics();
    _lastPosition = null;
    _totalDistance = 0.0;
    _speedReadings = [];

    dispose();
  }

  void dispose() {
    _speedController.close();
    _altitudeController.close();
    _distanceController.close();
    _currentGpsPointController.close();
    _gpsAccuracyController.close();
    _metricsController.close();
    _positionSubscription?.cancel();
    _accelerometerSubscription?.cancel();
  }
}

class KalmanFilter {
  double _x = 0;
  double _p = 1;
  final double _q = 0.1;
  final double _r = 0.1;

  double filter(double measurement) {
    _p = _p + _q;
    final k = _p / (_p + _r);
    _x = _x + k * (measurement - _x);
    _p = (1 - k) * _p;
    return _x;
  }
}
