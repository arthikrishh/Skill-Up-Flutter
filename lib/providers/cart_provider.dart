import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item_model.dart';

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
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
    // Load cart items from Firestore when provider is created
    if (_auth.currentUser != null) {
      _loadCartItemsFromFirestore();
    }
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _loadCartItemsFromFirestore();
      } else {
        _cartItems.clear();
        notifyListeners();
      }
    });
  }

  // Load cart items from Firestore
  Future<void> _loadCartItemsFromFirestore() async {
    if (_auth.currentUser == null) {
      _cartItems = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .orderBy('addedAt', descending: true)
          .get();

      _cartItems = snapshot.docs
          .map((doc) => CartItemModel.fromMap(doc.data()))
          .toList();

      print('✅ Loaded ${_cartItems.length} cart items from Firestore');
    } catch (e) {
      print('🚨 Error loading cart from Firestore: $e');
      _errorMessage = 'Failed to load cart items';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add to cart and save to Firestore
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
    if (_auth.currentUser == null) {
      _errorMessage = 'Please login to add items to cart';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🛒 Adding to Firestore cart...');
      
      // Create cart item
      final cartItem = CartItemModel(
        id: '${productId}_${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        productName: productName,
        productImage: productImage,
        size: size,
        paperType: paperType,
        price: price,
        quantity: quantity,
        uploadedImages: [], // We'll store image paths as strings
        specialInstructions: specialInstructions,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(cartItem.id)
          .set(cartItem.toMap());

      // Also add to local list
      _cartItems.add(cartItem);
      
      print('✅ Cart item saved to Firestore: ${cartItem.productName}');
      print('📊 Cart now has ${_cartItems.length} items in Firestore');

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('🚨 Error saving to Firestore cart: $e');
      _errorMessage = 'Failed to add item to cart: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update quantity in Firestore
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (_auth.currentUser == null || quantity < 1) return;

    try {
      if (quantity == 0) {
        await removeFromCart(cartItemId);
        return;
      }

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(cartItemId)
          .update({'quantity': quantity});

      // Update local list
      final index = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
        notifyListeners();
      }
    } catch (e) {
      print('Error updating quantity: $e');
      _errorMessage = 'Failed to update quantity';
      notifyListeners();
    }
  }

  // Remove from cart in Firestore
  Future<void> removeFromCart(String cartItemId) async {
    if (_auth.currentUser == null) return;

    try {
      // Remove from Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(cartItemId)
          .delete();

      // Remove from local list
      _cartItems.removeWhere((item) => item.id == cartItemId);
      notifyListeners();
    } catch (e) {
      print('Error removing from cart: $e');
      _errorMessage = 'Failed to remove item';
      notifyListeners();
    }
  }

  // Clear entire cart from Firestore
  Future<void> clearCart() async {
    if (_auth.currentUser == null) return;

    try {
      // Get all cart items
      final snapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .get();

      // Delete all items in batch
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // Clear local list
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
      _errorMessage = 'Failed to clear cart';
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

  // Refresh cart from Firestore
  Future<void> refreshCart() async {
    await _loadCartItemsFromFirestore();
  }

  // Get cart count
  int get cartCount => _cartItems.length;

  // Check if cart is empty
  bool get isCartEmpty => _cartItems.isEmpty;
}