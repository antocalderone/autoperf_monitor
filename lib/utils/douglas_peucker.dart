// lib/utils/douglas_peucker.dart
import 'dart:math';
import 'package:autoperf_monitor/models/gps_point.dart';

class DouglasPeucker {
  /// Simplifies a list of [GPSPoint] using the Douglas-Peucker algorithm.
  ///
  /// The [epsilon] parameter determines the tolerance of the simplification.
  /// A higher value of [epsilon] will result in a more simplified trajectory.
  List<GPSPoint> simplify(List<GPSPoint> points, double epsilon) {
    if (points.length < 3) {
      return List.from(points);
    }

    double maxDistance = 0;
    int index = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double distance =
          _getPerpendicularDistance(points[i], points.first, points.last);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    if (maxDistance > epsilon) {
      List<GPSPoint> firstHalf =
          simplify(points.sublist(0, index + 1), epsilon);
      List<GPSPoint> secondHalf = simplify(points.sublist(index), epsilon);
      return [...firstHalf.sublist(0, firstHalf.length - 1), ...secondHalf];
    } else {
      return [points.first, points.last];
    }
  }

  /// Calculates the perpendicular distance from a [point] to a line segment
  /// defined by [lineStart] and [lineEnd].
  double _getPerpendicularDistance(
      GPSPoint point, GPSPoint lineStart, GPSPoint lineEnd) {
    double dx = lineEnd.longitude - lineStart.longitude;
    double dy = lineEnd.latitude - lineStart.latitude;

    double lengthSq = dx * dx + dy * dy;
    if (lengthSq == 0) {
      return _distance(point, lineStart);
    }

    double t = ((point.longitude - lineStart.longitude) * dx +
            (point.latitude - lineStart.latitude) * dy) /
        lengthSq;
    t = max(0, min(1, t));

    double closestX = lineStart.longitude + t * dx;
    double closestY = lineStart.latitude + t * dy;

    return _distanceBetweenCoordinates(
        point.latitude, point.longitude, closestY, closestX);
  }

  /// Calculates the distance between two [GPSPoint]s.
  double _distance(GPSPoint p1, GPSPoint p2) {
    return _distanceBetweenCoordinates(
        p1.latitude, p1.longitude, p2.latitude, p2.longitude);
  }

  /// Calculates the distance between two coordinates.
  double _distanceBetweenCoordinates(
      double lat1, double lon1, double lat2, double lon2) {
    return sqrt(pow(lon1 - lon2, 2) + pow(lat1 - lat2, 2));
  }
}
