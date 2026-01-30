import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  List<CartItemModel> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItemModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cart totals
  double get subtotal {
    return _cartItems.fold(0, (total, item) => total + item.itemTotal);
  }

  double get itemCount {
    return _cartItems.fold(0, (count, item) => count + item.quantity);
  }

  CartProvider() {
    // Initialize cart items
    _initializeCart();
  }

  // Initialize cart
  Future<void> _initializeCart() async {
    try {
      _cartService.getCartItems().listen((items) {
        _cartItems = items;
        notifyListeners();
      });
    } catch (e) {
      print('Error initializing cart: $e');
    }
  }

  // Add to cart - SIMPLIFIED VERSION FOR TESTING
  Future<bool> addToCart({
    required String productId,
    required String productName,
    required String productImage,
    required String size,
    required String paperType,
    required double price,
    required List<String> imagePaths,
    int quantity = 1,
    String? specialInstructions,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🛒 CartProvider.addToCart called');
      print('📦 Product: $productName');
      print('💰 Price: $price');
      print('📷 Images: ${imagePaths.length}');
      print('🔢 Quantity: $quantity');

      // Create a temporary cart item (for testing without Firebase)
      final cartItem = CartItemModel(
        id: '${productId}_${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        productName: productName,
        productImage: productImage,
        size: size,
        paperType: paperType,
        price: price,
        quantity: quantity,
        uploadedImages: [], // Empty for local storage
        specialInstructions: specialInstructions,
      );

      // Add to local list (TEMPORARY - replace with actual storage)
      _cartItems.add(cartItem);
      
      print('✅ Cart item created: ${cartItem.productName}');
      print('📊 Cart now has ${_cartItems.length} items');

      _isLoading = false;
      notifyListeners(); // THIS IS CRITICAL - notifies UI to update
      return true;
    } catch (e) {
      print('🚨 Error in addToCart: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get cart items count
  int get cartCount => _cartItems.length;

  // Check if cart is empty
  bool get isCartEmpty => _cartItems.isEmpty;

  // Remove from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      _cartItems.removeWhere((item) => item.id == cartItemId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Check if product is in cart
  bool isProductInCart(String productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Refresh cart
  Future<void> refreshCart() async {
    notifyListeners();
  }
}