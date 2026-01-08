import 'dart:math';
import 'package:cartrackerevo/notifiers/history_notifier.dart';
import 'package:cartrackerevo/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cartrackerevo/database/database_helper.dart';
import 'package:cartrackerevo/models/driving_session.dart';
import 'package:cartrackerevo/models/fuel_record.dart'; // Import FuelRecord
import 'package:cartrackerevo/services/export_service.dart';
import 'package:cartrackerevo/screens/maintenance_screen.dart';
import 'package:provider/provider.dart'; // Import MaintenanceScreen

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
  late HistoryNotifier _historyNotifier;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyNotifier = Provider.of<HistoryNotifier>(context);
    _historyNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    _historyNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final sessions = await _databaseHelper.getDrivingSessions();
    final records = await _databaseHelper.getFuelRecords();
    if (mounted) {
      setState(() {
        _drivingSessions = sessions;
        _fuelRecords = records;
      });
    }
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
          SnackBar(content: Text('Sessioni di guida esportate in: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante l\'esportazione delle sessioni di guida: $e')),
        );
      }
    }
  }

  Future<void> _exportFuelRecords() async {
    try {
      final path = await _exportService.exportFuelRecordsToPdf(_fuelRecords);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record di carburante esportati in: $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante l\'esportazione dei record di carburante: $e')),
        );
      }
    }
  }

  Future<void> _resetSessions() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Sei sicuro di voler eliminare tutte le sessioni di guida?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Elimina'),
              onPressed: () async {
                await _databaseHelper.deleteAllDrivingSessions();
                _loadData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tutte le sessioni di guida sono state eliminate.')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSession(int sessionId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to dismiss.
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Eliminazione'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Sei sicuro di voler eliminare questa sessione di guida?'),
                Text('Questa azione è irreversibile.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annulla'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Elimina'),
              onPressed: () async {
                await _databaseHelper.deleteDrivingSession(sessionId);
                _loadData(); // Refresh the list after deletion.
                Navigator.of(context).pop(); // Close the dialog.
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sessione eliminata con successo.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronologia e Statistiche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MaintenanceScreen()),
              );
            },
            tooltip: 'Registro Manutenzione',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esporta Dati',
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
                    label: const Text('Esporta Sessioni (CSV)'),
                  ),
                ),
                const SizedBox(width: 10), // Add some spacing between buttons
                Expanded( // Wrap with Expanded
                  child: ElevatedButton.icon(
                    onPressed: _exportFuelRecords,
                    icon: const Icon(Icons.download),
                    label: const Text('Esporta Carburante (PDF)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _resetSessions,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Azzera Sessioni'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.redAccent,
              ),
            ),
            const Divider(height: 40),
            Text(
              'Sessioni di Guida Registrate',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _drivingSessions.isEmpty
                ? const Center(child: Text('Nessuna sessione di guida registrata.'))
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

                final duration = session.endTime?.difference(session.startTime);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Sessione: ${DateFormatter.formatFull(session.startTime)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _deleteSession(session.id!),
                              tooltip: 'Elimina Sessione',
                            ),
                          ],
                        ),
                        if (session.endTime != null)
                          Text(
                            'Fine: ${DateFormatter.formatFull(session.endTime!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (duration != null)
                          Text(
                            'Durata: ${DateFormatter.formatDuration(duration)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        Text(
                          'Distanza: ${session.metrics.distanceTraveled.toStringAsFixed(2)} km',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Velocità Media: ${session.metrics.averageSpeed.toStringAsFixed(1)} km/h',
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
                                  axisNameWidget: const Text('Velocità (km/h)'),
                                  axisNameSize: 24,
                                  sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text(value.toInt().toString())),
                                ),
                                bottomTitles: AxisTitles(
                                  axisNameWidget: const Text('Ora'),
                                  axisNameSize: 24,
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value == minX || value == maxX) {
                                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 8.0,
                                          child: Text(DateFormatter.formatHourMinute(date), style: const TextStyle(fontSize: 10)),
                                        );
                                      }
                                      return Container();
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
                            : const Text('Nessun dato di velocità disponibile per questa sessione.'),
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
