class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final ProductCategory category;
  final List<String>
  ageGroups; // e.g., "0-6 months", "6-12 months", "1-2 years"
  final List<String> features;
  final bool inStock;
  final double rating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.ageGroups,
    required this.features,
    this.inStock = true,
    this.rating = 4.5,
    this.reviewCount = 0,
  });
}

enum ProductCategory {
  toys,
  clothing,
  feeding,
  health,
  education,
  safety,
  furniture,
  bath;

  String get displayName {
    switch (this) {
      case ProductCategory.toys:
        return 'Toys & Games';
      case ProductCategory.clothing:
        return 'Clothing';
      case ProductCategory.feeding:
        return 'Feeding';
      case ProductCategory.health:
        return 'Health & Care';
      case ProductCategory.education:
        return 'Educational';
      case ProductCategory.safety:
        return 'Safety';
      case ProductCategory.furniture:
        return 'Furniture';
      case ProductCategory.bath:
        return 'Bath & Hygiene';
    }
  }

  String get emoji {
    switch (this) {
      case ProductCategory.toys:
        return '🧸';
      case ProductCategory.clothing:
        return '👕';
      case ProductCategory.feeding:
        return '🍼';
      case ProductCategory.health:
        return '💊';
      case ProductCategory.education:
        return '📚';
      case ProductCategory.safety:
        return '🛡️';
      case ProductCategory.furniture:
        return '🪑';
      case ProductCategory.bath:
        return '🛁';
    }
  }
}

// Static product data
class ProductData {
  static final List<Product> allProducts = [
    // Toys & Games
    Product(
      id: 1,
      name: 'Soft Plush Bear',
      description: 'Cuddly and safe plush toy perfect for infants',
      price: 24.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Plush+Bear',
      category: ProductCategory.toys,
      ageGroups: ['0-6 months', '6-12 months', '1-2 years'],
      features: ['Soft material', 'Machine washable', 'Non-toxic'],
      rating: 4.8,
      reviewCount: 125,
    ),
    Product(
      id: 2,
      name: 'Educational Building Blocks',
      description: 'Colorful blocks to develop motor skills and creativity',
      price: 34.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Building+Blocks',
      category: ProductCategory.toys,
      ageGroups: ['1-2 years', '2-3 years', '3-4 years'],
      features: ['BPA-free', 'Color recognition', 'Safe edges'],
      rating: 4.9,
      reviewCount: 200,
    ),
    Product(
      id: 3,
      name: 'Musical Activity Cube',
      description:
          'Interactive cube with music and lights for sensory development',
      price: 45.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Activity+Cube',
      category: ProductCategory.toys,
      ageGroups: ['6-12 months', '1-2 years'],
      features: ['Multiple activities', 'Music & lights', 'Battery operated'],
      rating: 4.7,
      reviewCount: 89,
    ),

    // Clothing
    Product(
      id: 4,
      name: 'Organic Cotton Onesie Set',
      description: 'Soft and comfortable onesies made from 100% organic cotton',
      price: 29.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Onesie+Set',
      category: ProductCategory.clothing,
      ageGroups: ['0-6 months', '6-12 months'],
      features: ['100% organic', 'Snap closure', 'Pack of 3'],
      rating: 4.6,
      reviewCount: 156,
    ),
    Product(
      id: 5,
      name: 'Toddler Winter Jacket',
      description: 'Warm and cozy jacket for cold weather',
      price: 54.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Winter+Jacket',
      category: ProductCategory.clothing,
      ageGroups: ['1-2 years', '2-3 years', '3-4 years'],
      features: ['Water-resistant', 'Warm lining', 'Multiple colors'],
      rating: 4.8,
      reviewCount: 98,
    ),

    // Feeding
    Product(
      id: 6,
      name: 'Anti-Colic Baby Bottles Set',
      description: 'Advanced anti-colic system reduces feeding issues',
      price: 39.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Baby+Bottles',
      category: ProductCategory.feeding,
      ageGroups: ['0-6 months', '6-12 months'],
      features: ['BPA-free', 'Anti-colic', 'Set of 4 bottles'],
      rating: 4.9,
      reviewCount: 234,
    ),
    Product(
      id: 7,
      name: 'Silicone Baby Feeding Set',
      description: 'Complete feeding set with plate, bowl, spoon, and cup',
      price: 27.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Feeding+Set',
      category: ProductCategory.feeding,
      ageGroups: ['6-12 months', '1-2 years'],
      features: ['Silicone material', 'Microwave safe', 'Suction base'],
      rating: 4.7,
      reviewCount: 178,
    ),
    Product(
      id: 8,
      name: 'Stainless Steel Sippy Cup',
      description: 'Leak-proof sippy cup with handles for easy grip',
      price: 18.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Sippy+Cup',
      category: ProductCategory.feeding,
      ageGroups: ['6-12 months', '1-2 years', '2-3 years'],
      features: ['Stainless steel', 'Leak-proof', 'Easy to clean'],
      rating: 4.5,
      reviewCount: 145,
    ),

    // Health & Care
    Product(
      id: 9,
      name: 'Digital Thermometer',
      description: 'Fast and accurate temperature readings',
      price: 15.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Thermometer',
      category: ProductCategory.health,
      ageGroups: [
        '0-6 months',
        '6-12 months',
        '1-2 years',
        '2-3 years',
        '3-4 years',
      ],
      features: ['Fast reading', 'Fever alarm', 'Memory function'],
      rating: 4.6,
      reviewCount: 267,
    ),
    Product(
      id: 10,
      name: 'Baby First Aid Kit',
      description: 'Complete first aid kit designed for babies and toddlers',
      price: 42.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=First+Aid+Kit',
      category: ProductCategory.health,
      ageGroups: ['0-6 months', '6-12 months', '1-2 years', '2-3 years'],
      features: ['90+ items', 'Portable case', 'Essential care items'],
      rating: 4.8,
      reviewCount: 112,
    ),

    // Educational
    Product(
      id: 11,
      name: 'Interactive Learning Tablet',
      description: 'Kid-friendly tablet with educational games and activities',
      price: 79.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Learning+Tablet',
      category: ProductCategory.education,
      ageGroups: ['2-3 years', '3-4 years', '4-5 years'],
      features: ['Pre-loaded content', 'Parental controls', 'Durable design'],
      rating: 4.7,
      reviewCount: 189,
    ),
    Product(
      id: 12,
      name: 'Alphabet Learning Cards',
      description: 'Colorful flashcards for learning letters and words',
      price: 14.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Learning+Cards',
      category: ProductCategory.education,
      ageGroups: ['1-2 years', '2-3 years', '3-4 years'],
      features: ['52 cards', 'Laminated', 'Picture association'],
      rating: 4.5,
      reviewCount: 98,
    ),

    // Safety
    Product(
      id: 13,
      name: 'Baby Monitor with Camera',
      description: 'HD video baby monitor with night vision',
      price: 129.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Baby+Monitor',
      category: ProductCategory.safety,
      ageGroups: ['0-6 months', '6-12 months', '1-2 years'],
      features: ['HD video', 'Night vision', 'Two-way audio'],
      rating: 4.9,
      reviewCount: 345,
    ),
    Product(
      id: 14,
      name: 'Cabinet Safety Locks Set',
      description: 'Childproof locks for cabinets and drawers',
      price: 19.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Safety+Locks',
      category: ProductCategory.safety,
      ageGroups: ['6-12 months', '1-2 years', '2-3 years'],
      features: ['Easy installation', 'No drilling', 'Pack of 10'],
      rating: 4.6,
      reviewCount: 223,
    ),

    // Furniture
    Product(
      id: 15,
      name: 'Convertible Baby Crib',
      description: 'Grows with your child - converts to toddler bed',
      price: 299.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Baby+Crib',
      category: ProductCategory.furniture,
      ageGroups: ['0-6 months', '6-12 months', '1-2 years', '2-3 years'],
      features: ['Convertible', 'Solid wood', 'Adjustable height'],
      rating: 4.9,
      reviewCount: 412,
    ),
    Product(
      id: 16,
      name: 'High Chair with Tray',
      description: 'Comfortable and safe high chair for feeding time',
      price: 89.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=High+Chair',
      category: ProductCategory.furniture,
      ageGroups: ['6-12 months', '1-2 years', '2-3 years'],
      features: ['Adjustable height', 'Removable tray', 'Easy to clean'],
      rating: 4.7,
      reviewCount: 167,
    ),

    // Bath & Hygiene
    Product(
      id: 17,
      name: 'Baby Bath Tub with Support',
      description: 'Ergonomic bath tub with newborn support sling',
      price: 34.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Bath+Tub',
      category: ProductCategory.bath,
      ageGroups: ['0-6 months', '6-12 months'],
      features: ['Newborn support', 'Drain plug', 'Non-slip bottom'],
      rating: 4.6,
      reviewCount: 201,
    ),
    Product(
      id: 18,
      name: 'Organic Baby Shampoo Set',
      description: 'Gentle, tear-free shampoo and body wash',
      price: 22.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Shampoo+Set',
      category: ProductCategory.bath,
      ageGroups: ['0-6 months', '6-12 months', '1-2 years', '2-3 years'],
      features: ['Organic ingredients', 'Tear-free', 'Hypoallergenic'],
      rating: 4.8,
      reviewCount: 289,
    ),
    Product(
      id: 19,
      name: 'Hooded Baby Towel Set',
      description: 'Soft and absorbent towels with cute animal designs',
      price: 24.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Towel+Set',
      category: ProductCategory.bath,
      ageGroups: ['0-6 months', '6-12 months', '1-2 years'],
      features: ['100% cotton', 'Hooded design', 'Set of 2'],
      rating: 4.7,
      reviewCount: 156,
    ),
    Product(
      id: 20,
      name: 'Bath Toys Set',
      description: 'Fun and safe bath toys for water play',
      price: 16.99,
      imageUrl: 'https://via.placeholder.com/300x300.png?text=Bath+Toys',
      category: ProductCategory.bath,
      ageGroups: ['6-12 months', '1-2 years', '2-3 years'],
      features: ['BPA-free', 'Floating toys', 'Colorful designs'],
      rating: 4.5,
      reviewCount: 134,
    ),
  ];

  // Age group options
  static final List<String> ageGroups = [
    '0-6 months',
    '6-12 months',
    '1-2 years',
    '2-3 years',
    '3-4 years',
    '4-5 years',
  ];

  // Get products by category
  static List<Product> getProductsByCategory(ProductCategory category) {
    return allProducts.where((p) => p.category == category).toList();
  }

  // Get products by age group
  static List<Product> getProductsByAgeGroup(String ageGroup) {
    return allProducts.where((p) => p.ageGroups.contains(ageGroup)).toList();
  }

  // Get products by category and age
  static List<Product> getFilteredProducts({
    ProductCategory? category,
    String? ageGroup,
  }) {
    return allProducts.where((product) {
      final matchesCategory = category == null || product.category == category;
      final matchesAge =
          ageGroup == null || product.ageGroups.contains(ageGroup);
      return matchesCategory && matchesAge;
    }).toList();
  }
}
