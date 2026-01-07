// lib/screens/maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:autoperf_monitor/database/database_helper.dart';
import 'package:autoperf_monitor/models/maintenance_record.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  MaintenanceType _selectedMaintenanceType = MaintenanceType.oilChange;

  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<MaintenanceRecord> _maintenanceRecords = [];

  @override
  void initState() {
    super.initState();
    _loadMaintenanceRecords();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _loadMaintenanceRecords() async {
    final records = await _databaseHelper.getMaintenanceRecords();
    setState(() {
      _maintenanceRecords = records;
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
      final newRecord = MaintenanceRecord(
        date: _selectedDate,
        mileage: double.parse(_mileageController.text),
        type: _selectedMaintenanceType,
        description: _descriptionController.text,
        cost: double.parse(_costController.text),
      );

      await _databaseHelper.insertMaintenanceRecord(newRecord);
      _loadMaintenanceRecords(); // Reload records after adding

      // Clear form
      _mileageController.clear();
      _descriptionController.clear();
      _costController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedMaintenanceType = MaintenanceType.oilChange;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maintenance record added successfully!')), 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Records'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Maintenance',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  ListTile(
                    title: Text('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _mileageController,
                    decoration: const InputDecoration(
                      labelText: 'Mileage (km)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter mileage';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<MaintenanceType>(
                    value: _selectedMaintenanceType,
                    decoration: const InputDecoration(
                      labelText: 'Maintenance Type',
                      border: OutlineInputBorder(),
                    ),
                    items: MaintenanceType.values.map((MaintenanceType type) {
                      return DropdownMenuItem<MaintenanceType>(
                        value: type,
                        child: Text(type.name.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')),
                      );
                    }).toList(),
                    onChanged: (MaintenanceType? newValue) {
                      setState(() {
                        _selectedMaintenanceType = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Cost (€)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter cost';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Add Maintenance Record'),
                  ),
                ],
              ),
            ),
            const Divider(height: 40),
            Text(
              'Maintenance History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _maintenanceRecords.isEmpty
                ? const Center(child: Text('No maintenance records yet.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _maintenanceRecords.length,
                    itemBuilder: (context, index) {
                      final record = _maintenanceRecords[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('${record.formattedDate} - ${record.type.name.replaceAll(RegExp(r'(?<!^)(?=[A-Z])'), ' ')}'),
                          subtitle: Text('Mileage: ${record.formattedMileage} | Cost: ${record.formattedCost}\n${record.description}'),
                          isThreeLine: record.description.isNotEmpty,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              if (record.id != null) {
                                await _databaseHelper.deleteMaintenanceRecord(record.id!);
                                _loadMaintenanceRecords();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Maintenance record deleted!')), 
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
