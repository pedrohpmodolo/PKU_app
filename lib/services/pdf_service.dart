import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

import '../models/analyzed_meal.dart';

class PDFService {
  static const double _maxDailyPHE = 500.0; // Updated to 500mg as per user requirement
  
  /// Format recipe text by parsing JSON and extracting readable content
  static String _formatRecipeText(String recipeText) {
    try {
      // Try to parse as JSON first
      if (recipeText.trim().startsWith('{')) {
        // Remove JSON formatting and extract readable content
        String formatted = recipeText
            .replaceAll(RegExp(r'[{}"]'), '')
            .replaceAll('recipe:', '')
            .replaceAll('ingredients:', '\nIngredients: ')
            .replaceAll('instructions:', '\nInstructions: ')
            .replaceAll('estimated_phe:', '\nEstimated PHE: ')
            .replaceAll('\\n', '\n')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        
        // Clean up any remaining formatting issues
        formatted = formatted
            .replaceAll(RegExp(r',\s*([A-Z])'), '. \$1')
            .replaceAll(RegExp(r'\s*,\s*'), ', ')
            .trim();
            
        return formatted.isNotEmpty ? formatted : recipeText;
      }
      
      // If not JSON, return as-is but clean up formatting
      return recipeText
          .replaceAll('\\n', '\n')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    } catch (e) {
      // If parsing fails, return original text
      return recipeText;
    }
  }
  
  /// Generate PDF with automatic user profile fetching (minimal version - no Supabase)
  static Future<void> generateMealSummaryWithProfile(List<AnalyzedMeal> meals) async {
    await generateMealSummary(meals, userProfile: null);
  }
  
  /// Generate PDF bytes with automatic user profile fetching (minimal version - no Supabase)
  static Future<Uint8List> generateMealSummaryBytesWithProfile(List<AnalyzedMeal> meals) async {
    return await generateMealSummaryBytes(meals, userProfile: null);
  }
  
  static Future<void> generateMealSummary(List<AnalyzedMeal> meals, {Map<String, dynamic>? userProfile}) async {
    try {
      if (meals.isEmpty) {
        throw Exception('No meals provided for PDF generation');
      }

      final pdf = pw.Document();
      final now = DateTime.now();
      final date = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      final totalPHE = meals.fold<double>(0, (sum, meal) => sum + meal.pheAmount);
      final phePercentage = (totalPHE / _maxDailyPHE * 100).clamp(0, 100);

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left side - Title and Date
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              "PKU Wise Daily Meal Summary",
                              style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              "Date: $date",
                              style: pw.TextStyle(
                                fontSize: 16,
                                color: PdfColors.blue600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right side - Username
                      if (userProfile != null && userProfile['name'] != null)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue100,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfColors.blue200),
                          ),
                          child: pw.Text(
                            userProfile['name'],
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 24),
                
                // PHE Summary
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: phePercentage > 80 ? PdfColors.red50 : PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(
                      color: phePercentage > 80 ? PdfColors.red200 : PdfColors.green200,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Daily PHE Summary",
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: phePercentage > 80 ? PdfColors.red800 : PdfColors.green800,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        "Total PHE: ${totalPHE.toStringAsFixed(1)} mg / ${_maxDailyPHE.toInt()} mg",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "Tip: You've used ${phePercentage.toStringAsFixed(1)}% of your daily limit. Great job staying on track!",
                        style: pw.TextStyle(fontSize: 14),
                      ),                                   
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 24),
                
                // Meals Section
                pw.Text(
                  "Meal Details",
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                
                pw.SizedBox(height: 16),
                
                // Meals List
                ...meals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final meal = entry.value;
                  final isLast = index == meals.length - 1;
                  
                  return pw.Container(
                    margin: pw.EdgeInsets.only(bottom: isLast ? 0 : 16),
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              meal.mealType,
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.blue100,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                "${meal.pheAmount.toStringAsFixed(1)} mg PHE",
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          "Ingredients:",
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          meal.ingredients.isNotEmpty 
                            ? meal.ingredients.join(", ")
                            : "No ingredients listed",
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          "Nutritional Summary:",
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          "Per 100g serving - Values may vary based on actual portions consumed",
                          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
                        ),
                        
                        // Display recipe if available
                        if (meal.recipe != null && meal.recipe!.isNotEmpty) ...[
                          pw.SizedBox(height: 12),
                          pw.Text(
                            "Recipe:",
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.blue50,
                              borderRadius: pw.BorderRadius.circular(4),
                              border: pw.Border.all(color: PdfColors.blue200),
                            ),
                            child: pw.Text(
                              _formatRecipeText(meal.recipe!),
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            "Note: The phenylalanine content of this recipe is estimated by multiplying the weight (in grams) of each ingredient by its PHE concentration (in mg/100g) and then summing up the values. For example, if we use 200 grams of plantain and 150 grams of banana in this recipe, the total estimated PHE would be: (200 * 62.5 / 1000) + (150 * 75 / 1000) = ${meal.pheAmount.toStringAsFixed(1)} mg",
                            style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
                          ),
                        ],
                        
                        // Display nutritional summary if available
                        if (meal.nutritionSummary != null && meal.nutritionSummary!.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          ...meal.nutritionSummary!.map((nutrition) {
                            final ingredient = nutrition['ingredient'] ?? 'Unknown';
                            final phe = nutrition['phe']?.toDouble() ?? 0.0;
                            final protein = nutrition['protein']?.toDouble() ?? 0.0;
                            final carbs = nutrition['carbs']?.toDouble() ?? 0.0;
                            final energy = nutrition['energy']?.toDouble() ?? 0.0;
                            final flag = nutrition['flag'] ?? 'Unknown';
                            
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(top: 4),
                              padding: const pw.EdgeInsets.all(6),
                              decoration: pw.BoxDecoration(
                                color: flag.toLowerCase() == 'safe' ? PdfColors.green50 :
                                       flag.toLowerCase() == 'caution' ? PdfColors.orange50 :
                                       flag.toLowerCase() == 'avoid' ? PdfColors.red50 : PdfColors.grey50,
                                borderRadius: pw.BorderRadius.circular(4),
                                border: pw.Border.all(
                                  color: flag.toLowerCase() == 'safe' ? PdfColors.green200 :
                                         flag.toLowerCase() == 'caution' ? PdfColors.orange200 :
                                         flag.toLowerCase() == 'avoid' ? PdfColors.red200 : PdfColors.grey200,
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        ingredient.toUpperCase(),
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: pw.BoxDecoration(
                                          color: flag.toLowerCase() == 'safe' ? PdfColors.green100 :
                                                 flag.toLowerCase() == 'caution' ? PdfColors.orange100 :
                                                 flag.toLowerCase() == 'avoid' ? PdfColors.red100 : PdfColors.grey100,
                                          borderRadius: pw.BorderRadius.circular(2),
                                        ),
                                        child: pw.Text(
                                          flag.toUpperCase(),
                                          style: pw.TextStyle(
                                            fontSize: 7,
                                            fontWeight: pw.FontWeight.bold,
                                            color: flag.toLowerCase() == 'safe' ? PdfColors.green800 :
                                                   flag.toLowerCase() == 'caution' ? PdfColors.orange800 :
                                                   flag.toLowerCase() == 'avoid' ? PdfColors.red800 : PdfColors.grey800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 3),
                                  pw.Row(
                                    children: [
                                      pw.Expanded(
                                        child: pw.Text(
                                          "PHE: ${phe.toStringAsFixed(1)}mg",
                                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Text(
                                          "Protein: ${protein.toStringAsFixed(1)}g",
                                          style: const pw.TextStyle(fontSize: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Row(
                                    children: [
                                      pw.Expanded(
                                        child: pw.Text(
                                          "Carbs: ${carbs.toStringAsFixed(1)}g",
                                          style: const pw.TextStyle(fontSize: 8),
                                        ),
                                      ),
                                      pw.Expanded(
                                        child: pw.Text(
                                          "Energy: ${energy.toStringAsFixed(0)} kcal",
                                          style: const pw.TextStyle(fontSize: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                }),
                
                pw.Spacer(),
                
                // Footer
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Generated by PKU Wise",
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      "Generated on: ${DateTime.now().toString().split('.')[0]}",
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Show print preview or allow download
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'PKU_Meal_Summary_$date.pdf',
      );
    } catch (e) {
      // Handle errors gracefully
      throw Exception('Failed to generate PDF: ${e.toString()}');
    }
  }

  /// Generate a simplified PDF for sharing
  static Future<Uint8List> generateMealSummaryBytes(List<AnalyzedMeal> meals, {Map<String, dynamic>? userProfile}) async {
    try {
      if (meals.isEmpty) {
        throw Exception('No meals provided for PDF generation');
      }

      final pdf = pw.Document();
      final now = DateTime.now();
      final date = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
      final totalPHE = meals.fold<double>(0, (sum, meal) => sum + meal.pheAmount);

      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with username
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "PKU Wise Daily Summary - $date",
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (userProfile != null && userProfile['name'] != null)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey200,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          userProfile['name'],
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  "Total PHE: ${totalPHE.toStringAsFixed(1)} mg / ${_maxDailyPHE.toInt()} mg",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                ...meals.map((meal) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    "- ${meal.mealType}: ${meal.pheAmount.toStringAsFixed(1)} mg PHE",
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                )),
              ],
            );
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to generate PDF bytes: ${e.toString()}');
    }
  }
}
