// lib/screens/home/log_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:pkuapp/models/food_item.dart';
import 'package:pkuapp/screens/library/library_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pkuapp/screens/home/chat/conversation_list.dart';

class LogDashboardScreen extends StatefulWidget {
  const LogDashboardScreen({super.key});

  @override
  State<LogDashboardScreen> createState() => _LogDashboardScreenState();
}

class _LogDashboardScreenState extends State<LogDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _todaysLogs = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final logsResponse = await Supabase.instance.client
          .from('food_logs')
          .select()
          .eq('user_id', userId)
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);

      if (mounted) {
        setState(() {
          _profile = profileResponse;
          _todaysLogs = List<Map<String, dynamic>>.from(logsResponse);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching data: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteFoodLog(int logId) async {
    try {
      await Supabase.instance.client.from('food_logs').delete().eq('id', logId);
      _fetchDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting log: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showLogFoodDialog(FoodItem food, String mealType) async {
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Log ${food.name}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quantity', suffixText: 'grams'),
              validator: (value) {
                if (value == null || value.isEmpty || double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Log Food'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final quantity = double.parse(quantityController.text);
                  final scale = quantity / 100.0;
                  final pheForPortion = food.pheMg * scale;
                  final proteinForPortion = food.proteinG * scale;
                  final caloriesForPortion = (food.energyKcal ?? 0) * scale;

                  try {
                    await Supabase.instance.client.from('food_logs').insert({
                      'meal_type': mealType,
                      'food_name': food.name,
                      'quantity_g': quantity,
                      'phe_mg': pheForPortion,
                      'protein_g': proteinForPortion,
                      'calories_kcal': caloriesForPortion,
                    });

                    if (mounted) {
                      Navigator.of(context).pop();
                      _fetchDashboardData();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error logging food: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- CALCULATE ALL VALUES ---
    final double totalPhe = (_profile?['phe_tolerance_mg'] as num?)?.toDouble() ?? 700.0;
    final double currentPhe = _todaysLogs.fold(0.0, (sum, log) => sum + ((log['phe_mg'] as num?)?.toDouble() ?? 0.0));
    final double totalProtein = (_profile?['protein_goal_g'] as num?)?.toDouble() ?? 100.0;
    final double currentProtein = _todaysLogs.fold(0.0, (sum, log) => sum + ((log['protein_g'] as num?)?.toDouble() ?? 0.0));
    final double totalCalories = (_profile?['daily_calorie_target'] as num?)?.toDouble() ?? 2000.0;
    final double currentCalories = _todaysLogs.fold(0.0, (sum, log) => sum + ((log['calories_kcal'] as num?)?.toDouble() ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          tooltip: 'AI Chat',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const ConversationListScreen()),
            );
          },
        ),
        title: const Text('Today\'s Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () { /* TODO: Implement date picker */ },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: ListView(
          children: [
            const SizedBox(height: 20),
            _buildDailyProgressHeader(context, currentPhe, totalPhe),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  _buildMacroBar(
                    title: 'Protein',
                    currentValue: currentProtein,
                    goalValue: totalProtein,
                    unit: 'g',
                    color: const Color(0xFF26A69A), // Teal
                  ),
                  const SizedBox(height: 16),
                  _buildMacroBar(
                    title: 'Calories',
                    currentValue: currentCalories,
                    goalValue: totalCalories,
                    unit: 'kcal',
                    color: const Color(0xFFFFA726), // Orange
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildMealCard(context, 'Breakfast'),
            _buildMealCard(context, 'Lunch'),
            _buildMealCard(context, 'Dinner'),
            _buildMealCard(context, 'Snacks'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyProgressHeader(BuildContext context, double current, double total) {
    final percent = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    final theme = Theme.of(context);
    return CircularPercentIndicator(
      radius: 90.0,
      lineWidth: 15.0,
      percent: percent,
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            (total - current).toStringAsFixed(0),
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text("mg Left"),
        ],
      ),
      progressColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      circularStrokeCap: CircularStrokeCap.round,
    );
  }

  Widget _buildMacroBar({
    required String title,
    required double currentValue,
    required double goalValue,
    required String unit,
    required Color color,
  }) {
    final percent = goalValue > 0 ? (currentValue / goalValue).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${currentValue.toStringAsFixed(0)} / ${goalValue.toStringAsFixed(0)} $unit'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          minHeight: 10,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(5),
        ),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, String title) {
  final theme = Theme.of(context);
  final mealLogs = _todaysLogs.where((log) => log['meal_type'] == title).toList();
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    elevation: 2,
    shadowColor: Colors.black.withAlpha(25),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              IconButton(
                icon: Icon(Icons.add_circle, color: theme.colorScheme.primary, size: 30),
                // --- THIS IS THE UPDATED PART ---
                onPressed: () async {
                  // Now expect a LIST of FoodItems back from the LibraryScreen
                  final selectedFoods = await Navigator.of(context).push<List<FoodItem>>(
                    MaterialPageRoute(builder: (ctx) => const LibraryScreen()),
                  );

                  // If the user selected one or more foods, process them
                  if (selectedFoods != null && selectedFoods.isNotEmpty && mounted) {
                    // Loop through each selected food and show the dialog
                    for (final food in selectedFoods) {
                      // await here ensures dialogs appear one after another
                      await _showLogFoodDialog(food, title);
                    }
                  }
                },
                // -----------------------------
              ),
            ],
          ),
          const Divider(),
          if (mealLogs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'You haven\'t logged any food yet.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mealLogs.length,
              itemBuilder: (context, index) {
                final log = mealLogs[index];
                final logId = log['id'] as int;
                return Dismissible(
                  key: ValueKey(logId),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteFoodLog(logId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${log['food_name']} removed.')),
                    );
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(log['food_name']),
                    subtitle: Text('${(log['quantity_g'] as num).toStringAsFixed(0)}g'),
                    trailing: Text('${(log['phe_mg'] as num).toStringAsFixed(0)} mg PHE'),
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
}
}