import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../../services/pdf_service.dart';
import '../../models/analyzed_meal.dart';


class IngredientInputScreen extends StatefulWidget {
  static const routeName = '/ingredient-input';

  @override
  _IngredientInputScreenState createState() => _IngredientInputScreenState();
}

class _IngredientInputScreenState extends State<IngredientInputScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _recipe;
  double? _phe;
  Map<String, String>? _flags;
  String? _error;
  
  // Daily tracking variables
  double _dailyPheTotal = 0.0;
  List<Map<String, dynamic>> _dailyMeals = [];
  bool _isDayComplete = false;

  //KSP - adding this here
  String _selectedMealType = 'Unspecified';

  final List<String> _mealTypes = [
    'Unspecified', // ✅ Add this to match the default value
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadDailySummary();
  }

  Future<void> _loadDailySummary() async {
    final summary = await ApiService.getDailySummary();
    if (summary != null) {
      setState(() {
        _dailyPheTotal = (summary['daily_phe_total'] ?? 0.0).toDouble();
        _dailyMeals = List<Map<String, dynamic>>.from(summary['daily_meals'] ?? []);
      });
    }
  }

  Future<void> _analyzeIngredients() async {
    final ingredients =
        _controller.text.split(',').map((e) => e.trim()).toList();

    setState(() {
      _isLoading = true;
      _error = null;
      _recipe = null;
      _phe = null;
      _flags = null;
    });

    // Analyze ingredients but don't add to daily tracking yet
    final result = await ApiService.analyzeIngredientsPreview(ingredients, mealType: _selectedMealType);

    if (result == null) {
      setState(() {
        _error = 'Oops! The AI did not respond. Please try again.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _recipe = result['recipe'];
      _phe = result['total_phe']?.toDouble();
      // Don't update daily total yet - wait for user approval
      
      // Convert nutrition_summary to flags map
      _flags = <String, String>{};
      if (result['nutrition_summary'] != null) {
        for (var item in result['nutrition_summary']) {
          _flags![item['ingredient']] = item['flag'];
        }
      }
      
      _isLoading = false;
    });
  }

  Future<void> _addMealToDaily() async {
    if (_phe == null || _selectedMealType == 'Unspecified') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please analyze ingredients and select a meal type first!")),
      );
      return;
    }

    // Add the meal to daily tracking
    final ingredients = _controller.text.split(',').map((e) => e.trim()).toList();
    final result = await ApiService.analyzeIngredients(ingredients, mealType: _selectedMealType);
    
    if (result != null) {
      setState(() {
        _dailyPheTotal = (result['daily_phe_total'] ?? 0.0).toDouble();
        _dailyMeals = List<Map<String, dynamic>>.from(result['daily_meals'] ?? []);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Meal added! PHE: ${_phe!.toStringAsFixed(1)}mg"),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear the form for next meal
      _controller.clear();
      setState(() {
        _recipe = null;
        _phe = null;
        _flags = null;
        _selectedMealType = 'Unspecified';
      });
    }
  }

  Future<void> _doneForTheDay() async {
    setState(() {
      _isDayComplete = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ Day completed! Total PHE: ${_dailyPheTotal.toStringAsFixed(1)} mg"),
        backgroundColor: _dailyPheTotal > 500 ? Colors.red : Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _stillHungry() async {
    final remainingPhe = 500 - _dailyPheTotal;
    final phePercentage = (_dailyPheTotal / 500 * 100);
    
    if (remainingPhe <= 0) {
      // No PHE left
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("⚠️ PHE Limit Reached"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("You've used ${phePercentage.toStringAsFixed(1)}% of your daily PHE limit."),
              SizedBox(height: 10),
              Text("Consider these PHE-free options:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("• Water, herbal teas"),
              Text("• Sugar, honey, maple syrup"),
              Text("• Some fruits (very small portions)"),
              Text("• PKU-specific low-protein products"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Got it!"),
            ),
          ],
        ),
      );
    } else {
      // Still have PHE remaining
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("🍽️ Still Hungry?"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("You have ${remainingPhe.toStringAsFixed(1)}mg PHE remaining (${(100-phePercentage).toStringAsFixed(1)}% of daily limit)."),
              SizedBox(height: 10),
              Text("Safe low-PHE options:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text("• Small apple (~30mg PHE)"),
              Text("• Banana (~49mg PHE)"),
              Text("• Berries (small portions)"),
              Text("• Rice cakes (check portions)"),
              Text("• Low-protein pasta"),
              SizedBox(height: 10),
              Text("💡 Tip: Try analyzing specific portions to stay within your limit!", 
                   style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Thanks!"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Focus on ingredient input
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Text("Analyze Food"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _savePDF() async {
    if (_dailyMeals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No meals to save! Please analyze some ingredients first.")),
      );
      return;
    }

    try {
      // Convert daily meals to AnalyzedMeal objects
      List<AnalyzedMeal> meals = _dailyMeals.map((meal) {
        return AnalyzedMeal(
          mealType: meal['meal_type'] ?? 'Unknown',
          ingredients: List<String>.from(meal['ingredients'] ?? []),
          pheAmount: (meal['phe_amount'] ?? 0.0).toDouble(),
          nutritionSummary: meal['nutrition_summary'] != null 
            ? List<Map<String, dynamic>>.from(meal['nutrition_summary'])
            : null,
          recipe: meal['recipe'],
        );
      }).toList();

      await PDFService.generateMealSummary(meals);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("📄 PDF generated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error generating PDF: $e")),
      );
    }
  }

  Future<void> _resetDay() async {
    final success = await ApiService.resetDailyTracking();
    if (success) {
      setState(() {
        _dailyPheTotal = 0.0;
        _dailyMeals = [];
        _isDayComplete = false;
        _recipe = null;
        _phe = null;
        _flags = null;
        _controller.clear();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🔄 Daily tracking reset for new day!")),
      );
    }
  }

  Color _getColor(String level) {
    switch (level.toLowerCase()) {
      case 'safe':
        return Colors.green;
      case 'caution':
        return Colors.orange;
      case 'avoid':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDailySummary() {
    final phePercentage = (_dailyPheTotal / 500 * 100).clamp(0.0, 100.0);
    final remainingPhe = (500 - _dailyPheTotal).clamp(0.0, double.infinity);
    
    return Card(
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "📊 Your Daily PHE Tracker",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.blue[600]),
                  onPressed: _resetDay,
                  tooltip: "Start New Day",
                ),
              ],
            ),
            SizedBox(height: 12),
            
            // Friendly status message
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _dailyPheTotal > 500 ? Colors.red[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _dailyPheTotal > 500 ? Colors.red[300]! : Colors.green[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _dailyPheTotal > 500 ? Icons.warning_amber : Icons.check_circle,
                    color: _dailyPheTotal > 500 ? Colors.red[700] : Colors.green[700],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dailyPheTotal > 500 
                        ? "You've exceeded your daily PHE limit. Consider PKU-safe alternatives!"
                        : remainingPhe > 100 
                          ? "Great job! You have ${remainingPhe.toStringAsFixed(0)}mg PHE remaining today."
                          : remainingPhe > 0
                            ? "Almost at your limit! ${remainingPhe.toStringAsFixed(0)}mg PHE left."
                            : "Perfect! You've reached your daily PHE target.",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _dailyPheTotal > 500 ? Colors.red[800] : Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            Text(
              "PHE Consumed: ${_dailyPheTotal.toStringAsFixed(1)} mg of 500 mg (${phePercentage.toStringAsFixed(1)}%)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _dailyPheTotal > 500 ? Colors.red[700] : Colors.blue[800],
              ),
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_dailyPheTotal / 500).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _dailyPheTotal > 500 ? Colors.red[600]! : Colors.green[600]!,
              ),
              minHeight: 8,
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Meals logged: ${_dailyMeals.length}",
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                TextButton.icon(
                  onPressed: _stillHungry,
                  icon: Icon(Icons.restaurant_menu, size: 16),
                  label: Text("Need More Food?"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                    textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red),
            SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: Colors.red)),
          ],
        ),
      );
    }
    if (_isLoading) return Center(child: CircularProgressIndicator());
    if (_recipe == null) return SizedBox.shrink();

    return Card(
      color: Colors.teal[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🍽️ Recipe", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              _recipe!, 
              style: TextStyle(fontSize: 16, color: Colors.black), // Black text for LLM output
            ),
            SizedBox(height: 10),
            Text("🧪 Estimated PHE: ${_phe?.toStringAsFixed(2)} mg", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text("🚨 Ingredients:", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _flags!.entries.map((entry) {
                return Chip(
                  label: Text(entry.key),
                  avatar: Icon(Icons.circle, color: _getColor(entry.value), size: 12),
                  backgroundColor: _getColor(entry.value).withOpacity(0.2),
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Add Meal button (only show if analysis is complete)
        if (_phe != null && _selectedMealType != 'Unspecified')
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addMealToDaily,
              icon: Icon(Icons.add_circle),
              label: Text("Add Meal to Daily Summary"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        
        if (_phe != null && _selectedMealType != 'Unspecified')
          SizedBox(height: 12),
        
        // Done for Day and Save PDF buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isDayComplete ? null : _doneForTheDay,
                icon: Icon(Icons.check_circle),
                label: Text("Done for the Day"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _savePDF,
                icon: Icon(Icons.picture_as_pdf),
                label: Text("Save me (PDF)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    String emoji;
    
    if (hour < 12) {
      greeting = "Good morning!";
      emoji = "🌅";
    } else if (hour < 17) {
      greeting = "Good afternoon!";
      emoji = "☀️";
    } else {
      greeting = "Good evening!";
      emoji = "🌙";
    }
    
    return Card(
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "$greeting Welcome to PKU Wise",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "I'm here to help you manage your PHE intake safely. Let's analyze your ingredients and create delicious PKU-friendly recipes together! 🍎✨",
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      color: Colors.purple[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.feedback, color: Colors.purple[600], size: 20),
                SizedBox(width: 8),
                Text(
                  "💬 Have feedback or questions?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("💡 Suggestions & Feedback"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("We'd love to hear from you!", style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Text("• Found the recipe helpful? 👍"),
                              Text("• Need different ingredient suggestions? 🥗"),
                              Text("• Want more PKU-safe meal ideas? 🍽️"),
                              Text("• Have questions about PHE calculations? 🧮"),
                              SizedBox(height: 10),
                              Text("Your feedback helps us improve PKU Wise for everyone in our community! 💙", 
                                   style: TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Thanks!"),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.lightbulb, size: 16),
                    label: Text("Share Ideas"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("❓ Need Help?"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Quick Tips:", style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text("🔸 Enter ingredients separated by commas"),
                              Text("🔸 Select your meal type before analyzing"),
                              Text("🔸 Green = Safe, Orange = Caution, Red = Avoid"),
                              Text("🔸 Daily limit is 500mg PHE for most adults"),
                              Text("🔸 Save your daily summary as PDF anytime"),
                              SizedBox(height: 10),
                              Text("Remember: Always consult your healthcare provider for personalized advice! 👩‍⚕️", 
                                   style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Got it!"),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: Icon(Icons.help, size: 16),
                    label: Text("Get Help"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[100],
      appBar: AppBar(
        title: Text("PKU Wise - Your PHE Assistant"),
        backgroundColor: Color(0xFF5DADE2),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (_selectedMealType == 'Unspecified') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Please select a meal type first 💡")),
              );
              return;
            } 

            if (_phe != null) {
              Navigator.of(context).pop({
                'ingredients': _controller.text,
                'phe': _phe,
                'mealType': _selectedMealType,
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Please analyze ingredients before finishing!")),
              );
            }
          },
        ),
      ), 
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Welcome Greeting
            _buildWelcomeGreeting(),
            
            SizedBox(height: 16),
            
            // Daily Summary
            _buildDailySummary(),
            
            SizedBox(height: 16),
            
            // ✅ Meal Type Dropdown
            DropdownButtonFormField<String>(
              value: _selectedMealType,
              decoration: InputDecoration(
                labelText: "🍽️ What type of meal is this?",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                helperText: "This helps us provide better recipe suggestions",
                helperStyle: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: Colors.white,
              items: _mealTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: type == 'Unspecified' ? Colors.grey[600] : Colors.black,
                      fontWeight: type == 'Unspecified' ? FontWeight.normal : FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedMealType = val!);
              },
              hint: Text(
                "Select meal type...",
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),

            SizedBox(height: 16),

            Text(
              "📝 What ingredients would you like to use?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.teal[800]),
            ),
            SizedBox(height: 8),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  hintText: "e.g. apple, banana, white rice, chicken breast",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analyzeIngredients,
              icon: _isLoading 
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(Icons.restaurant_menu),
              label: Text(_isLoading ? "Analyzing..." : "✨ Analyze & Create Recipe"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5DADE2),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(height: 20),
            _buildResults(),
            
            SizedBox(height: 20),
            _buildActionButtons(),
            
            SizedBox(height: 20),
            _buildFeedbackSection(),
          ],
        ),
      ),
    );
  }
}
