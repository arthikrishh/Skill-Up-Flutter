class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final String productImage;
  final String size;
  final String paperType;
  final double price;
  final int quantity;
  final List<String> uploadedImages;
  final String? specialInstructions;
  final DateTime addedAt;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.size,
    required this.paperType,
    required this.price,
    required this.quantity,
    required this.uploadedImages,
    this.specialInstructions,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  // Calculate item total
  double get itemTotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'size': size,
      'paperType': paperType,
      'price': price,
      'quantity': quantity,
      'uploadedImages': uploadedImages,
      'specialInstructions': specialInstructions,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      productImage: map['productImage'] ?? '',
      size: map['size'] ?? '',
      paperType: map['paperType'] ?? '',
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] ?? 1,
      uploadedImages: List<String>.from(map['uploadedImages'] ?? []),
      specialInstructions: map['specialInstructions'],
      addedAt: map['addedAt'] != null 
          ? DateTime.parse(map['addedAt']) 
          : DateTime.now(),
    );
  }

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImage,
    String? size,
    String? paperType,
    double? price,
    int? quantity,
    List<String>? uploadedImages,
    String? specialInstructions,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      size: size ?? this.size,
      paperType: paperType ?? this.paperType,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      uploadedImages: uploadedImages ?? this.uploadedImages,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}