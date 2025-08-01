// lib/screens/library/library_screen.dart

import 'package:flutter/material.dart';
import 'package:pkuapp/models/food_item.dart';
import 'package:pkuapp/utils/food_service.dart';
import 'package:pkuapp/services/library_service.dart';
import 'package:pkuapp/screens/library/recipe_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  List<FoodItem> _foodResults = [];
  List<FoodItem> _favoriteFoods = [];
  bool _isLoadingFoods = true;
  bool _isLoadingFavorites = true;

  // --- NEW: State variables for multi-selection ---
  bool _isSelectionMode = false;
  final List<FoodItem> _selectedFoods = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadInitialFoods();
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialFoods() async {
    if (!mounted) return;
    setState(() => _isLoadingFoods = true);
    try {
      final response = await Supabase.instance.client
          .from('foods')
          .select()
          .order('name', ascending: true)
          .limit(50);

      if (mounted) {
        setState(() {
          _foodResults = response.map((item) => FoodItem.fromJson(item)).toList();
          _isLoadingFoods = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFoods = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading foods: $e')));
      }
    }
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
    if (query.isEmpty) {
      _loadInitialFoods();
      return;
    }
    if (query.length < 3) return;

    if(mounted) setState(() => _isLoadingFoods = true);
    final results = await _foodService.searchFoods(query);
    if(mounted) {
      setState(() {
        _foodResults = results;
        _isLoadingFoods = false;
      });
    }
  }

  // --- UPDATED: Tap and selection logic ---

  void _onFoodTapped(FoodItem food) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedFoods.contains(food)) {
          _selectedFoods.remove(food);
          if (_selectedFoods.isEmpty) {
            _isSelectionMode = false;
          }
        } else {
          _selectedFoods.add(food);
        }
      });
    } else {
      // For single selection, return a list containing just one item
      Navigator.of(context).pop([food]);
    }
  }

  void _onItemLongPress(FoodItem food) {
    if (!_isSelectionMode) {
      setState(() {
        _isSelectionMode = true;
        _selectedFoods.add(food);
      });
    }
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedFoods.clear();
    });
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_selectedFoods);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text('${_selectedFoods.length} selected'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelSelection,
              ),
            )
          : AppBar(
              title: const Text('Add Food'),
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
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _confirmSelection,
              label: const Text('Add Selected'),
              icon: const Icon(Icons.check),
            )
          : null,
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
              hintText: 'Search foods...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withAlpha(100),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoadingFoods
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _foodResults.length,
                  itemBuilder: (context, index) {
                    final food = _foodResults[index];
                    final isFavorite = _favoriteFoods.any((fav) => fav.fdcId == food.fdcId);
                    return _buildFoodItemCard(food, isFavorite);
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
      return Center(
        child: Text('You haven\'t saved any foods yet.', style: TextStyle(color: Colors.grey.shade600)),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        itemCount: _favoriteFoods.length,
        itemBuilder: (context, index) {
          final food = _favoriteFoods[index];
          return _buildFoodItemCard(food, true);
        },
      ),
    );
  }

  Widget _buildFoodItemCard(FoodItem food, bool isFavorite) {
    final isSelected = _selectedFoods.contains(food);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onFoodTapped(food),
        onLongPress: () => _onItemLongPress(food),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(food.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      '${food.proteinG.toStringAsFixed(1)}g Protein / 100g',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.check_circle, color: Colors.green),
                ),
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: 'Get Recipes',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RecipeScreen(foodName: food.name),
                    ),
                  );
                },
              ),
              IconButton(
                icon: isFavorite
                    ? Icon(Icons.favorite, color: Theme.of(context).colorScheme.primary)
                    : const Icon(Icons.favorite_border),
                tooltip: isFavorite ? 'Remove from Library' : 'Save to Library',
                onPressed: () async {
                  if (isFavorite) {
                    await _libraryService.removeFavorite(food.fdcId);
                  } else {
                    await _libraryService.addFavorite(food);
                  }
                  _loadFavorites();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}