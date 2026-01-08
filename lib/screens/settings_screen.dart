// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:autoperf_monitor/theme/theme_notifier.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    final List<Color> themeColors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tema',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Modalità Scura'),
              value: themeNotifier.isDarkMode,
              onChanged: (value) {
                themeNotifier.setDarkMode(value);
              },
            ),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              'Colore Primario',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: themeColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    themeNotifier.setPrimaryColor(color);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: themeNotifier.primaryColor == color
                            ? Theme.of(context).colorScheme.secondary
                            : Colors.transparent,
                        width: 3.0,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
