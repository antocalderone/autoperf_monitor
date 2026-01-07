// lib/services/export_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:autoperf_monitor/models/driving_session.dart';
import 'package:autoperf_monitor/models/fuel_record.dart';
import 'package:intl/intl.dart';

class ExportService {
  Future<String> exportDrivingSessionsToCsv(List<DrivingSession> sessions) async {
    List<List<dynamic>> rows = [];
    // CSV Header
    rows.add([
      'Session ID', 'Start Time', 'End Time', 'Min Speed (km/h)', 'Max Speed (km/h)',
      'Average Speed (km/h)', 'Distance Traveled (km)', 'Altitude (m)',
      'Refueling Date', 'Refueling Amount (€)', 'Refueling Liters',
      'Refueling Mileage', 'Refueling Fuel Type'
    ]);

    // CSV Data
    for (var session in sessions) {
      rows.add([
        session.id,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime),
        session.endTime != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!) : '',
        session.metrics.minSpeed,
        session.metrics.maxSpeed,
        session.metrics.averageSpeed,
        session.metrics.distanceTraveled,
        session.metrics.altitude,
        session.refueling?.date != null ? DateFormat('yyyy-MM-dd').format(session.refueling!.date) : '',
        session.refueling?.amount ?? '',
        session.refueling?.liters ?? '',
        session.refueling?.mileage ?? '',
        session.refueling?.fuelType.name ?? '',
      ]);
      // TODO: Optionally add GPS points data as separate rows or a separate CSV
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/driving_sessions.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }

  Future<String> exportFuelRecordsToCsv(List<FuelRecord> records) async {
    List<List<dynamic>> rows = [];
    // CSV Header
    rows.add(['Record ID', 'Date', 'Amount (€)', 'Liters', 'Mileage (km)', 'Fuel Type']);

    // CSV Data
    for (var record in records) {
      rows.add([
        record.id,
        DateFormat('yyyy-MM-dd').format(record.date),
        record.amount,
        record.liters,
        record.mileage,
        record.fuelType.name,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/fuel_records.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }

  Future<String> exportDrivingSessionsToPdf(List<DrivingSession> sessions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(child: pw.Text('Driving Sessions Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            for (var session in sessions) ...[
              pw.Text('Session ID: ${session.id}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Start Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.startTime)}'),
              if (session.endTime != null) pw.Text('End Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(session.endTime!)}'),
              pw.Text('Distance: ${session.metrics.distanceTraveled.toStringAsFixed(2)} km'),
              pw.Text('Average Speed: ${session.metrics.averageSpeed.toStringAsFixed(1)} km/h'),
              pw.Text('Max Speed: ${session.metrics.maxSpeed.toStringAsFixed(1)} km/h'),
              pw.Text('Min Speed: ${session.metrics.minSpeed.toStringAsFixed(1)} km/h'),
              pw.Text('Altitude: ${session.metrics.altitude.toStringAsFixed(0)} m'),
              if (session.refueling != null) ...[
                pw.SizedBox(height: 10),
                pw.Text('Refueling Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('  Date: ${DateFormat('yyyy-MM-dd').format(session.refueling!.date)}'),
                pw.Text('  Amount: €${session.refueling!.amount.toStringAsFixed(2)}'),
                pw.Text('  Liters: ${session.refueling!.liters.toStringAsFixed(2)}'),
                pw.Text('  Mileage: ${session.refueling!.mileage.toStringAsFixed(0)} km'),
                pw.Text('  Fuel Type: ${session.refueling!.fuelType.name}'),
              ],
              pw.Divider(),
            ]
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/driving_sessions_report.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }

  Future<String> exportFuelRecordsToPdf(List<FuelRecord> records) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Center(child: pw.Text('Fuel Records Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Date', 'Amount (€)', 'Liters', 'Mileage (km)', 'Fuel Type'],
              data: records.map((record) => [
                DateFormat('yyyy-MM-dd').format(record.date),
                record.amount.toStringAsFixed(2),
                record.liters.toStringAsFixed(2),
                record.mileage.toStringAsFixed(0),
                record.fuelType.name,
              ]).toList(),
            ),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/fuel_records_report.pdf';
    final file = File(path);
    await file.writeAsBytes(await pdf.save());
    return path;
  }
}
