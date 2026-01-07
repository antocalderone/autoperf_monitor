// lib/services/performance_monitor.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:autoperf_monitor/models/gps_point.dart';
import 'package:autoperf_monitor/models/performance_metrics.dart';
import 'package:autoperf_monitor/database/database_helper.dart';
import 'package:autoperf_monitor/models/driving_session.dart';
import 'package:autoperf_monitor/utils/douglas_peucker.dart'; // Import the Douglas-Peucker utility

class PerformanceMonitor {
  final DatabaseHelper _databaseHelper;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Real-time data streams
  late final StreamController<double> _speedController;
  late final StreamController<double> _altitudeController;
  late final StreamController<double> _distanceController;
  late final StreamController<GPSPoint> _currentGpsPointController;
  late final StreamController<PerformanceMetrics> _metricsController;
  late final StreamController<double> _gpsAccuracyController;

  Stream<double> get speedStream => _speedController.stream;
  Stream<double> get altitudeStream => _altitudeController.stream;
  Stream<double> get distanceStream => _distanceController.stream;
  Stream<GPSPoint> get currentGpsPointStream => _currentGpsPointController.stream;
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;
  Stream<double> get gpsAccuracyStream => _gpsAccuracyController.stream;

  // Session-related data
  DrivingSession? _currentDrivingSession;
  List<GPSPoint> _currentTrajectory = [];
  PerformanceMetrics _currentMetrics = PerformanceMetrics();
  Position? _lastPosition;
  double _totalDistance = 0.0;
  double _minSpeed = double.infinity;
  double _maxSpeed = 0.0;
  List<double> _speedReadings = []; // For average speed calculation

  // GPS Accuracy
  

  // Adaptive sampling
  Duration _currentSamplingInterval = const Duration(milliseconds: 500); // Default

  // Kalman Filter for speed smoothing (placeholder)
  // TODO: Implement Kalman Filter

  PerformanceMonitor({DatabaseHelper? databaseHelper}) : _databaseHelper = databaseHelper ?? DatabaseHelper() {
    _initialize();
  }

  void _initialize() {
    _speedController = StreamController<double>.broadcast();
    _altitudeController = StreamController<double>.broadcast();
    _distanceController = StreamController<double>.broadcast();
    _currentGpsPointController = StreamController<GPSPoint>.broadcast();
    _metricsController = StreamController<PerformanceMetrics>.broadcast();
    _gpsAccuracyController = StreamController<double>.broadcast();

    _currentMetrics = PerformanceMetrics(
      minSpeed: double.infinity,
      maxSpeed: 0.0,
      averageSpeed: 0.0,
      distanceTraveled: 0.0,
      altitude: 0.0,
    );
  }

  Future<void> startMonitoring() async {
    // Start a new driving session
    _currentDrivingSession = DrivingSession(
      startTime: DateTime.now(),
      trajectory: [],
      metrics: PerformanceMetrics(),
    );
    _currentTrajectory = [];
    _totalDistance = 0.0;
    _minSpeed = double.infinity;
    _maxSpeed = 0.0;
    _speedReadings = [];
    _lastPosition = null; // Reset last position

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, don't start monitoring
      _speedController.addError('Location services are disabled.'); // Notify UI
      return Future.error('Location services are disabled.');
    }

    // Request location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Permissions not granted, don't start monitoring
        _speedController.addError('Location permissions are denied (or denied forever).'); // Notify UI
        return Future.error('Location permissions are denied (or denied forever).');
      }
    }

    // Configure location updates (every 500ms as requested)
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        forceLocationManager: true,
      ),
    ).listen((Position position) {
      _processPosition(position);
    });

    // Start accelerometer monitoring (optional, if needed for more advanced calculations)
    _accelerometerSubscription = accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen(
      (AccelerometerEvent event) {
        // TODO: Process accelerometer data if needed (e.g., for more precise motion detection)
      },
    );
  }

  void _processPosition(Position position) {
    // Convert speed from m/s to km/h
    final speedKmH = (position.speed ?? 0.0) * 3.6;

    // Adaptive sampling logic
    if (speedKmH < 30 && _currentSamplingInterval != const Duration(seconds: 1)) { // Urban speed threshold
      _currentSamplingInterval = const Duration(seconds: 1);
      _restartPositionStream();
    } else if (speedKmH >= 30 && _currentSamplingInterval != const Duration(milliseconds: 500)) { // Highway speed threshold
      _currentSamplingInterval = const Duration(milliseconds: 500);
      _restartPositionStream();
    }

    // Apply Kalman filter for speed smoothing (placeholder)
    final smoothedSpeedKmH = speedKmH; // TODO: Integrate Kalman Filter

    // Update metrics
    if (smoothedSpeedKmH < _minSpeed) {
      _minSpeed = smoothedSpeedKmH;
    }
    if (smoothedSpeedKmH > _maxSpeed) {
      _maxSpeed = smoothedSpeedKmH;
    }
    _speedReadings.add(smoothedSpeedKmH);
    if (_speedReadings.length > 120) { // Keep last 60 seconds of readings for average (500ms interval * 120 = 60s)
      _speedReadings.removeAt(0);
    }
    _currentMetrics = _currentMetrics.copyWith(
      minSpeed: _minSpeed == double.infinity ? 0.0 : _minSpeed,
      maxSpeed: _maxSpeed,
      averageSpeed: _speedReadings.isNotEmpty ? _speedReadings.reduce((a, b) => a + b) / _speedReadings.length : 0.0,
      distanceTraveled: _totalDistance,
      altitude: position.altitude,
    );

    // Calculate distance traveled
    if (_lastPosition != null) {
      _totalDistance += Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      ) / 1000; // Convert to km
    }
    _lastPosition = position;

    // Create GPSPoint and add to trajectory
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

    // Emit data through streams
    _speedController.add(smoothedSpeedKmH);
    _altitudeController.add(position.altitude);
    _distanceController.add(_totalDistance);
    _gpsAccuracyController.add(position.accuracy);
    _metricsController.add(_currentMetrics);
  }

  void _restartPositionStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        forceLocationManager: true,
      ),
    ).listen((Position position) {
      _processPosition(position);
    });
  }

  Future<void> stopMonitoring() async {
    await _positionSubscription?.cancel();
    await _accelerometerSubscription?.cancel();

    // Apply Douglas-Peucker algorithm to compress trajectory
    final compressedTrajectory = douglasPeucker(_currentTrajectory, 0.0001); // Epsilon value might need tuning

    _currentDrivingSession = _currentDrivingSession?.copyWith(
      endTime: DateTime.now(),
      trajectory: compressedTrajectory,
      metrics: _currentMetrics.copyWith(
        minSpeed: _minSpeed == double.infinity ? 0.0 : _minSpeed,
        maxSpeed: _maxSpeed,
        averageSpeed: _currentMetrics.averageSpeed,
        distanceTraveled: _totalDistance,
        altitude: _currentMetrics.altitude,
      ),
    );

    if (_currentDrivingSession != null) {
      // Save the session to the database
      // The insertDrivingSession method will also handle GPS points
      await _databaseHelper.insertDrivingSession(_currentDrivingSession!);
    }
    
    _currentDrivingSession = null;
    _currentTrajectory = [];
    _currentMetrics = PerformanceMetrics();
    _lastPosition = null;
    _totalDistance = 0.0;
    _minSpeed = double.infinity;
    _maxSpeed = 0.0;
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

// Add copyWith to PerformanceMetrics
extension PerformanceMetricsCopyWith on PerformanceMetrics {
  PerformanceMetrics copyWith({
    double? minSpeed,
    double? maxSpeed,
    double? averageSpeed,
    double? distanceTraveled,
    double? altitude,
  }) {
    return PerformanceMetrics(
      minSpeed: minSpeed ?? this.minSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      distanceTraveled: distanceTraveled ?? this.distanceTraveled,
      altitude: altitude ?? this.altitude,
    );
  }
}