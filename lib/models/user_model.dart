class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool emailVerified;
  final List<String>? addresses;
  final List<String>? favoriteProducts;
  final List<String>? cartItems;
  final Map<String, int>? cartQuantities; // productId -> quantity

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    required this.createdAt,
    this.lastLoginAt,
    this.emailVerified = false,
    this.addresses,
    this.favoriteProducts,
    this.cartItems,
    this.cartQuantities,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'emailVerified': emailVerified,
      'addresses': addresses ?? [],
      'favoriteProducts': favoriteProducts ?? [],
      'cartItems': cartItems ?? [],
      'cartQuantities': cartQuantities ?? {},
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phoneNumber: map['phoneNumber'],
      photoURL: map['photoURL'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLoginAt: map['lastLoginAt'] != null 
          ? DateTime.parse(map['lastLoginAt']) 
          : null,
      emailVerified: map['emailVerified'] ?? false,
      addresses: List<String>.from(map['addresses'] ?? []),
      favoriteProducts: List<String>.from(map['favoriteProducts'] ?? []),
      cartItems: List<String>.from(map['cartItems'] ?? []),
      cartQuantities: Map<String, int>.from(map['cartQuantities'] ?? {}),
    );
  }

  // Copy with method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? emailVerified,
    List<String>? addresses,
    List<String>? favoriteProducts,
    List<String>? cartItems,
    Map<String, int>? cartQuantities,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      emailVerified: emailVerified ?? this.emailVerified,
      addresses: addresses ?? this.addresses,
      favoriteProducts: favoriteProducts ?? this.favoriteProducts,
      cartItems: cartItems ?? this.cartItems,
      cartQuantities: cartQuantities ?? this.cartQuantities,
    );
  }

  // Helper methods for e-commerce functionality
  bool hasProductInCart(String productId) {
    return cartItems?.contains(productId) ?? false;
  }

  bool hasProductInFavorites(String productId) {
    return favoriteProducts?.contains(productId) ?? false;
  }

  int getCartQuantity(String productId) {
    return cartQuantities?[productId] ?? 0;
  }
}