// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:pkuapp/screens/home/log_dashboard_screen.dart'; // <-- 1. IMPORT a nova tela
import 'package:pkuapp/screens/home/phecalculator/phe_calculator_screen.dart';
import 'package:pkuapp/screens/home/scanner/food_scanner_screen.dart';
import 'package:pkuapp/screens/library/library_screen.dart';
import 'package:pkuapp/screens/home/settings/settings.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // 2. SUBSTITUA a primeira página na lista
  final List<Widget> _pages = [
    const LogDashboardScreen(), // <-- A nova tela do dashboard está aqui
    const PheCalculatorScreen(),
    const FoodScannerScreen(),
    const LibraryScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() { _currentIndex = index; }),
        type: BottomNavigationBarType.fixed, // Mantém a aparência consistente
        selectedItemColor: Theme.of(context).colorScheme.primary, // Adiciona cor ao item selecionado
        unselectedItemColor: Colors.grey.shade600, // Adiciona cor aos itens não selecionados
        items: const [
          // 3. ATUALIZE o primeiro item da barra de navegação
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_outlined),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}