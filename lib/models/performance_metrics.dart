// lib/models/performance_metrics.dart
class PerformanceMetrics {
  double minSpeed; // km/h
  double maxSpeed; // km/h
  double averageSpeed; // km/h
  double distanceTraveled; // km
  double altitude; // meters

  PerformanceMetrics({
    this.minSpeed = double.infinity,
    this.maxSpeed = 0.0,
    this.averageSpeed = 0.0,
    this.distanceTraveled = 0.0,
    this.altitude = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'minSpeed': minSpeed,
      'maxSpeed': maxSpeed,
      'averageSpeed': averageSpeed,
      'distanceTraveled': distanceTraveled,
      'altitude': altitude,
    };
  }

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
