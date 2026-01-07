import 'package:flutter/material.dart';
import 'package:autoperf_monitor/screens/dashboard_screen.dart';
import 'package:autoperf_monitor/screens/fuel_screen.dart';
import 'package:autoperf_monitor/screens/history_stats_screen.dart';

void main() {
  runApp(const MainApp());
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
    return MaterialApp(
      title: 'AutoPerf Monitor',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF3B30), // Rosso automobilistico
        scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Nero carbone
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData( // Added const
          backgroundColor: Color(0xFF00C853), // Verde efficienza
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          selectedItemColor: Color(0xFFFF3B30),
          unselectedItemColor: Colors.grey,
        ),
        cardTheme: CardThemeData( // Changed from CardTheme to CardThemeData
          color: Colors.grey[900],
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 57,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        colorScheme: const ColorScheme.dark().copyWith( // Changed from fromSwatch to dark() and added const
          primary: Color(0xFFFF3B30), // Rosso automobilistico
          secondary: Color(0xFF00C853), // Verde efficienza as accent
          surface: Color(0xFF1A1A1A), // Nero carbone for surface
        ),
      ),
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
  }
}

