// lib/database/database_helper.dart
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:autoperf_monitor/models/driving_session.dart';
import 'package:autoperf_monitor/models/fuel_record.dart';
import 'package:autoperf_monitor/models/gps_point.dart';
import 'package:autoperf_monitor/models/performance_metrics.dart';
import 'package:autoperf_monitor/models/maintenance_record.dart'; // Import MaintenanceRecord

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String? databasesPath = await getDatabasesPath();
    if (databasesPath == null) {
      throw Exception('Unable to get databases path');
    }
    String path = join(databasesPath, 'autoperf_monitor.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE driving_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime INTEGER NOT NULL,
        endTime INTEGER,
        metricsMinSpeed REAL,
        metricsMaxSpeed REAL,
        metricsAverageSpeed REAL,
        metricsDistanceTraveled REAL,
        metricsAltitude REAL,
        refuelingId INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE gps_points(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        altitude REAL NOT NULL,
        speed REAL NOT NULL,
        accuracy REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (sessionId) REFERENCES driving_sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE fuel_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        amount REAL NOT NULL,
        liters REAL NOT NULL,
        mileage REAL NOT NULL,
        fuelType TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE maintenance_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date INTEGER NOT NULL,
        mileage REAL NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        cost REAL
      )
    ''');
  }

  // --- DrivingSession DAO ---
  Future<DrivingSession> insertDrivingSession(DrivingSession session) async {
    final db = await database;

    int? refuelingId;
    if (session.refueling != null) {
      refuelingId = await insertFuelRecord(session.refueling!);
    }

    final sessionId = await db.insert('driving_sessions', {
      'startTime': session.startTime.millisecondsSinceEpoch,
      'endTime': session.endTime?.millisecondsSinceEpoch,
      'metricsMinSpeed': session.metrics.minSpeed,
      'metricsMaxSpeed': session.metrics.maxSpeed,
      'metricsAverageSpeed': session.metrics.averageSpeed,
      'metricsDistanceTraveled': session.metrics.distanceTraveled,
      'metricsAltitude': session.metrics.altitude,
      'refuelingId': refuelingId,
    });

    final newSession = session.copyWith(id: sessionId);

    // Insert GPS points
    for (var point in newSession.trajectory) {
      await db.insert('gps_points', {
        'sessionId': newSession.id,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'altitude': point.altitude,
        'speed': point.speed,
        'accuracy': point.accuracy,
        'timestamp': point.timestamp.millisecondsSinceEpoch,
      });
    }
    return newSession;
  }

  Future<List<DrivingSession>> getDrivingSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> sessionMaps = await db.query('driving_sessions');

    List<DrivingSession> sessions = [];
    for (var sessionMap in sessionMaps) {
      FuelRecord? refuelingRecord;
      if (sessionMap['refuelingId'] != null) {
        refuelingRecord = await _getFuelRecordById(sessionMap['refuelingId']);
      }

      final List<Map<String, dynamic>> gpsMaps = await db.query(
        'gps_points',
        where: 'sessionId = ?',
        whereArgs: [sessionMap['id']],
        orderBy: 'timestamp ASC',
      );

      final List<GPSPoint> trajectory = List.generate(gpsMaps.length, (i) {
        return GPSPoint(
          latitude: gpsMaps[i]['latitude'],
          longitude: gpsMaps[i]['longitude'],
          altitude: gpsMaps[i]['altitude'],
          speed: gpsMaps[i]['speed'],
          accuracy: gpsMaps[i]['accuracy'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(gpsMaps[i]['timestamp']),
        );
      });

      sessions.add(DrivingSession(
        id: sessionMap['id'], // Retrieve the ID
        startTime: DateTime.fromMillisecondsSinceEpoch(sessionMap['startTime']),
        endTime: sessionMap['endTime'] != null ? DateTime.fromMillisecondsSinceEpoch(sessionMap['endTime']) : null,
        metrics: PerformanceMetrics(
          minSpeed: sessionMap['metricsMinSpeed'],
          maxSpeed: sessionMap['metricsMaxSpeed'],
          averageSpeed: sessionMap['metricsAverageSpeed'],
          distanceTraveled: sessionMap['metricsDistanceTraveled'],
          altitude: sessionMap['metricsAltitude'],
        ),
        trajectory: trajectory,
        refueling: refuelingRecord,
      ));
    }
    return sessions;
  }

  Future<void> deleteDrivingSession(int id) async {
    final db = await database;
    await db.delete(
      'driving_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllDrivingSessions() async {
    final db = await database;
    await db.delete('driving_sessions');
  }

  Future<FuelRecord?> _getFuelRecordById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'fuel_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return FuelRecord.fromMap(maps.first);
    }
    return null;
  }


  // --- FuelRecord DAO ---
  Future<int> insertFuelRecord(FuelRecord record) async {
    final db = await database;
    return await db.insert('fuel_records', record.toMap());
  }

  Future<List<FuelRecord>> getFuelRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('fuel_records', orderBy: 'date DESC');

    return List.generate(maps.length, (i) {
      return FuelRecord.fromMap(maps[i]);
    });
  }

  Future<int> updateFuelRecord(FuelRecord record) async {
    final db = await database;
    return db.update(
      'fuel_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteFuelRecord(int id) async {
    final db = await database;
    return await db.delete(
      'fuel_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- MaintenanceRecord DAO ---
  Future<int> insertMaintenanceRecord(MaintenanceRecord record) async {
    final db = await database;
    return await db.insert('maintenance_records', record.toMap());
  }

  Future<List<MaintenanceRecord>> getMaintenanceRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('maintenance_records', orderBy: 'date DESC');

    return List.generate(maps.length, (i) {
      return MaintenanceRecord.fromMap(maps[i]);
    });
  }

  Future<int> updateMaintenanceRecord(MaintenanceRecord record) async {
    final db = await database;
    return db.update(
      'maintenance_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteMaintenanceRecord(int id) async {
    final db = await database;
    return await db.delete(
      'maintenance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
