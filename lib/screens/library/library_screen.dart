// lib/screens/library/library_screen.dart

import 'package:flutter/material.dart';
import 'package:pkuapp/models/food_item.dart';
import 'package:pkuapp/utils/food_service.dart';
import 'package:pkuapp/services/library_service.dart';
import 'package:pkuapp/screens/library/recipe_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  final _foodService = FoodService();
  final _libraryService = LibraryService();

  List<FoodItem> _searchResults = [];
  List<FoodItem> _favoriteFoods = [];
  bool _isLoadingSearch = false;
  bool _isLoadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() => _isLoadingFavorites = true);
    final favorites = await _libraryService.getFavoriteFoods();
    if (mounted) {
      setState(() {
        _favoriteFoods = favorites;
        _isLoadingFavorites = false;
      });
    }
  }

  void _onSearchChanged(String query) async {
    if (query.length < 3) {
      if(mounted) setState(() => _searchResults = []);
      return;
    }
    if(mounted) setState(() => _isLoadingSearch = true);
    final results = await _foodService.searchFoods(query);
    if(mounted) {
      setState(() {
        _searchResults = results;
        _isLoadingSearch = false;
      });
    }
  }

  void _onFoodTapped(FoodItem food) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeScreen(foodName: food.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Food Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.search), text: 'Search All Foods'),
            Tab(icon: Icon(Icons.favorite), text: 'My Library'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSearchTab(),
          _buildFavoritesTab(),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              labelText: 'Search Supabase & Open Food Facts...',
              suffixIcon: _isLoadingSearch ? const CircularProgressIndicator() : const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingSearch
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final food = _searchResults[index];
                    return ListTile(
                      title: Text(food.name),
                      subtitle: Text('${food.proteinG.toStringAsFixed(1)}g Protein / 100g'),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.grey),
                        tooltip: 'Save to Library',
                        onPressed: () async {
                          await _libraryService.addFavorite(food);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${food.name} saved!'), backgroundColor: Colors.green),
                          );
                          _loadFavorites();
                        },
                      ),
                      onTap: () => _onFoodTapped(food),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() {
    if (_isLoadingFavorites) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favoriteFoods.isEmpty) {
      return const Center(child: Text('You haven\'t saved any foods yet.'));
    }
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        itemCount: _favoriteFoods.length,
        itemBuilder: (context, index) {
          final food = _favoriteFoods[index];
          return ListTile(
            title: Text(food.name),
            subtitle: Text('${food.proteinG.toStringAsFixed(1)}g Protein / 100g'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Remove from Library',
              onPressed: () async {
                await _libraryService.removeFavorite(food.fdcId);
                _loadFavorites();
              },
            ),
            onTap: () => _onFoodTapped(food),
          );
        },
      ),
    );
  }
}