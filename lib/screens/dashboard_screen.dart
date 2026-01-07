// lib/screens/dashboard_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:autoperf_monitor/widgets/analog_speedometer.dart';
import 'package:autoperf_monitor/services/performance_monitor.dart'; // Import the service
import 'package:autoperf_monitor/models/performance_metrics.dart'; // Import PerformanceMetrics
// import 'package:autoperf_monitor/services/obd_service.dart'; // Commented out ObdService import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  // final ObdService _obdService = ObdService(); // Commented out ObdService initialization
  double _currentGpsSpeed = 0.0;
  // double _currentObdSpeed = 0.0; // Commented out
  // double _currentObdRpm = 0.0; // Commented out
  PerformanceMetrics _currentMetrics = PerformanceMetrics();
  double _gpsAccuracy = 0.0;
  bool _isMonitoring = false;
  // bool _isObdConnected = false; // Commented out

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation; // New animation for scaling

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.0, // Corrected to 0.0
      upperBound: 1.0,  // Corrected to 1.0
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(_pulseAnimation); // Apply tween to animation

    _performanceMonitor.speedStream.listen((speed) {
      if (mounted) {
        setState(() {
          _currentGpsSpeed = speed;
          _updateSpeedDisplay(speed); // Pass speed to update method
        });
      }
    });
    _performanceMonitor.metricsStream.listen((metrics) {
      if (mounted) {
        setState(() {
          _currentMetrics = metrics;
        });
      }
    });
    _performanceMonitor.gpsAccuracyStream.listen((accuracy) {
      if (mounted) {
        setState(() {
          _gpsAccuracy = accuracy;
        });
      }
    });

    // Commented out OBD listeners
    // _obdService.speedStream.listen((obdSpeed) {
    //   if (mounted) {
    //     setState(() {
    //       _currentObdSpeed = obdSpeed;
    //       _updateSpeedDisplay(_currentGpsSpeed); // Update with GPS speed as OBD is off
    //     });
    //   }
    // });
    // _obdService.rpmStream.listen((obdRpm) {
    //   if (mounted) {
    //     setState(() {
    //       _currentObdRpm = obdRpm;
    //     });
    //   }
    // });
  }

  void _updateSpeedDisplay(double gpsSpeed) {
    double speedToDisplay = gpsSpeed;
    // if (_isObdConnected && _currentObdSpeed > 0) { // Commented out OBD speed prioritization
    //   speedToDisplay = _currentObdSpeed;
    // }

    if (speedToDisplay > 120) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _performanceMonitor.stopMonitoring();
    _performanceMonitor.dispose();
    // _obdService.dispose(); // Commented out Dispose ObdService
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleMonitoring() async { // Changed to async
    HapticFeedback.lightImpact(); // Haptic feedback on button press
    if (_isMonitoring) {
      _performanceMonitor.stopMonitoring();
      setState(() {
        _isMonitoring = false;
      });
    } else {
      try {
        await _performanceMonitor.startMonitoring(); // Await without assignment
        setState(() {
          _isMonitoring = true;
        });
      } catch (e) {
        // Show error message if monitoring failed to start
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start monitoring: ${e.toString()}')), // Display the caught error
        );
      }
    }
  }

  // Commented out OBD connection method
  // Future<void> _connectToObd() async {
  //   const String obdBluetoothAddress = "XX:XX:XX:XX:XX:XX";
  //   bool connected = await _obdService.connectToDevice(obdBluetoothAddress);
  //   setState(() {
  //     _isObdConnected = connected;
  //   });

  //   if (connected) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Connected to OBD2!')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to connect to OBD2.')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    // double speedToDisplay = _isObdConnected && _currentObdSpeed > 0 ? _currentObdSpeed : _currentGpsSpeed; // Commented out
    double speedToDisplay = _currentGpsSpeed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cruscotto'),
        // actions: [ // Commented out OBD connection button
        //   IconButton(
        //     icon: Icon(_isObdConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
        //     onPressed: _isObdConnected ? _obdService.disconnect : _connectToObd,
        //     tooltip: _isObdConnected ? 'Disconnect OBD2' : 'Connect OBD2',
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GPS Precision Indicator
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Precisione GPS: ${_gpsAccuracy.toStringAsFixed(1)} m',
                  style: TextStyle(
                    color: _gpsAccuracy < 10 ? Colors.green : (_gpsAccuracy < 30 ? Colors.orange : Colors.red),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            // Commented out OBD RPM display
            // if (_isObdConnected)
            //   Align(
            //     alignment: Alignment.centerLeft,
            //     child: Padding(
            //       padding: const EdgeInsets.only(bottom: 8.0),
            //       child: Text(
            //         'OBD RPM: ${_currentObdRpm.toStringAsFixed(0)}',
            //         style: const TextStyle(
            //           color: Colors.white,
            //           fontSize: 14,
            //         ),
            //       ),
            //     ),
            //   ),
            // Speedometer and Digital Display
            SizedBox( // Added SizedBox for explicit constraints
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.8,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnalogSpeedometer(speed: speedToDisplay),
                  GestureDetector(
                    onTap: _toggleMonitoring,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _isMonitoring ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isMonitoring ? Colors.red : Colors.green).withAlpha(100),
                            blurRadius: 10.0,
                            spreadRadius: 5.0,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isMonitoring ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Metric List
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MetricRow(
                  icon: Icons.speed,
                  label: 'Velocità',
                  value: '${_currentGpsSpeed.toStringAsFixed(1)} km/h',
                ),
                _MetricRow(
                  icon: Icons.landscape,
                  label: 'Altitudine',
                  value: '${_currentMetrics.altitude.toStringAsFixed(1)} m',
                ),
                _MetricRow(
                  icon: Icons.av_timer,
                  label: 'Velocità media',
                  value: '${_currentMetrics.averageSpeed.toStringAsFixed(1)} km/h',
                ),
                _MetricRow(
                  icon: Icons.arrow_downward,
                  label: 'Velocità minima',
                  value: '${_currentMetrics.minSpeed.toStringAsFixed(1)} km/h',
                ),
                _MetricRow(
                  icon: Icons.arrow_upward,
                  label: 'Velocità massima',
                  value: '${_currentMetrics.maxSpeed.toStringAsFixed(1)} km/h',
                ),
                _MetricRow(
                  icon: Icons.directions_car,
                  label: 'Distanza',
                  value: '${_currentMetrics.distanceTraveled.toStringAsFixed(2)} km',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
