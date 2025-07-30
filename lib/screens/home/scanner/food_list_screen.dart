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


// import 'package:flutter/material.dart';
// import 'package:pkuapp/screens/home/scanner/models/FoodItem_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';


// class FoodItemListScreen extends StatefulWidget {
//   final String title;

//   const FoodItemListScreen({super.key, required this.title});

//   @override
//   State<FoodItemListScreen> createState() => _FoodItemListScreenState();
// }

// class _FoodItemListScreenState extends State<FoodItemListScreen> {

//   List<FoodItemItem> FoodItemList = [], filteredFoodItemList = [];
//   final searchController = TextEditingController();
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchFoodItems();
//   }

//   Future<void> fetchFoodItems() async {
//     final rows = await Supabase.instance.client
//         .from('FoodItems')
//         .select()
//         .limit(100);

//         setState(() {
//           FoodItemList = rows.map(FoodItemItem.fromMap).toList();
//           filteredFoodItemList = FoodItemList;
//           isLoading = false;
//         });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar( title: const Text('FoodItem List') ),
//       body: isLoading
//       ? const Center(child: CircularProgressIndicator())
//       : Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: TextField(
//               controller: searchController,
//               decoration: const InputDecoration(
//                 hintText: 'Search FoodItem',
//                 prefixIcon: Icon(Icons.search),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   filteredFoodItemList = FoodItemList.where((FoodItem) {
//                     final FoodItemName = FoodItem.name.toLowerCase() ?? '';
//                     return FoodItemName.contains(value.toLowerCase());
//                   }).toList();
//                 });
//               },
//             )
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: filteredFoodItemList.length,
//               itemBuilder: (_, i ) {
//                 final FoodItem = filteredFoodItemList[i];
//                 return ListTile(
//                   title: Text(FoodItem.name ?? 'Unknown FoodItem'),
//                   subtitle: Text(
//                     '${FoodItem.category} • ${FoodItem.proteinG} g protein,'
//                     '${FoodItem.carbsG} g carbs, ${FoodItem.energyKcal} Kcal'),
//                     // '${FoodItem.category} * ${FoodItem['protein_g']} g protein, ${FoodItem['carbohydrates_g']} g carbs'),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }