// lib/widgets/analog_speedometer.dart
import 'dart:math';
import 'package:flutter/material.dart';

class AnalogSpeedometer extends StatefulWidget {
  final double speed; // Current speed in km/h
  final double maxSpeed; // Max speed for the gauge
  final Color primaryColor;
  final Color accentColor;
  final Color warningColor;

  const AnalogSpeedometer({
    super.key,
    required this.speed,
    this.maxSpeed = 240,
    this.primaryColor = Colors.red,
    this.accentColor = Colors.green,
    this.warningColor = Colors.orange,
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
    _animation = Tween<double>(begin: 0, end: widget.speed).animate(_controller);
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
            primaryColor: widget.primaryColor,
            accentColor: widget.accentColor,
            warningColor: widget.warningColor,
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
  final Color primaryColor;
  final Color accentColor;
  final Color warningColor;

  _SpeedometerPainter({
    required this.speed,
    required this.maxSpeed,
    required this.primaryColor,
    required this.accentColor,
    required this.warningColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = min(centerX, centerY) * 0.9;

    final Paint dialPaint = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final Paint tickPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw dial arc (270 degrees from -225 to 45 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -225 * (pi / 180), // Start angle (top-left)
      270 * (pi / 180),  // Sweep angle (3/4 of a circle)
      false,
      dialPaint,
    );

    // Draw speed zones
    final greenZoneSweep = (maxSpeed * 0.5 / maxSpeed) * 270 * (pi / 180); // 0-50%
    final yellowZoneSweep = (maxSpeed * 0.25 / maxSpeed) * 270 * (pi / 180); // 50-75%
    final redZoneSweep = (maxSpeed * 0.25 / maxSpeed) * 270 * (pi / 180); // 75-100%

    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -225 * (pi / 180),
      greenZoneSweep,
      false,
      Paint()..color = accentColor.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 10,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -225 * (pi / 180) + greenZoneSweep,
      yellowZoneSweep,
      false,
      Paint()..color = warningColor.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 10,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
      -225 * (pi / 180) + greenZoneSweep + yellowZoneSweep,
      redZoneSweep,
      false,
      Paint()..color = primaryColor.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 10,
    );


    // Draw tick marks and labels
    for (int i = 0; i <= maxSpeed; i += 10) {
      final angle = -225 + (i / maxSpeed * 270);
      final tickStart = Offset(
        centerX + radius * cos(angle * (pi / 180)),
        centerY + radius * sin(angle * (pi / 180)),
      );
      final tickEnd = Offset(
        centerX + (radius - (i % 20 == 0 ? 15 : 8)) * cos(angle * (pi / 180)),
        centerY + (radius - (i % 20 == 0 ? 15 : 8)) * sin(angle * (pi / 180)),
      );
      canvas.drawLine(tickStart, tickEnd, tickPaint);

      if (i % 20 == 0) {
        final TextPainter tp = TextPainter(
          text: TextSpan(
            text: '$i',
            style: TextStyle(color: Colors.white, fontSize: radius * 0.08),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        final textOffset = Offset(
          centerX + (radius - 30) * cos(angle * (pi / 180)) - tp.width / 2,
          centerY + (radius - 30) * sin(angle * (pi / 180)) - tp.height / 2,
        );
        tp.paint(canvas, textOffset);
      }
    }


    // Draw needle
    final needleAngle = -225 + (speed / maxSpeed * 270);
    final needlePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final needlePath = Path();
    needlePath.moveTo(centerX, centerY);
    needlePath.lineTo(
      centerX + radius * 0.8 * cos(needleAngle * pi / 180),
      centerY + radius * 0.8 * sin(needleAngle * pi / 180),
    );
    needlePath.close();

    canvas.drawPath(needlePath, needlePaint..strokeWidth = 4);

    // Draw center hub
    canvas.drawCircle(Offset(centerX, centerY), 10, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(centerX, centerY), 8, Paint()..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed;
  }
}
