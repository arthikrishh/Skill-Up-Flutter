class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final List<String> imageUrls;
  final List<String> features;
  final String size;
  final String paperType;
  final bool isPopular;
  final int stockQuantity;
  final DateTime? createdAt;
  final double? discountPrice;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrls,
    this.features = const [],
    required this.size,
    required this.paperType,
    this.isPopular = false,
    this.stockQuantity = 100,
    this.createdAt,
    this.discountPrice,
  });

  // Get final price after discount
  double get finalPrice => discountPrice ?? price;

  // Check if product is on discount
  bool get hasDiscount => discountPrice != null;

  // Calculate discount percentage
  double? get discountPercentage {
    if (discountPrice != null) {
      return ((price - discountPrice!) / price) * 100;
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrls': imageUrls,
      'features': features,
      'size': size,
      'paperType': paperType,
      'isPopular': isPopular,
      'stockQuantity': stockQuantity,
      'createdAt': createdAt?.toIso8601String(),
      'discountPrice': discountPrice,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] as num).toDouble(),
      category: map['category'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      features: List<String>.from(map['features'] ?? []),
      size: map['size'] ?? '',
      paperType: map['paperType'] ?? '',
      isPopular: map['isPopular'] ?? false,
      stockQuantity: map['stockQuantity'] ?? 100,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : null,
      discountPrice: map['discountPrice']?.toDouble(),
    );
  }
}