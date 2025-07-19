import 'package:flutter/material.dart';
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
    final rows = await Supabase.instance.client
        .from('foods')
        .select()
        .limit(100);

        setState(() {
          foodList = rows.map(FoodItem.fromMap).toList();
          filteredFoodList = foodList;
          isLoading = false;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: const Text('Food List') ),
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
                  filteredFoodList = foodList.where((food) {
                    final foodName = food.name.toLowerCase() ?? '';
                    return foodName.contains(value.toLowerCase());
                  }).toList();
                });
              },
            )
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFoodList.length,
              itemBuilder: (_, i ) {
                final food = filteredFoodList[i];
                return ListTile(
                  title: Text(food.name ?? 'Unknown Food'),
                  subtitle: Text(
                    '${food.category} • ${food.proteinG} g protein,'
                    '${food.carbsG} g carbs, ${food.energyKcal} Kcal'),
                    // '${food.category} * ${food['protein_g']} g protein, ${food['carbohydrates_g']} g carbs'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}