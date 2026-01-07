// lib/widgets/analog_speedometer.dart
import 'dart:math';
import 'package:flutter/material.dart';

class AnalogSpeedometer extends StatefulWidget {
  final double speed; // Current speed in km/h
  final double maxSpeed; // Max speed for the gauge

  const AnalogSpeedometer({
    super.key,
    required this.speed,
    this.maxSpeed = 180,
  });

  @override
  State<AnalogSpeedometer> createState() => _AnalogSpeedometerState();
}

class _AnalogSpeedometerState extends State<AnalogSpeedometer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: widget.speed).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnalogSpeedometer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.speed != oldWidget.speed) {
      _animation = Tween<double>(
        begin: oldWidget.speed,
        end: widget.speed,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _SpeedometerPainter(
            speed: _animation.value,
            maxSpeed: widget.maxSpeed,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final double maxSpeed;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(centerX, centerY);

    // Background
    final backgroundPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(centerX, centerY), radius, backgroundPaint);

    // Outer rings
    final outerRingPaint = Paint()
      ..color = const Color(0xFFF82D2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(centerX, centerY), radius - 2, outerRingPaint);

    final innerRingPaint = Paint()
      ..color = const Color(0xFF00CFF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(centerX, centerY), radius - 6, innerRingPaint);

    // Draw tick marks and labels
    for (int i = 0; i <= maxSpeed; i += 10) {
      final angle = -210 + (i / maxSpeed * 240);
      final isMajorTick = i % 20 == 0;
      final tickLength = isMajorTick ? 20.0 : 10.0;
      final tickPaint = Paint()
        ..color = isMajorTick ? Colors.yellow : Colors.white
        ..strokeWidth = isMajorTick ? 4 : 2;

      final tickStart = Offset(
        centerX + (radius - 20) * cos(angle * pi / 180),
        centerY + (radius - 20) * sin(angle * pi / 180),
      );
      final tickEnd = Offset(
        centerX + (radius - 20 - tickLength) * cos(angle * pi / 180),
        centerY + (radius - 20 - tickLength) * sin(angle * pi / 180),
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);

      if (isMajorTick) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$i',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        final textOffset = Offset(
          centerX + (radius - 50) * cos(angle * pi / 180) - textPainter.width / 2,
          centerY + (radius - 50) * sin(angle * pi / 180) - textPainter.height / 2,
        );
        textPainter.paint(canvas, textOffset);
      }
    }

    // Inner arc
    final innerArcPaint = Paint()
      ..color = const Color(0xFF00CFF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 0.6),
      -210 * pi / 180,
      120 * pi / 180,
      false,
      innerArcPaint,
    );

    final redArcPaint = Paint()
      ..color = const Color(0xFFF82D2D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius * 0.6),
      -90 * pi / 180,
      120 * pi / 180,
      false,
      redArcPaint,
    );

    // "km/h" text
    final kmhPainter = TextPainter(
      text: const TextSpan(
        text: 'km/h',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    kmhPainter.layout();
    kmhPainter.paint(canvas, Offset(centerX - kmhPainter.width / 2, centerY - 30));

    // Needle
    final needleAngle = -210 + (speed / maxSpeed * 240);
    final needlePaint = Paint()
      ..color = const Color(0xFFF82D2D)
      ..style = PaintingStyle.fill;

    final needlePath = Path()
      ..moveTo(centerX - 5 * cos((needleAngle + 90) * pi / 180), centerY - 5 * sin((needleAngle + 90) * pi / 180))
      ..lineTo(centerX + (radius * 0.5) * cos(needleAngle * pi / 180), centerY + (radius * 0.5) * sin(needleAngle * pi / 180))
      ..lineTo(centerX + 5 * cos((needleAngle - 90) * pi / 180), centerY + 5 * sin((needleAngle - 90) * pi / 180))
      ..close();
    canvas.drawPath(needlePath, needlePaint);

    // Center hub
    final hubPaint = Paint()..color = const Color(0xFF00CFF8);
    canvas.drawCircle(Offset(centerX, centerY), 12, hubPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed;
  }
}
