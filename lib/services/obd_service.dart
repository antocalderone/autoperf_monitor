// lib/services/obd_service.dart
import 'dart:async';
import 'package:bluetooth_obd/bluetooth_obd.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class ObdService {
  final BluetoothOBD _bluetoothOBD = BluetoothOBD();
  bool _isConnected = false;

  final _speedController = StreamController<double>.broadcast();
  Stream<double> get speedStream => _speedController.stream;

  final _rpmController = StreamController<double>.broadcast();
  Stream<double> get rpmStream => _rpmController.stream;

  // Add more stream controllers for other PIDs as needed
  // e.g., final _fuelLevelController = StreamController<double>.broadcast();

  ObdService() {
    _bluetoothOBD.initBluetooth();
  }

  Future<bool> connectToDevice(String address) async {
    try {
      _isConnected = await _bluetoothOBD.connect(address);
      if (_isConnected) {
        debugPrint('Connected to OBD2 device: $address');
        _startReadingPIDs();
      } else {
        debugPrint('Failed to connect to OBD2 device: $address');
      }
    } catch (e) {
      debugPrint('Error connecting to OBD2 device: $e');
      _isConnected = false;
    }
    return _isConnected;
  }

  Future<void> disconnect() async {
    await _bluetoothOBD.disconnect();
    _isConnected = false;
    _speedController.close();
    _rpmController.close();
    debugPrint('Disconnected from OBD2 device.');
  }

  void _startReadingPIDs() {
    // Read speed (PID 0x0D)
    _bluetoothOBD.readPID(0x0D).listen((speed) {
      if (speed != null) {
        _speedController.add(speed.toDouble());
      }
    });

    // Read RPM (PID 0x0C)
    _bluetoothOBD.readPID(0x0C).listen((rpm) {
      if (rpm != null) {
        _rpmController.add(rpm.toDouble());
      }
    });

    // TODO: Add more PID readings here
  }

  bool get isConnected => _isConnected;

  void dispose() {
    disconnect();
    _speedController.close();
    _rpmController.close();
  }
}
