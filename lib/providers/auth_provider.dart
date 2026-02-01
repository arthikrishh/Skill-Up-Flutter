import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/auth_service.dart'; // CHANGE THIS LINE
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService(); // CHANGE THIS LINE
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
    _authService.authStateChanges.listen((User? user) async {
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

      final userData = await _authService.getCurrentUserData(); // CHANGED THIS
      
      if (userData != null) {
        _currentUser = userData;
        // Note: Your UserModel might not have cartItems, cartQuantities, favoriteProducts
        // These might be handled by a separate CartProvider
        _cartItems = []; // You might need to load these from Firestore separately
        _cartQuantities = {};
        _favorites = [];
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
      final user = await _authService.signUpWithEmail( // CHANGED THIS
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
      final user = await _authService.signInWithEmail( // CHANGED THIS
        email: email,
        password: password,
      );
      
      if (user != null) {
        _currentUser = user;
        // You might need to load cart and favorites from a separate service
        _cartItems = [];
        _cartQuantities = {};
        _favorites = [];
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

  // You might not have Google sign-in in the new AuthService
  // Remove this if not needed, or add it to AuthService
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // This method might not exist in AuthService yet
      // final user = await _authService.signInWithGoogle();
      
      // if (user != null) {
      //   _currentUser = user;
      //   _cartItems = user.cartItems ?? [];
      //   _cartQuantities = user.cartQuantities ?? {};
      //   _favorites = user.favoriteProducts ?? [];
      // }
      
      _isLoading = false;
      notifyListeners();
      return false; // Temporarily disabled
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut(); // CHANGED THIS
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
      await _authService.sendPasswordResetEmail(email); // CHANGED THIS
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
  String? bio,
  String? photoURL,
}) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  print('🎯 AuthProvider.updateProfile() called with:');
  print('  displayName: "$displayName"');
  print('  phoneNumber: "$phoneNumber"');
  print('  bio: "$bio"');
  print('  photoURL: "$photoURL"');

  try {
    final updatedUser = await _authService.updateProfile(
      displayName: displayName,
      phoneNumber: phoneNumber,
      bio: bio,
      photoURL: photoURL,
    );
    
    if (updatedUser != null) {
      _currentUser = updatedUser;
      print('✅ AuthProvider - Successfully updated user data:');
      print('  displayName: "${updatedUser.displayName}"');
      print('  phoneNumber: "${updatedUser.phoneNumber}"');
      print('  bio: "${updatedUser.bio}"');
      print('  photoURL: "${updatedUser.photoURL}"');
      
      // Also call debugUserData to see everything
      await _authService.debugUserData();
    } else {
      print('❌ AuthProvider - updatedUser is null');
    }
    
    _isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    _errorMessage = e.toString();
    print('❌ AuthProvider.updateProfile() error: $e');
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
  // ADD THIS METHOD FOR UPLOADING PROFILE IMAGES
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final imageUrl = await _authService.uploadProfileImage(imageFile);
      return imageUrl;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ADD THIS METHOD FOR EMAIL VERIFICATION
  Future<bool> sendEmailVerification() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendEmailVerification();
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

  // ==================== CART METHODS (MIGHT BE HANDLED BY SEPARATE CART PROVIDER) ====================

  // Note: Cart functionality might be better handled by a separate CartProvider
  // The AuthService I created doesn't have cart methods
  // You might need to keep these if you have a separate service or move to CartProvider

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    try {
      // You'll need to implement this in a separate CartService
      // await _firebaseService.addToCart(productId, quantity: quantity);
      
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
      // You'll need to implement this in a separate CartService
      // await _firebaseService.removeFromCart(productId);
      
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
      // You'll need to implement this in a separate CartService
      // await _firebaseService.updateCartQuantity(productId, quantity);
      
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
      // You'll need to implement this in a separate service
      // await _firebaseService.toggleFavorite(productId);
      
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
      // You'll need to implement this in a separate service
      // await _firebaseService.addAddress(address);
      
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
      // You'll need to implement this in a separate service
      // await _firebaseService.removeAddress(address);
      
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