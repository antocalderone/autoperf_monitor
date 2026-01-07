import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:autoperf_monitor/database/database_helper.dart';
import 'package:autoperf_monitor/models/driving_session.dart';
import 'package:autoperf_monitor/models/gps_point.dart';
import 'package:autoperf_monitor/models/fuel_record.dart'; // Import FuelRecord
import 'package:autoperf_monitor/services/export_service.dart';
import 'package:autoperf_monitor/screens/maintenance_screen.dart'; // Import MaintenanceScreen

class HistoryStatsScreen extends StatefulWidget {
  const HistoryStatsScreen({super.key});

  @override
  State<HistoryStatsScreen> createState() => _HistoryStatsScreenState();
}

class _HistoryStatsScreenState extends State<HistoryStatsScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final ExportService _exportService = ExportService();
  List<DrivingSession> _drivingSessions = [];
  List<FuelRecord> _fuelRecords = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sessions = await _databaseHelper.getDrivingSessions();
    final records = await _databaseHelper.getFuelRecords();
    setState(() {
      _drivingSessions = sessions;
      _fuelRecords = records;
    });
  }

  List<FlSpot> _getSpeedTimeSpots(DrivingSession session) {
    if (session.trajectory.isEmpty) return [];

    return session.trajectory.map((point) {
      return FlSpot(point.timestamp.millisecondsSinceEpoch.toDouble(), point.speed);
    }).toList();
  }

  Future<void> _exportDrivingSessions() async {
    try {
      final path = await _exportService.exportDrivingSessionsToCsv(_drivingSessions);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driving sessions exported to: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting driving sessions: $e')),
        );
      }
    }
  }

  Future<void> _exportFuelRecords() async {
    try {
      final path = await _exportService.exportFuelRecordsToPdf(_fuelRecords);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fuel records exported to: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting fuel records: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
              );
            },
            tooltip: 'Maintenance Records',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded( // Wrap with Expanded
                  child: ElevatedButton.icon(
                    onPressed: _exportDrivingSessions,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Sessions (CSV)'),
                  ),
                ),
                const SizedBox(width: 10), // Add some spacing between buttons
                Expanded( // Wrap with Expanded
                  child: ElevatedButton.icon(
                    onPressed: _exportFuelRecords,
                    icon: const Icon(Icons.download),
                    label: const Text('Export Fuel (PDF)'),
                  ),
                ),
              ],
            ),
            const Divider(height: 40),
            Text(
              'Recorded Driving Sessions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _drivingSessions.isEmpty
                ? const Center(child: Text('No driving sessions recorded yet.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _drivingSessions.length,
                    itemBuilder: (context, index) {
                      final session = _drivingSessions[index];
                      final speedTimeSpots = _getSpeedTimeSpots(session);

                      double minX = speedTimeSpots.isNotEmpty ? speedTimeSpots.first.x : 0;
                      double maxX = speedTimeSpots.isNotEmpty ? speedTimeSpots.last.x : 0;
                      double minY = speedTimeSpots.isNotEmpty ? speedTimeSpots.map((e) => e.y).reduce(min) : 0;
                      double maxY = speedTimeSpots.isNotEmpty ? speedTimeSpots.map((e) => e.y).reduce(max) : 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Session: ${DateFormat('yyyy-MM-dd HH:mm').format(session.startTime)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (session.endTime != null)
                                Text(
                                  'End: ${DateFormat('yyyy-MM-dd HH:mm').format(session.endTime!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              Text(
                                'Distance: ${session.metrics.distanceTraveled.toStringAsFixed(2)} km',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Avg Speed: ${session.metrics.averageSpeed.toStringAsFixed(1)} km/h',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 10),
                              speedTimeSpots.isNotEmpty
                                ? SizedBox(
                                    height: 200,
                                    child: LineChart(
                                      LineChartData(
                                        gridData: const FlGridData(show: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            axisNameWidget: const Text('Speed (km/h)'),
                                            axisNameSize: 24,
                                            sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text(value.toInt().toString())),
                                          ),
                                          bottomTitles: AxisTitles(
                                            axisNameWidget: const Text('Time'),
                                            axisNameSize: 24,
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 30,
                                              getTitlesWidget: (value, meta) {
                                                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                                return SideTitleWidget(
                                                  meta: meta,
                                                  space: 8.0,
                                                  child: Text(DateFormat('HH:mm').format(date), style: const TextStyle(fontSize: 10)),
                                                );
                                              },
                                            ),
                                          ),
                                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        borderData: FlBorderData(
                                          show: true,
                                          border: Border.all(color: const Color(0xff37434d), width: 1),
                                        ),
                                        minX: minX,
                                        maxX: maxX,
                                        minY: minY > 0 ? minY * 0.9 : 0, // 10% padding
                                        maxY: maxY * 1.1, // 10% padding
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: speedTimeSpots,
                                            isCurved: true,
                                            color: Colors.lightBlueAccent,
                                            barWidth: 3,
                                            isStrokeCapRound: true,
                                            dotData: const FlDotData(show: false),
                                            belowBarData: BarAreaData(show: false),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const Text('No speed data available for this session.'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}