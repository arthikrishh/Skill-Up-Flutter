import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  List<String> _cartItems = [];
  Map<String, int> _cartQuantities = {};
  List<String> _favorites = [];

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get cartItems => _cartItems;
  Map<String, int> get cartQuantities => _cartQuantities;
  List<String> get favorites => _favorites;
  
  int get cartItemCount => _cartItems.length;
  int get favoriteCount => _favorites.length;

  AuthProvider() {
    // Initialize auth listener
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _firebaseService.authStateChanges.listen((User? user) async {
      if (user != null) {
        await _loadCurrentUser();
      } else {
        _currentUser = null;
        _cartItems = [];
        _cartQuantities = {};
        _favorites = [];
        notifyListeners();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final userData = await _firebaseService.getCurrentUserData();
      
      if (userData != null) {
        _currentUser = userData;
        _cartItems = userData.cartItems ?? [];
        _cartQuantities = userData.cartQuantities ?? {};
        _favorites = userData.favoriteProducts ?? [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== AUTH METHODS ====================

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _firebaseService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      
      if (user != null) {
        _currentUser = user;
      }
      
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

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _firebaseService.signInWithEmail(
        email: email,
        password: password,
      );
      
      if (user != null) {
        _currentUser = user;
        _cartItems = user.cartItems ?? [];
        _cartQuantities = user.cartQuantities ?? {};
        _favorites = user.favoriteProducts ?? [];
      }
      
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

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _firebaseService.signInWithGoogle();
      
      if (user != null) {
        _currentUser = user;
        _cartItems = user.cartItems ?? [];
        _cartQuantities = user.cartQuantities ?? {};
        _favorites = user.favoriteProducts ?? [];
      }
      
      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _firebaseService.signOut();
    _currentUser = null;
    _cartItems = [];
    _cartQuantities = {};
    _favorites = [];
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.sendPasswordResetEmail(email);
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

  // ==================== USER PROFILE METHODS ====================

  Future<bool> updateProfile({
    String? displayName,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _firebaseService.updateUserProfile(
        displayName: displayName,
        phoneNumber: phoneNumber,
      );
      
      // Update local user model
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          displayName: displayName ?? _currentUser!.displayName,
          phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        );
      }
      
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

  // ==================== CART METHODS ====================

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    try {
      await _firebaseService.addToCart(productId, quantity: quantity);
      
      if (!_cartItems.contains(productId)) {
        _cartItems.add(productId);
      }
      
      _cartQuantities[productId] = 
          (_cartQuantities[productId] ?? 0) + quantity;
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      await _firebaseService.removeFromCart(productId);
      
      _cartItems.remove(productId);
      _cartQuantities.remove(productId);
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateCartQuantity(String productId, int quantity) async {
    try {
      await _firebaseService.updateCartQuantity(productId, quantity);
      
      if (quantity <= 0) {
        _cartItems.remove(productId);
        _cartQuantities.remove(productId);
      } else {
        _cartQuantities[productId] = quantity;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearCart() async {
    try {
      // Remove each item individually
      for (final productId in List.from(_cartItems)) {
        await removeFromCart(productId);
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ==================== FAVORITE METHODS ====================

  Future<void> toggleFavorite(String productId) async {
    try {
      await _firebaseService.toggleFavorite(productId);
      
      if (_favorites.contains(productId)) {
        _favorites.remove(productId);
      } else {
        _favorites.add(productId);
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  bool isFavorite(String productId) {
    return _favorites.contains(productId);
  }

  // ==================== ADDRESS METHODS ====================

  Future<void> addAddress(String address) async {
    try {
      await _firebaseService.addAddress(address);
      
      if (_currentUser != null) {
        final currentAddresses = _currentUser!.addresses ?? [];
        currentAddresses.add(address);
        _currentUser = _currentUser!.copyWith(addresses: currentAddresses);
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeAddress(String address) async {
    try {
      await _firebaseService.removeAddress(address);
      
      if (_currentUser != null) {
        final currentAddresses = _currentUser!.addresses ?? [];
        currentAddresses.remove(address);
        _currentUser = _currentUser!.copyWith(addresses: currentAddresses);
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ==================== UTILITY METHODS ====================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}