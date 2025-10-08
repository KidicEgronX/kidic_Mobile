import 'package:flutter/foundation.dart';

class Meal {
  final int? id; // Note: Java uses Long, but Dart int can handle the range
  final String title;
  final List<String>? ingredients;
  final String? recipe;
  final int childId; // Derived from Child entity relationship

  // Note: The Java entity doesn't have these fields yet, but they're useful for UI
  // These are client-side only fields for categorization and filtering
  final FoodType? foodType;
  final List<NutritionCategory>? nutritionCategories;
  final String? ageGroup;
  final String? notes;

  const Meal({
    this.id,
    required this.title,
    this.ingredients,
    this.recipe,
    required this.childId,
    this.foodType,
    this.nutritionCategories,
    this.ageGroup,
    this.notes,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    // Parse FoodType from string if present
    FoodType? foodType;
    if (json['foodType'] != null) {
      try {
        foodType = FoodType.values.firstWhere(
          (e) => e.name == json['foodType'],
        );
      } catch (e) {
        debugPrint('Warning: Invalid foodType value: ${json['foodType']}');
      }
    }

    // Parse NutritionCategories from list of strings if present
    List<NutritionCategory>? nutritionCategories;
    if (json['nutritionCategories'] != null) {
      try {
        final categoryList = json['nutritionCategories'] as List;
        nutritionCategories = categoryList
            .map(
              (categoryName) => NutritionCategory.values.firstWhere(
                (e) => e.name == categoryName,
              ),
            )
            .toList();
      } catch (e) {
        debugPrint(
          'Warning: Invalid nutritionCategories: ${json['nutritionCategories']}',
        );
      }
    }

    return Meal(
      id: json['id'] as int?,
      title: json['title'] as String,
      ingredients: json['ingredients'] != null
          ? List<String>.from(json['ingredients'] as List)
          : null,
      recipe: json['recipe'] as String?,
      // Note: childId needs to be extracted from child relationship in JSON
      childId:
          json['childId'] as int? ??
          (json['child'] != null ? json['child']['id'] as int : 0),
      // Parse categories from JSON (loaded from local storage)
      foodType: foodType,
      nutritionCategories: nutritionCategories,
      ageGroup: null, // Set manually in client
      notes: null, // Set manually in client
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ingredients': ingredients,
      'recipe': recipe,
      'childId': childId,
      // Don't send client-side fields to API
    };
  }

  // Create a minimal JSON for API requests (only fields the backend expects)
  Map<String, dynamic> toApiJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      if (ingredients != null) 'ingredients': ingredients,
      if (recipe != null) 'recipe': recipe,
    };
  }

  Meal copyWith({
    int? id,
    String? title,
    List<String>? ingredients,
    String? recipe,
    int? childId,
    FoodType? foodType,
    List<NutritionCategory>? nutritionCategories,
    String? ageGroup,
    String? notes,
  }) {
    return Meal(
      id: id ?? this.id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      recipe: recipe ?? this.recipe,
      childId: childId ?? this.childId,
      foodType: foodType ?? this.foodType,
      nutritionCategories: nutritionCategories ?? this.nutritionCategories,
      ageGroup: ageGroup ?? this.ageGroup,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Meal(id: $id, title: $title, childId: $childId, foodType: $foodType)';
  }
}

enum FoodType { breakfast, lunch, dinner, snack, main }

enum NutritionCategory {
  protein,
  carbohydrates,
  vegetables,
  fruits,
  dairy,
  grains,
  healthy_fats,
  balanced,
}

extension FoodTypeExtension on FoodType {
  String get displayName {
    switch (this) {
      case FoodType.breakfast:
        return 'Breakfast';
      case FoodType.lunch:
        return 'Lunch';
      case FoodType.dinner:
        return 'Dinner';
      case FoodType.snack:
        return 'Snack';
      case FoodType.main:
        return 'Main Course';
    }
  }

  String get icon {
    switch (this) {
      case FoodType.breakfast:
        return '🌅';
      case FoodType.lunch:
        return '🌞';
      case FoodType.dinner:
        return '🌙';
      case FoodType.snack:
        return '🍎';
      case FoodType.main:
        return '🍽️';
    }
  }
}

extension NutritionCategoryExtension on NutritionCategory {
  String get displayName {
    switch (this) {
      case NutritionCategory.protein:
        return 'Protein';
      case NutritionCategory.carbohydrates:
        return 'Carbohydrates';
      case NutritionCategory.vegetables:
        return 'Vegetables';
      case NutritionCategory.fruits:
        return 'Fruits';
      case NutritionCategory.dairy:
        return 'Dairy';
      case NutritionCategory.grains:
        return 'Grains';
      case NutritionCategory.healthy_fats:
        return 'Healthy Fats';
      case NutritionCategory.balanced:
        return 'Balanced';
    }
  }

  String get icon {
    switch (this) {
      case NutritionCategory.protein:
        return '🥩';
      case NutritionCategory.carbohydrates:
        return '🍞';
      case NutritionCategory.vegetables:
        return '🥬';
      case NutritionCategory.fruits:
        return '🍎';
      case NutritionCategory.dairy:
        return '🥛';
      case NutritionCategory.grains:
        return '🌾';
      case NutritionCategory.healthy_fats:
        return '🥑';
      case NutritionCategory.balanced:
        return '🥗';
    }
  }

  String get color {
    switch (this) {
      case NutritionCategory.protein:
        return '#E53E3E';
      case NutritionCategory.carbohydrates:
        return '#D69E2E';
      case NutritionCategory.vegetables:
        return '#38A169';
      case NutritionCategory.fruits:
        return '#E53E3E';
      case NutritionCategory.dairy:
        return '#3182CE';
      case NutritionCategory.grains:
        return '#D69E2E';
      case NutritionCategory.healthy_fats:
        return '#38A169';
      case NutritionCategory.balanced:
        return '#805AD5';
    }
  }
}

// Age group helper class
class AgeGroup {
  static const String baby = '0-1 years';
  static const String toddler = '1-3 years';
  static const String preschool = '3-5 years';
  static const String schoolAge = '5-12 years';
  static const String teen = '12+ years';

  static List<String> get all => [baby, toddler, preschool, schoolAge, teen];

  static String getAgeGroupForAge(String age) {
    // Parse age and return appropriate group
    final ageInYears = _parseAge(age);
    if (ageInYears < 1) return baby;
    if (ageInYears < 3) return toddler;
    if (ageInYears < 5) return preschool;
    if (ageInYears < 12) return schoolAge;
    return teen;
  }

  static double _parseAge(String age) {
    // Simple age parsing - you might want to make this more robust
    final ageStr = age.toLowerCase().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(ageStr) ?? 0;
  }
}
