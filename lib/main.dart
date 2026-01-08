import 'package:cartrackerevo/notifiers/history_notifier.dart';
import 'package:cartrackerevo/theme/theme_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cartrackerevo/screens/dashboard_screen.dart';
import 'package:cartrackerevo/screens/fuel_screen.dart';
import 'package:cartrackerevo/screens/history_stats_screen.dart';
import 'package:cartrackerevo/services/settings_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier(SettingsService())),
        ChangeNotifierProvider(create: (_) => HistoryNotifier()),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    FuelScreen(),
    HistoryStatsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'CarTrackerEvo',
          theme: themeNotifier.getTheme,
          home: Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.speed),
                  label: 'Cruscotto',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.local_gas_station),
                  label: 'Rifornimento',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'Cronologia',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          ),
        );
      },
    );
  }
}
