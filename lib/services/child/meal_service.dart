import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidicapp_flutter/services/auth/auth_service.dart';
import 'package:kidicapp_flutter/models/meal_model.dart';

class MealService {
  final AuthService _authService = AuthService();

  // Backend URL - matches the MealController pattern
  // Android Emulator: http://10.0.2.2:8080/api/meals
  // iOS Simulator/Web: http://localhost:8080/api/meals
  // Physical Device/Network: http://192.168.1.4:8080/api/meals
  static const String _baseUrl = 'http://10.0.2.2:8080/api/meals';

  // Client-side category storage keys
  static const String _mealCategoriesKey = 'meal_categories_';

  /// Save meal categories locally (client-side only)
  Future<void> _saveMealCategories(
    int mealId,
    FoodType? foodType,
    List<NutritionCategory>? nutritionCategories,
  ) async {
    if (foodType == null &&
        (nutritionCategories == null || nutritionCategories.isEmpty))
      return;

    final prefs = await SharedPreferences.getInstance();
    final categoryData = {
      'foodType': foodType?.name,
      'nutritionCategories': nutritionCategories?.map((e) => e.name).toList(),
    };
    await prefs.setString(
      '${_mealCategoriesKey}$mealId',
      json.encode(categoryData),
    );
    debugPrint(
      '📁 Saved categories for meal $mealId: ${json.encode(categoryData)}',
    );
  }

  /// Load meal categories from local storage
  Future<Map<String, dynamic>?> _loadMealCategories(int mealId) async {
    final prefs = await SharedPreferences.getInstance();
    final categoryJson = prefs.getString('${_mealCategoriesKey}$mealId');
    if (categoryJson != null) {
      debugPrint('📂 Loaded categories for meal $mealId: $categoryJson');
      return json.decode(categoryJson);
    }
    debugPrint('📭 No categories found for meal $mealId');
    return null;
  }

  /// Get all meals for a specific child
  /// This calls GET /api/meals/children/{childId} endpoint
  Future<List<Meal>> getMealsForChild(int childId) async {
    try {
      debugPrint(
        '🍽️ === CALLING GET /api/meals/children/$childId ENDPOINT ===',
      );

      // Get JWT token for authentication
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No authentication token found');
        return [];
      }

      // Prepare the request URL
      final url = '$_baseUrl/children/$childId';
      debugPrint('🍽️ URL: $url');
      debugPrint('🍽️ Authorization: Bearer ${token.substring(0, 20)}...');

      // Make HTTP GET request to Java Spring Boot backend
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📥 === API RESPONSE FROM GET /api/meals/children/$childId ===',
      );
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final meals = <Meal>[];

        for (final mealJson in jsonData) {
          final mealMap = mealJson as Map<String, dynamic>;
          // Add childId to each meal since the backend might not include it
          mealMap['childId'] = childId;

          final meal = Meal.fromJson(mealMap);

          // Load client-side categories if meal has an ID
          if (meal.id != null) {
            final categoryData = await _loadMealCategories(meal.id!);
            if (categoryData != null) {
              // Add categories from local storage
              if (categoryData['foodType'] != null) {
                mealMap['foodType'] = categoryData['foodType'];
              }
              if (categoryData['nutritionCategories'] != null) {
                mealMap['nutritionCategories'] =
                    categoryData['nutritionCategories'];
              }
              // Create meal with categories
              meals.add(Meal.fromJson(mealMap));
            } else {
              meals.add(meal);
            }
          } else {
            meals.add(meal);
          }
        }

        debugPrint(
          '✅ Successfully loaded ${meals.length} meals for child $childId (with local categories)',
        );
        return meals;
      } else {
        debugPrint('❌ Failed to load meals. Status: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error getting meals for child: $e');
      return [];
    }
  }

  /// Add a new meal for a specific child
  /// This calls POST /api/meals/children/{childId} endpoint
  Future<Meal?> addMealForChild({
    required int childId,
    required String title,
    List<String>? ingredients,
    String? recipe,
    FoodType? foodType,
    List<NutritionCategory>? nutritionCategories,
  }) async {
    try {
      debugPrint(
        '🍽️ === CALLING POST /api/meals/children/$childId ENDPOINT ===',
      );

      // Get JWT token for authentication
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No authentication token found');
        return null;
      }

      // Prepare the request URL and body
      final url = '$_baseUrl/children/$childId';
      final ingredientsCsv = ingredients?.join(',') ?? '';

      debugPrint('🍽️ URL: $url');
      debugPrint('🍽️ Title: $title');
      debugPrint('🍽️ Ingredients: $ingredientsCsv');
      debugPrint('🍽️ Recipe: ${recipe ?? 'No recipe'}');
      debugPrint('🍽️ Food Type: ${foodType?.name ?? 'None'}');
      debugPrint(
        '🍽️ Nutrition Categories: ${nutritionCategories?.map((e) => e.name).join(', ') ?? 'None'}',
      );

      // Create form data (backend only supports title, ingredients, recipe)
      final requestBody = {
        'title': title,
        if (ingredients != null && ingredients.isNotEmpty)
          'ingredients': ingredientsCsv,
        if (recipe != null && recipe.isNotEmpty) 'recipe': recipe,
        // NOTE: foodType and nutritionCategories are stored client-side only
        // Backend doesn't support these fields yet
      };

      // Make HTTP POST request to Java Spring Boot backend
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📥 === API RESPONSE FROM POST /api/meals/children/$childId ===',
      );
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Raw Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        // Add childId to the JSON since the backend might not include it
        jsonData['childId'] = childId;
        final meal = Meal.fromJson(jsonData);

        // Save categories locally if meal has ID and categories were provided
        if (meal.id != null &&
            (foodType != null ||
                (nutritionCategories != null &&
                    nutritionCategories.isNotEmpty))) {
          await _saveMealCategories(meal.id!, foodType, nutritionCategories);

          // Update the meal object to include categories
          if (foodType != null) jsonData['foodType'] = foodType.name;
          if (nutritionCategories != null && nutritionCategories.isNotEmpty) {
            jsonData['nutritionCategories'] = nutritionCategories
                .map((e) => e.name)
                .toList();
          }

          final mealWithCategories = Meal.fromJson(jsonData);
          debugPrint(
            '✅ Successfully created meal with categories: ${mealWithCategories.title}',
          );
          return mealWithCategories;
        }

        debugPrint('✅ Successfully created meal: ${meal.title}');
        return meal;
      } else {
        debugPrint('❌ Failed to create meal. Status: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error creating meal for child: $e');
      return null;
    }
  }

  /// Update an existing meal for a specific child
  /// This calls PUT /api/meals/children/{childId}/{mealId} endpoint
  Future<Meal?> updateMealForChild({
    required int childId,
    required int mealId,
    String? title,
    List<String>? ingredients,
    String? recipe,
    FoodType? foodType,
    List<NutritionCategory>? nutritionCategories,
  }) async {
    try {
      debugPrint(
        '🍽️ === CALLING PUT /api/meals/children/$childId/$mealId ENDPOINT ===',
      );

      // Get JWT token for authentication
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No authentication token found');
        return null;
      }

      // Prepare the request URL and body
      final url = '$_baseUrl/children/$childId/$mealId';
      final ingredientsCsv = ingredients?.join(',') ?? '';

      debugPrint('🍽️ URL: $url');
      debugPrint('🍽️ Title: ${title ?? 'Not updating'}');
      debugPrint(
        '🍽️ Ingredients: ${ingredients != null ? ingredientsCsv : 'Not updating'}',
      );
      debugPrint('🍽️ Recipe: ${recipe ?? 'Not updating'}');
      debugPrint('🍽️ Food Type: ${foodType?.name ?? 'Not updating'}');
      debugPrint(
        '🍽️ Nutrition Categories: ${nutritionCategories?.map((e) => e.name).join(', ') ?? 'Not updating'}',
      );

      // Create form data (backend only supports title, ingredients, recipe)
      final requestBody = <String, String>{};
      if (title != null) requestBody['title'] = title;
      if (ingredients != null) requestBody['ingredients'] = ingredientsCsv;
      if (recipe != null) requestBody['recipe'] = recipe;
      // NOTE: foodType and nutritionCategories are stored client-side only
      // Backend doesn't support these fields yet

      // Make HTTP PUT request to Java Spring Boot backend
      final response = await http
          .put(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📥 === API RESPONSE FROM PUT /api/meals/children/$childId/$mealId ===',
      );
      debugPrint('📥 Response Status: ${response.statusCode}');
      debugPrint('📥 Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        // Add childId to the JSON since the backend might not include it
        jsonData['childId'] = childId;

        // Save/update categories locally if provided
        if (foodType != null ||
            (nutritionCategories != null && nutritionCategories.isNotEmpty)) {
          await _saveMealCategories(mealId, foodType, nutritionCategories);

          // Update the meal object to include categories
          if (foodType != null) jsonData['foodType'] = foodType.name;
          if (nutritionCategories != null && nutritionCategories.isNotEmpty) {
            jsonData['nutritionCategories'] = nutritionCategories
                .map((e) => e.name)
                .toList();
          }
        } else {
          // Load existing categories if none provided
          final existingCategories = await _loadMealCategories(mealId);
          if (existingCategories != null) {
            if (existingCategories['foodType'] != null) {
              jsonData['foodType'] = existingCategories['foodType'];
            }
            if (existingCategories['nutritionCategories'] != null) {
              jsonData['nutritionCategories'] =
                  existingCategories['nutritionCategories'];
            }
          }
        }

        final meal = Meal.fromJson(jsonData);
        debugPrint('✅ Successfully updated meal: ${meal.title}');
        return meal;
      } else {
        debugPrint('❌ Failed to update meal. Status: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error updating meal for child: $e');
      return null;
    }
  }

  /// Delete a meal for a specific child
  /// This calls DELETE /api/meals/children/{childId}/{mealId} endpoint
  Future<bool> deleteMealForChild({
    required int childId,
    required int mealId,
  }) async {
    try {
      debugPrint(
        '🍽️ === CALLING DELETE /api/meals/children/$childId/$mealId ENDPOINT ===',
      );

      // Get JWT token for authentication
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('❌ No authentication token found');
        return false;
      }

      // Prepare the request URL
      final url = '$_baseUrl/children/$childId/$mealId';
      debugPrint('🍽️ URL: $url');

      // Make HTTP DELETE request to Java Spring Boot backend
      final response = await http
          .delete(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📥 === API RESPONSE FROM DELETE /api/meals/children/$childId/$mealId ===',
      );
      debugPrint('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 204) {
        // Also remove local categories when meal is deleted
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('${_mealCategoriesKey}$mealId');

        debugPrint(
          '✅ Successfully deleted meal $mealId for child $childId (with local categories)',
        );
        return true;
      } else {
        debugPrint('❌ Failed to delete meal. Status: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error deleting meal for child: $e');
      return false;
    }
  }

  /// Filter meals by food type
  List<Meal> filterMealsByFoodType(List<Meal> meals, FoodType foodType) {
    return meals.where((meal) => meal.foodType == foodType).toList();
  }

  /// Filter meals by nutrition category
  List<Meal> filterMealsByNutrition(
    List<Meal> meals,
    NutritionCategory category,
  ) {
    return meals
        .where((meal) => meal.nutritionCategories?.contains(category) ?? false)
        .toList();
  }

  /// Filter meals by age group
  List<Meal> filterMealsByAgeGroup(List<Meal> meals, String ageGroup) {
    return meals.where((meal) => meal.ageGroup == ageGroup).toList();
  }

  /// Search meals by title or ingredients
  List<Meal> searchMeals(List<Meal> meals, String query) {
    final lowerQuery = query.toLowerCase();
    return meals.where((meal) {
      final titleMatch = meal.title.toLowerCase().contains(lowerQuery);
      final ingredientsMatch =
          meal.ingredients?.any(
            (ingredient) => ingredient.toLowerCase().contains(lowerQuery),
          ) ??
          false;
      return titleMatch || ingredientsMatch;
    }).toList();
  }

  /// Validate meal data before sending
  Map<String, String> validateMeal({
    required String title,
    List<String>? ingredients,
    String? recipe,
  }) {
    final Map<String, String> errors = {};

    if (title.trim().isEmpty) {
      errors['title'] = 'Meal title is required';
    } else if (title.trim().length < 3) {
      errors['title'] = 'Meal title must be at least 3 characters';
    } else if (title.trim().length > 100) {
      errors['title'] = 'Meal title must be less than 100 characters';
    }

    if (ingredients != null) {
      if (ingredients.length > 20) {
        errors['ingredients'] = 'Maximum 20 ingredients allowed';
      }
      for (int i = 0; i < ingredients.length; i++) {
        if (ingredients[i].trim().isEmpty) {
          errors['ingredients'] = 'Ingredient ${i + 1} cannot be empty';
          break;
        }
      }
    }

    if (recipe != null && recipe.length > 2000) {
      errors['recipe'] = 'Recipe must be less than 2000 characters';
    }

    return errors;
  }

  /// Get suggested meals based on age group and nutrition needs
  Future<List<Map<String, dynamic>>> getSuggestedMeals(String childAge) async {
    // This would ideally come from a nutrition database or API
    // For now, returning mock suggested meals based on age group
    final ageGroup = AgeGroup.getAgeGroupForAge(childAge);

    switch (ageGroup) {
      case AgeGroup.baby:
        return [
          {
            'title': 'Mashed Banana',
            'ingredients': ['Ripe banana'],
            'nutritionCategories': [NutritionCategory.fruits],
            'foodType': FoodType.snack,
          },
          {
            'title': 'Rice Cereal',
            'ingredients': ['Baby rice cereal', 'Breast milk or formula'],
            'nutritionCategories': [NutritionCategory.grains],
            'foodType': FoodType.breakfast,
          },
        ];
      case AgeGroup.toddler:
        return [
          {
            'title': 'Mini Scrambled Eggs',
            'ingredients': ['Eggs', 'Milk', 'Butter'],
            'nutritionCategories': [NutritionCategory.protein],
            'foodType': FoodType.breakfast,
          },
          {
            'title': 'Cut Fruit Bowl',
            'ingredients': ['Apple pieces', 'Banana slices', 'Soft berries'],
            'nutritionCategories': [NutritionCategory.fruits],
            'foodType': FoodType.snack,
          },
        ];
      default:
        return [
          {
            'title': 'Balanced Meal',
            'ingredients': ['Lean protein', 'Vegetables', 'Whole grains'],
            'nutritionCategories': [NutritionCategory.balanced],
            'foodType': FoodType.lunch,
          },
        ];
    }
  }
}
