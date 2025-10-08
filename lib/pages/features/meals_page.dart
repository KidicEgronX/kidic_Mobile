import 'package:flutter/material.dart';
import 'package:kidicapp_flutter/models/meal_model.dart';
import 'package:kidicapp_flutter/services/child/meal_service.dart';
import 'package:kidicapp_flutter/services/child/child_service.dart';

class MealsPage extends StatefulWidget {
  final int? initialChildId;

  const MealsPage({super.key, this.initialChildId});

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> with TickerProviderStateMixin {
  final MealService _mealService = MealService();
  final ChildService _childService = ChildService();

  List<Map<String, dynamic>> _children = [];
  List<Meal> _meals = [];
  List<Meal> _filteredMeals = [];
  int? _selectedChildId;
  String _selectedChild = '';
  bool _isLoading = true;
  String _searchQuery = '';

  // Filter states
  FoodType? _selectedFoodType;
  NutritionCategory? _selectedNutritionCategory;
  String? _selectedAgeGroup;

  // Tab controller for categories
  late TabController _tabController;

  // Category tabs
  final List<Tab> _categoryTabs = [
    const Tab(text: 'All'),
    const Tab(text: '🌅 Breakfast'),
    const Tab(text: '🌞 Lunch'),
    const Tab(text: '🌙 Dinner'),
    const Tab(text: '🍎 Snacks'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categoryTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadChildren();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFoodType = null;
            break;
          case 1:
            _selectedFoodType = FoodType.breakfast;
            break;
          case 2:
            _selectedFoodType = FoodType.lunch;
            break;
          case 3:
            _selectedFoodType = FoodType.dinner;
            break;
          case 4:
            _selectedFoodType = FoodType.snack;
            break;
        }
        _applyFilters();
      });
    }
  }

  Future<void> _loadChildren() async {
    try {
      final children = await _childService.getAllChildren();
      setState(() {
        _children = children;
        if (widget.initialChildId != null) {
          _selectedChildId = widget.initialChildId;
          final child = children.firstWhere(
            (c) => c['id'] == widget.initialChildId,
            orElse: () => children.first,
          );
          _selectedChild = child['name'] ?? 'Unknown';
        } else if (children.isNotEmpty) {
          _selectedChildId = children.first['id'];
          _selectedChild = children.first['name'] ?? 'Unknown';
        }
      });

      if (_selectedChildId != null) {
        await _loadMealsForChild(_selectedChildId!);
      }
    } catch (e) {
      debugPrint('Error loading children: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMealsForChild(int childId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final meals = await _mealService.getMealsForChild(childId);
      setState(() {
        _meals = meals;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading meals: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Meal> filtered = List.from(_meals);

    // Apply food type filter
    if (_selectedFoodType != null) {
      filtered = _mealService.filterMealsByFoodType(
        filtered,
        _selectedFoodType!,
      );
    }

    // Apply nutrition category filter
    if (_selectedNutritionCategory != null) {
      filtered = _mealService.filterMealsByNutrition(
        filtered,
        _selectedNutritionCategory!,
      );
    }

    // Apply age group filter
    if (_selectedAgeGroup != null) {
      filtered = _mealService.filterMealsByAgeGroup(
        filtered,
        _selectedAgeGroup!,
      );
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = _mealService.searchMeals(filtered, _searchQuery);
    }

    setState(() {
      _filteredMeals = filtered;
    });
  }

  void _onChildChanged(int? childId) {
    if (childId != null && childId != _selectedChildId) {
      final child = _children.firstWhere((c) => c['id'] == childId);
      setState(() {
        _selectedChildId = childId;
        _selectedChild = child['name'] ?? 'Unknown';
      });
      _loadMealsForChild(childId);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Header with child selector
            _buildHeader(),

            // Search bar
            _buildSearchBar(),

            // Filter chips
            _buildFilterChips(),

            // Category tabs
            _buildCategoryTabs(),

            // Meals list
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildMealsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedChildId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMealDialog(),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Meal'),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.restaurant_menu, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Meals & Nutrition',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          // Child selector - better placement
          if (_children.length > 1) ...[
            const SizedBox(height: 16),
            const Text(
              'Select Child',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            _buildChildSelector(),
          ] else if (_selectedChild.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Meals for $_selectedChild',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChildSelector() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _children.length,
        itemBuilder: (context, index) {
          final child = _children[index];
          final childId = child['id'];
          final childName = child['name'] ?? 'Unknown';
          final isSelected = childId == _selectedChildId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isSelected
                        ? Colors.white
                        : Colors.blue.shade100,
                    child: Text(
                      childName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.blue.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(childName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onChildChanged(childId);
                }
              },
              selectedColor: Colors.blue.shade100,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade800 : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.blue.shade300 : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search meals or ingredients...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Nutrition category filters
            ...NutritionCategory.values.map((category) {
              final isSelected = _selectedNutritionCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    '${category.icon} ${category.displayName}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedNutritionCategory = selected ? category : null;
                      _applyFilters();
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: Color(
                    int.parse('FF${category.color.substring(1)}', radix: 16),
                  ),
                  checkmarkColor: Colors.white,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.blue.shade600,
        indicatorWeight: 3,
        labelColor: Colors.blue.shade600,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        tabs: _categoryTabs,
      ),
    );
  }

  Widget _buildMealsList() {
    if (_filteredMeals.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredMeals.length,
      itemBuilder: (context, index) {
        final meal = _filteredMeals[index];
        return _buildMealCard(meal);
      },
    );
  }

  Widget _buildMealCard(Meal meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Food type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meal.foodType?.icon ?? '🍽️',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),

                // Meal info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (meal.foodType != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          meal.foodType!.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditMealDialog(meal);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(meal);
                    }
                  },
                ),
              ],
            ),
          ),

          // Nutrition categories
          if (meal.nutritionCategories != null &&
              meal.nutritionCategories!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: meal.nutritionCategories!.map((category) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(
                          'FF${category.color.substring(1)}',
                          radix: 16,
                        ),
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(
                          int.parse(
                            'FF${category.color.substring(1)}',
                            radix: 16,
                          ),
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${category.icon} ${category.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(
                          int.parse(
                            'FF${category.color.substring(1)}',
                            radix: 16,
                          ),
                        ),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Ingredients
          if (meal.ingredients != null && meal.ingredients!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingredients:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.ingredients!.join(', '),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Recipe
          if (meal.recipe != null && meal.recipe!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recipe:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meal.recipe!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading meals...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No meals found' : 'No meals yet',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Add your first meal for $_selectedChild',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (_selectedChildId != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddMealDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add First Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddMealDialog() {
    if (_selectedChildId == null) return;

    _showMealDialog(
      title: 'Add New Meal',
      onSave:
          (title, ingredients, recipe, foodType, nutritionCategories) async {
            final meal = await _mealService.addMealForChild(
              childId: _selectedChildId!,
              title: title,
              ingredients: ingredients,
              recipe: recipe,
              foodType: foodType,
              nutritionCategories: nutritionCategories,
            );

            if (meal != null) {
              setState(() {
                _meals.add(meal);
                _applyFilters();
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Meal "${meal.title}" added successfully!'),
                    backgroundColor: Colors.green.shade600,
                  ),
                );
              }
            }
          },
    );
  }

  void _showEditMealDialog(Meal meal) {
    _showMealDialog(
      title: 'Edit Meal',
      initialTitle: meal.title,
      initialIngredients: meal.ingredients,
      initialRecipe: meal.recipe,
      initialFoodType: meal.foodType,
      initialNutritionCategories: meal.nutritionCategories,
      onSave:
          (title, ingredients, recipe, foodType, nutritionCategories) async {
            final updatedMeal = await _mealService.updateMealForChild(
              childId: meal.childId,
              mealId: meal.id!,
              title: title,
              ingredients: ingredients,
              recipe: recipe,
              foodType: foodType,
              nutritionCategories: nutritionCategories,
            );

            if (updatedMeal != null) {
              setState(() {
                final index = _meals.indexWhere((m) => m.id == meal.id);
                if (index != -1) {
                  _meals[index] = updatedMeal;
                  _applyFilters();
                }
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Meal "${updatedMeal.title}" updated successfully!',
                    ),
                    backgroundColor: Colors.blue.shade600,
                  ),
                );
              }
            }
          },
    );
  }

  void _showMealDialog({
    required String title,
    String? initialTitle,
    List<String>? initialIngredients,
    String? initialRecipe,
    FoodType? initialFoodType,
    List<NutritionCategory>? initialNutritionCategories,
    required Future<void> Function(
      String title,
      List<String>? ingredients,
      String? recipe,
      FoodType? foodType,
      List<NutritionCategory>? nutritionCategories,
    )
    onSave,
  }) {
    final titleController = TextEditingController(text: initialTitle ?? '');
    final ingredientsController = TextEditingController(
      text: initialIngredients?.join(', ') ?? '',
    );
    final recipeController = TextEditingController(text: initialRecipe ?? '');

    FoodType? selectedFoodType = initialFoodType;
    List<NutritionCategory> selectedNutritionCategories = List.from(
      initialNutritionCategories ?? [],
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meal Name
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Meal Name *',
                      hintText: 'e.g., Scrambled Eggs',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),

                  // Food Type Selection
                  const Text(
                    'Meal Type:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: FoodType.values.map((foodType) {
                      final isSelected = selectedFoodType == foodType;
                      return FilterChip(
                        label: Text('${foodType.icon} ${foodType.displayName}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            selectedFoodType = selected ? foodType : null;
                          });
                        },
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: Colors.blue.shade100,
                        checkmarkColor: Colors.blue.shade700,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Nutrition Categories Selection
                  const Text(
                    'Nutrition Categories:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: NutritionCategory.values.map((category) {
                      final isSelected = selectedNutritionCategories.contains(
                        category,
                      );
                      return FilterChip(
                        label: Text('${category.icon} ${category.displayName}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedNutritionCategories.add(category);
                            } else {
                              selectedNutritionCategories.remove(category);
                            }
                          });
                        },
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: Color(
                          int.parse(
                            'FF${category.color.substring(1)}',
                            radix: 16,
                          ),
                        ).withOpacity(0.2),
                        checkmarkColor: Color(
                          int.parse(
                            'FF${category.color.substring(1)}',
                            radix: 16,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Ingredients
                  TextField(
                    controller: ingredientsController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients (optional)',
                      hintText:
                          'e.g., Eggs, Milk, Butter (separate with commas)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Recipe
                  TextField(
                    controller: recipeController,
                    decoration: const InputDecoration(
                      labelText: 'Recipe Instructions (optional)',
                      hintText: 'How to prepare this meal...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final mealTitle = titleController.text.trim();
                if (mealTitle.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a meal name'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final ingredients = ingredientsController.text.trim().isNotEmpty
                    ? ingredientsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList()
                    : null;

                final recipe = recipeController.text.trim().isNotEmpty
                    ? recipeController.text.trim()
                    : null;

                Navigator.pop(context);
                await onSave(
                  mealTitle,
                  ingredients,
                  recipe,
                  selectedFoodType,
                  selectedNutritionCategories.isNotEmpty
                      ? selectedNutritionCategories
                      : null,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Meal meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await _mealService.deleteMealForChild(
                childId: meal.childId,
                mealId: meal.id!,
              );

              if (success) {
                setState(() {
                  _meals.removeWhere((m) => m.id == meal.id);
                  _applyFilters();
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Meal "${meal.title}" deleted successfully!',
                      ),
                      backgroundColor: Colors.red.shade600,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to delete meal'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
