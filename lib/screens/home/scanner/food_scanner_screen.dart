// lib/screens/scanner/food_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:pkuapp/screens/home/scanner/barcode_scanner_screen.dart';

class FoodScannerScreen extends StatelessWidget {
  const FoodScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyze Food')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // We only show the barcode scanner button for now
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Product Barcode'),
                onPressed: () {
                   Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              ),
              const SizedBox(height: 24),
              const Text(
                "Nutrition label scanning (OCR) is coming soon!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}