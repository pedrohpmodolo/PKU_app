// lib/screens/scanner/barcode_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pkuapp/models/food_item.dart'; // Import the new model
import 'package:pkuapp/screens/home/chat/chat_service.dart'; 
import 'package:pkuapp/services/library_service.dart'; // Import the new library service
import 'package:supabase_flutter/supabase_flutter.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final ChatService _chatService = ChatService();
  final LibraryService _libraryService = LibraryService(); // New service instance
  final MobileScannerController cameraController = MobileScannerController();

  bool _isProcessing = false;
  String? _analysisResult;
  FoodItem? _scannedFood; // Store the scanned food item

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _scannedFood = null; // Clear previous food
    });
    cameraController.stop();

    final String? barcode = capture.barcodes.first.rawValue;
    if (barcode == null) {
      if(mounted) setState(() => _isProcessing = false);
      cameraController.start();
      return;
    }

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barcode found: $barcode. Looking up product...')),
      );
    }

    final productData = await _fetchProductFromApi(barcode);
    if (productData == null) {
      if(mounted) {
        setState(() {
          _analysisResult = "Product not found in the Open Food Facts database.";
          _isProcessing = false;
        });
      }
      return;
    }
    
    // Create a FoodItem from the API data
    if(mounted) {
      setState(() {
        _scannedFood = FoodItem.fromOpenFoodFacts(barcode, productData);
      });
    }
    
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
       if(mounted) {
        setState(() {
          _analysisResult = "Error: Not logged in.";
          _isProcessing = false;
        });
      }
      return;
    }

    final queryForAI = "Analyze this product: ${_scannedFood!.name} (Protein: ${_scannedFood!.proteinG}g/100g)";
    final aiAnalysis = await _chatService.getRAGResponse(
      query: queryForAI, 
      history: [],
    );
    
    if(mounted) {
      setState(() {
        _analysisResult = aiAnalysis;
        _isProcessing = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchProductFromApi(String barcode) async {
    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode?fields=product_name,nutriments,categories_tags');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          return data['product'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onBarcodeDetected),
          Center(child: Container(width: 250, height: 150, decoration: BoxDecoration(border: Border.all(color: Colors.green, width: 4), borderRadius: BorderRadius.circular(12)))),
          
          if (_analysisResult != null)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Analysis Result', style: Theme.of(context).textTheme.headlineSmall),
                          const Divider(),
                          SelectableText(_analysisResult ?? ''),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // --- ADDED LIKE BUTTON ---
                              IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.pink),
                                iconSize: 30,
                                tooltip: 'Save to Library',
                                onPressed: () {},
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _analysisResult = null;
                                    _scannedFood = null;
                                  });
                                  cameraController.start();
                                },
                                child: const Text('Scan Another'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
             if (_isProcessing && _analysisResult == null)
              const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}