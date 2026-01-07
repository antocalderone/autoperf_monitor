// lib/screens/fuel_screen.dart
import 'package:autoperf_monitor/utils/date_formatter.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:autoperf_monitor/models/fuel_record.dart';
import 'package:autoperf_monitor/database/database_helper.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _litersController = TextEditingController();
  final TextEditingController _mileageController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  FuelType _selectedFuelType = FuelType.benzina;

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<FuelRecord> _fuelRecords = [];

  @override
  void initState() {
    super.initState();
    _loadFuelRecords();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _litersController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _loadFuelRecords() async {
    final records = await _databaseHelper.getFuelRecords();
    setState(() {
      _fuelRecords = records;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final newRecord = FuelRecord(
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        liters: double.parse(_litersController.text),
        mileage: double.parse(_mileageController.text),
        fuelType: _selectedFuelType,
      );

      await _databaseHelper.insertFuelRecord(newRecord);
      _loadFuelRecords(); // Reload records after adding

      // Clear form
      _amountController.clear();
      _litersController.clear();
      _mileageController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedFuelType = FuelType.petrol;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rifornimento aggiunto con successo!')),
      );
    }
  }

  _FuelStatistics _calculateStatistics() {
    if (_fuelRecords.isEmpty || _fuelRecords.length < 2) {
      return _FuelStatistics(); // Return default empty stats
    }

    double totalLiters = 0;
    double totalAmount = 0;
    double totalDistance = 0;

    // Sort records by mileage to ensure correct distance calculation
    _fuelRecords.sort((a, b) => a.mileage.compareTo(b.mileage));

    // Calculate total liters, amount, and distance covered between fill-ups
    for (int i = 0; i < _fuelRecords.length - 1; i++) {
      final current = _fuelRecords[i];
      final next = _fuelRecords[i + 1];

      // Assuming each fuel record represents a fill-up, and the distance covered is between current and next mileage.
      // Liters are from the next fill-up
      totalLiters += next.liters;
      totalAmount += next.amount;
      totalDistance += (next.mileage - current.mileage);
    }

    if (totalDistance == 0 || totalLiters == 0) {
      return _FuelStatistics();
    }

    final avgConsumption = totalDistance / totalLiters; // km/l
    final costPerKm = totalAmount / totalDistance; // €/km
    // Estimated range is harder to calculate accurately without knowing tank size or driving patterns.
    // For simplicity, let's assume average consumption for a hypothetical 50-liter tank.
    final estimatedRange = avgConsumption * 50; // km

    return _FuelStatistics(
      avgConsumption: avgConsumption,
      costPerKm: costPerKm,
      estimatedRange: estimatedRange,
    );
  }

  List<FlSpot> _getChartData() {
    if (_fuelRecords.length < 2) {
      return [];
    }

    _fuelRecords.sort((a, b) => a.date.compareTo(b.date));

    List<FlSpot> spots = [];
    double cumulativeDistance = 0;
    double cumulativeLiters = 0;

    for (int i = 0; i < _fuelRecords.length - 1; i++) {
      final current = _fuelRecords[i];
      final next = _fuelRecords[i + 1];

      final distance = next.mileage - current.mileage;
      final liters = next.liters;

      cumulativeDistance += distance;
      cumulativeLiters += liters;

      if (cumulativeLiters > 0) {
        spots.add(FlSpot(
          current.date.millisecondsSinceEpoch.toDouble(),
          cumulativeDistance / cumulativeLiters,
        ));
      }
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();
    final chartData = _getChartData();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rifornimento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aggiungi Rifornimento',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            // Form for adding refueling data
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Date Picker
                  ListTile(
                    title: Text('Data: ${DateFormatter.formatAnoMonthDay(_selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 10),
                  // Amount
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Importo (€)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci l\'importo';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Inserisci un numero valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // Liters
                  TextFormField(
                    controller: _litersController,
                    decoration: const InputDecoration(
                      labelText: 'Litri',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci i litri';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Inserisci un numero valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // Mileage
                  TextFormField(
                    controller: _mileageController,
                    decoration: const InputDecoration(
                      labelText: 'Chilometraggio (km)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci il chilometraggio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Inserisci un numero valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  // Fuel Type Dropdown
                  DropdownButtonFormField<FuelType>(
                    value: _selectedFuelType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo Carburante',
                      border: OutlineInputBorder(),
                    ),
                    items: FuelType.values.map((FuelType type) {
                      return DropdownMenuItem<FuelType>(
                        value: type,
                        child: Text(type.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (FuelType? newValue) {
                      setState(() {
                        _selectedFuelType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Aggiungi Rifornimento'),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            // Fuel Statistics
            Text(
              'Statistiche Consumo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _StatisticCard(
              title: 'Consumo Medio',
              value: stats.avgConsumption,
              unit: 'km/l',
              format: true,
            ),
            _StatisticCard(
              title: 'Costo per Km',
              value: stats.costPerKm,
              unit: '€/km',
              format: true,
            ),
            _StatisticCard(
              title: 'Autonomia Stimata',
              value: stats.estimatedRange,
              unit: 'km',
              format: true,
            ),
            const Divider(height: 40),
            // Historical Fuel Consumption Chart
            Text(
              'Consumo Storico (km/l)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200, // Fixed height for the chart
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles( // Removed const
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return SideTitleWidget(
                            meta: meta, // Added meta parameter
                            space: 8.0,
                            child: Text(DateFormatter.formatAnoMonthDay(date), style: const TextStyle(fontSize: 10)),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Removed const
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Removed const
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d), width: 1),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData,
                      isCurved: true,
                      color: Colors.blueAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 40),
            // List of Refueling Records
            Text(
              'Cronologia Rifornimenti',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _fuelRecords.isEmpty
                ? const Center(child: Text('Nessun rifornimento registrato.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _fuelRecords.length,
                    itemBuilder: (context, index) {
                      final record = _fuelRecords[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('${DateFormatter.formatAnoMonthDay(record.date)} - ${record.fuelType.name.toUpperCase()}'),
                          subtitle: Text('Litri: ${record.liters.toStringAsFixed(2)} | Importo: €${record.amount.toStringAsFixed(2)} | Chilometraggio: ${record.mileage.toStringAsFixed(0)} km'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              if (record.id != null) {
                                await _databaseHelper.deleteFuelRecord(record.id!);
                                _loadFuelRecords();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Rifornimento eliminato!')),
                                );
                              }
                            },
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

class _StatisticCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final bool format;

  const _StatisticCard({
    required this.title,
    required this.value,
    required this.unit,
    this.format = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.grey[850],
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            Text(
              format ? '${value.toStringAsFixed(2)} $unit' : '$value $unit',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FuelStatistics {
  final double avgConsumption;
  final double costPerKm;
  final double estimatedRange;

  _FuelStatistics({
    this.avgConsumption = 0.0,
    this.costPerKm = 0.0,
    this.estimatedRange = 0.0,
  });
}
