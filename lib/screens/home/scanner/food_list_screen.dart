import 'package:flutter/material.dart';
import 'package:pkuapp/screens/home/scanner/analyze_screen.dart';
import 'package:pkuapp/screens/home/scanner/models/food_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodListScreen extends StatefulWidget {
  final String title;

  const FoodListScreen({super.key, required this.title});

  @override
  State<FoodListScreen> createState() => _FoodListScreenState();
}

class _FoodListScreenState extends State<FoodListScreen> {
  List<FoodItem> foodList = [], filteredFoodList = [];
  final searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFoods();
  }

  Future<void> fetchFoods() async {
    final rows = await Supabase.instance.client.from('foods').select().limit(1000);
    setState(() {
      foodList = rows.map(FoodItem.fromMap).toList();
      filteredFoodList = foodList;
      isLoading = false;
    });
  }

  List<FoodItem> _filterFoods(String query) {
    final lowerQuery = query.toLowerCase();
    final exactMatches = foodList.where((food) =>
        food.name.toLowerCase().startsWith(lowerQuery));
    final categoryBoosted = foodList.where((food) =>
        food.category != null &&
        food.category!.toLowerCase().contains("fruit") &&
        food.name.toLowerCase().contains(lowerQuery));
    final generalMatches = foodList.where((food) =>
        food.name.toLowerCase().contains(lowerQuery));

    final combined = {...exactMatches, ...categoryBoosted, ...generalMatches}.toList();
    return combined;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Food List')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search Food',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        filteredFoodList = _filterFoods(value);
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredFoodList.length,
                    itemBuilder: (context, index) {
                      final food = filteredFoodList[index];
                      return ListTile(
                        title: Text(food.name),
                        subtitle: Text(food.category ?? 'Unknown'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AnalyzeScreen(food: food),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}