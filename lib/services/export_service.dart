// lib/services/export_service.dart
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cartrackerevo/models/driving_session.dart';
import 'package:cartrackerevo/models/fuel_record.dart';
import 'package:cartrackerevo/utils/date_formatter.dart';

class ExportService {
  Future<String> exportDrivingSessionsToCsv(List<DrivingSession> sessions) async {
    if (sessions.isEmpty) {
      throw Exception('Nessuna sessione di guida da esportare.');
    }

    List<List<dynamic>> rows = [];
    // Header
    rows.add([
      'ID Sessione',
      'Ora Inizio',
      'Ora Fine',
      'Distanza (km)',
      'Velocità Media (km/h)',
      'Velocità Massima (km/h)',
      'Velocità Minima (km/h)',
      'Latitudine',
      'Longitudine',
      'Altitudine (m)',
      'Velocità Punto (km/h)',
      'Timestamp Punto'
    ]);

    for (var session in sessions) {
      if (session.trajectory.isEmpty) {
        rows.add([
          session.id,
          DateFormatter.formatFull(session.startTime),
          session.endTime != null ? DateFormatter.formatFull(session.endTime!) : 'N/A',
          session.metrics.distanceTraveled.toStringAsFixed(2),
          session.metrics.averageSpeed.toStringAsFixed(1),
          session.metrics.maxSpeed.toStringAsFixed(1),
          session.metrics.minSpeed.toStringAsFixed(1),
          'N/A', 'N/A', 'N/A', 'N/A', 'N/A' // No trajectory data
        ]);
      } else {
        for (var point in session.trajectory) {
          rows.add([
            session.id,
            DateFormatter.formatFull(session.startTime),
            session.endTime != null ? DateFormatter.formatFull(session.endTime!) : 'N/A',
            session.metrics.distanceTraveled.toStringAsFixed(2),
            session.metrics.averageSpeed.toStringAsFixed(1),
            session.metrics.maxSpeed.toStringAsFixed(1),
            session.metrics.minSpeed.toStringAsFixed(1),
            point.latitude,
            point.longitude,
            point.altitude,
            point.speed.toStringAsFixed(1),
            DateFormatter.formatFull(point.timestamp)
          ]);
        }
      }
    }

    final String csv = const ListToCsvConverter().convert(rows);
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/driving_sessions_${DateTime.now().millisecondsSinceEpoch}.csv';
    final File file = File(path);
    await file.writeAsString(csv);

    return path;
  }

  Future<String> exportFuelRecordsToPdf(List<FuelRecord> records) async {
    if (records.isEmpty) {
      throw Exception('Nessun record di carburante da esportare.');
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Report Rifornimenti Carburante', style: pw.Theme.of(context).header0),
            ),
            pw.Table.fromTextArray(
              headers: ['Data', 'Importo (€)', 'Litri', 'Chilometraggio (km)', 'Tipo Carburante'],
              data: records.map((record) => [
                DateFormatter.formatAnoMonthDay(record.date),
                record.amount.toStringAsFixed(2),
                record.liters.toStringAsFixed(2),
                record.mileage.toStringAsFixed(0),
                record.fuelType.name.toUpperCase(),
              ]).toList(),
              border: pw.TableBorder.all(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/fuel_records_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(path);
    await file.writeAsBytes(await pdf.save());

    return path;
  }
}
