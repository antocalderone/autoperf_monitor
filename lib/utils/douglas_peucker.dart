// lib/utils/douglas_peucker.dart
import 'dart:math';
import 'package:cartrackerevo/models/gps_point.dart';

class DouglasPeucker {
  List<GPSPoint> simplify(List<GPSPoint> points, double epsilon) {
    if (points.length < 3) {
      return points;
    }

    int firstIndex = 0;
    int lastIndex = points.length - 1;
    List<int> indexList = [firstIndex, lastIndex];

    while (points[firstIndex] == points[lastIndex]) {
      lastIndex--;
    }

    _douglasPeucker(points, firstIndex, lastIndex, epsilon, indexList);

    List<GPSPoint> simplifiedPoints = [];
    indexList.sort();
    for (int index in indexList) {
      simplifiedPoints.add(points[index]);
    }

    return simplifiedPoints;
  }

  void _douglasPeucker(List<GPSPoint> points, int firstIndex, int lastIndex,
      double epsilon, List<int> indexList) {
    double maxDistance = 0;
    int index = 0;

    for (int i = firstIndex + 1; i < lastIndex; i++) {
      double distance = _perpendicularDistance(
          points[i], points[firstIndex], points[lastIndex]);
      if (distance > maxDistance) {
        maxDistance = distance;
        index = i;
      }
    }

    if (maxDistance > epsilon) {
      if (!indexList.contains(index)) {
        indexList.add(index);
      }
      _douglasPeucker(points, firstIndex, index, epsilon, indexList);
      _douglasPeucker(points, index, lastIndex, epsilon, indexList);
    }
  }

  double _perpendicularDistance(
      GPSPoint point, GPSPoint lineStart, GPSPoint lineEnd) {
    double dx = lineEnd.latitude - lineStart.latitude;
    double dy = lineEnd.longitude - lineStart.longitude;

    if (dx == 0 && dy == 0) {
      return _distance(point, lineStart);
    }

    double t = ((point.latitude - lineStart.latitude) * dx +
            (point.longitude - lineStart.longitude) * dy) /
        (dx * dx + dy * dy);

    GPSPoint projection;
    if (t < 0) {
      projection = lineStart;
    } else if (t > 1) {
      projection = lineEnd;
    } else {
      projection = GPSPoint(
        latitude: lineStart.latitude + t * dx,
        longitude: lineStart.longitude + t * dy,
        altitude: 0, // Altitude is not used in this 2D distance calculation
        speed: 0,
        accuracy: 0,
        timestamp: DateTime.now(),
      );
    }

    return _distance(point, projection);
  }

  double _distance(GPSPoint p1, GPSPoint p2) {
    double dx = p1.latitude - p2.latitude;
    double dy = p1.longitude - p2.longitude;
    return sqrt(dx * dx + dy * dy);
  }
}
