// lib/models/driving_session.dart
import 'package:cartrackerevo/models/fuel_record.dart';
import 'package:cartrackerevo/models/gps_point.dart';
import 'package:cartrackerevo/models/performance_metrics.dart';

class DrivingSession {
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<GPSPoint> trajectory;
  final PerformanceMetrics metrics;
  final FuelRecord? refueling;

  DrivingSession({
    this.id,
    required this.startTime,
    this.endTime,
    required this.trajectory,
    required this.metrics,
    this.refueling,
  });

  DrivingSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    List<GPSPoint>? trajectory,
    PerformanceMetrics? metrics,
    FuelRecord? refueling,
  }) {
    return DrivingSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      trajectory: trajectory ?? this.trajectory,
      metrics: metrics ?? this.metrics,
      refueling: refueling ?? this.refueling,
    );
  }
}
