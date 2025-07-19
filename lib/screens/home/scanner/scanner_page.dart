import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

import 'package:http/http.dart' as http;
import 'dart:convert';

class ScannerWidget extends StatefulWidget {
  const ScannerWidget({super.key});

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  final picker = ImagePicker();

  bool _isProcessing = false;
  String scannedText = '';
  String? protein;
  String? carbs;
  String? energy;
  double phe = 0;

  Future<File> _preprocess(File original) async {
    final bytes = await original.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image');

    final gray = img.grayscale(decoded);
    final sharp = img.adjustColor(gray, contrast: 1.2);
    final processed = File('${original.path}_proc.jpg');
    await processed.writeAsBytes(img.encodeJpg(sharp));
    return processed;
  }

  Future<void> _scan(ImageSource src) async {
    final picked = await picker.pickImage(source: src);
    if (picked == null) return;

    setState(() => _isProcessing = true);

    try {
      final file = await _preprocess(File(picked.path));
      final inputImage = InputImage.fromFile(file);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      _extractNutrients(result.text);
      scannedText = result.text;
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _extractNutrients(String text) {
    protein = _grab(text, ['protein', 'proteins']);
    carbs = _grab(text, ['carbohydrate', 'carbohydrates', 'carbs']);
    energy = _grab(text, ['energy', 'calories', 'kcal']);
    phe = (double.tryParse(protein ?? '') ?? 0) * 50;
  }

  String? _grab(String text, List<String> keys) {
    for (final k in keys) {
      final m = RegExp(
        '$k\\s*[:\\-]?\\s*(\\d+(\\.\\d+)?)',
        caseSensitive: false,
      ).firstMatch(text);
      if (m != null) return m.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nutrStyle = Theme.of(context).textTheme.titleMedium;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // const Divider(),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                onPressed: _isProcessing
                    ? null
                    : () => _scan(ImageSource.camera),
              ),
              // const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('From Gallery'),
                onPressed: _isProcessing
                    ? null
                    : () => _scan(ImageSource.gallery),
              ),
              const SizedBox(height: 25),
              if (protein != null || carbs != null || energy != null) ...[
                Text('🧪 Extracted Nutrients', style: nutrStyle),
                const SizedBox(height: 8),
                Text('Protein: ${protein ?? '—'} g'),
                Text('Carbohydrates: ${carbs ?? '—'} g'),
                Text('Energy: ${energy ?? '—'} kcal'),
                Text('Estimated PHE: ${phe.toStringAsFixed(0)} mg'),
                Text(
                  _riskLevel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _riskLabel(),
                  ),
                ),
                const SizedBox(height: 25),
                Text('📄 Full OCR Text Output:', style: nutrStyle),
                const SizedBox(height: 8),
                Text(scannedText),
              ],
            ],
          ),
        ),
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text(
                    'Analyzing image…',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  MaterialColor _riskLabel() => phe <= 50
      ? Colors.green
      : phe <= 100
      ? Colors.orange
      : Colors.red;
  String get _riskLevel =>
      "Risk Level: ${phe < 50
          ? 'Low Risk'
          : phe <= 100
          ? 'Moderate Risk'
          : 'High Risk'}";
}
