import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../models/cart_item_model.dart';
import 'dart:io';

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
    _loadCartItems();
  }

  // Load cart items
  Future<void> _loadCartItems() async {
    try {
      _cartService.getCartItems().listen((items) {
        _cartItems = items;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Add to cart
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
      // Convert image paths to Files
      List<File> images = [];
      for (var path in imagePaths) {
        images.add(File(path));
      }

      await _cartService.addToCart(
        productId: productId,
        productName: productName,
        productImage: productImage,
        size: size,
        paperType: paperType,
        price: price,
        images: images,
        quantity: quantity,
        specialInstructions: specialInstructions,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    try {
      await _cartService.updateQuantity(cartItemId, quantity);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Remove from cart
  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _cartService.removeFromCart(cartItemId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear cart
  Future<void> clearCart() async {
    try {
      await _cartService.clearCart();
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
}