// lib/models/gps_point.dart
class GPSPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed; // km/h
  final double accuracy; // meters
  final DateTime timestamp;

  GPSPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.accuracy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
