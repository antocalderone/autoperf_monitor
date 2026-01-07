// lib/utils/douglas_peucker.dart
import 'dart:math';
import 'package:autoperf_monitor/models/gps_point.dart';

/// Calculates the perpendicular distance from a point to a line segment.
double _perpendicularDistance(GPSPoint point, GPSPoint lineStart, GPSPoint lineEnd) {
  // Convert GPSPoint to a simple 2D point for distance calculation
  // Using longitude as X and latitude as Y for simplicity,
  // this is a planar approximation suitable for small distances.
  // For large-scale maps, more complex geodesic calculations would be needed.
  double x0 = point.longitude;
  double y0 = point.latitude;
  double x1 = lineStart.longitude;
  double y1 = lineStart.latitude;
  double x2 = lineEnd.longitude;
  double y2 = lineEnd.latitude;

  double dx = x2 - x1;
  double dy = y2 - y1;

  double lengthSq = dx * dx + dy * dy;
  if (lengthSq == 0) {
    return _distance(point, lineStart); // Start and end points are the same
  }

  double t = ((x0 - x1) * dx + (y0 - y1) * dy) / lengthSq;
  t = max(0, min(1, t)); // Clamp t to [0, 1]

  double closestX = x1 + t * dx;
  double closestY = y1 + t * dy;

  return sqrt(pow(x0 - closestX, 2) + pow(y0 - closestY, 2));
}

/// Calculates the distance between two GPS points (simplified 2D Euclidean distance).
double _distance(GPSPoint p1, GPSPoint p2) {
  return sqrt(pow(p1.longitude - p2.longitude, 2) + pow(p1.latitude - p2.latitude, 2));
}

/// Applies the Douglas-Peucker algorithm to simplify a polyline (list of GPSPoint).
List<GPSPoint> douglasPeucker(List<GPSPoint> points, double epsilon) {
  if (points.length < 3) {
    return List.from(points); // Cannot simplify a line with less than 3 points
  }

  double maxDistance = 0;
  int index = 0;

  // Find the point with the maximum distance from the line segment (first-last)
  for (int i = 1; i < points.length - 1; i++) {
    double distance = _perpendicularDistance(points[i], points.first, points.last);
    if (distance > maxDistance) {
      maxDistance = distance;
      index = i;
    }
  }

  // If max distance is greater than epsilon, recursively simplify
  if (maxDistance > epsilon) {
    List<GPSPoint> recResults1 = douglasPeucker(points.sublist(0, index + 1), epsilon);
    List<GPSPoint> recResults2 = douglasPeucker(points.sublist(index, points.length), epsilon);

    // Build the result list, avoiding duplicate point at the intersection
    return [...recResults1.sublist(0, recResults1.length - 1), ...recResults2];
  } else {
    return [points.first, points.last]; // All points are within epsilon, return just the endpoints
  }
}
