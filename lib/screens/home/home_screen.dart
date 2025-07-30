// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:pkuapp/screens/home/chat/conversation_list.dart';
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

  final List<Widget> _pages = [
    const ConversationListScreen(),
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt), 
            label: 'Scanner',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}