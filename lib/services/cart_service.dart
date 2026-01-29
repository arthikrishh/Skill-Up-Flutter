import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/cart_item_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user cart items
  Stream<List<CartItemModel>> getCartItems() {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('cart')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartItemModel.fromMap(doc.data()))
            .toList());
  }

  // Add item to cart
  Future<void> addToCart({
    required String productId,
    required String productName,
    required String productImage,
    required String size,
    required String paperType,
    required double price,
    required List<File> images,
    int quantity = 1,
    String? specialInstructions,
  }) async {
    if (_auth.currentUser == null) {
      throw 'Please login to add items to cart';
    }

    try {
      // Upload images to Firebase Storage
      List<String> imageUrls = [];
      for (var i = 0; i < images.length; i++) {
        final imageUrl = await _uploadImage(images[i]);
        imageUrls.add(imageUrl);
      }

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
        uploadedImages: imageUrls,
        specialInstructions: specialInstructions,
      );

      // Add to Firestore
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('cart')
          .doc(cartItem.id)
          .set(cartItem.toMap());
    } catch (e) {
      throw 'Failed to add item to cart: $e';
    }
  }

  // Update cart item quantity
  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (_auth.currentUser == null) return;

    if (quantity <= 0) {
      // Remove item if quantity is 0
      await removeFromCart(cartItemId);
      return;
    }

    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('cart')
        .doc(cartItemId)
        .update({'quantity': quantity});
  }

  // Remove item from cart
  Future<void> removeFromCart(String cartItemId) async {
    if (_auth.currentUser == null) return;

    // Delete uploaded images from storage
    final doc = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('cart')
        .doc(cartItemId)
        .get();

    if (doc.exists) {
      final cartItem = CartItemModel.fromMap(doc.data()!);
      
      // Delete each uploaded image
      for (var imageUrl in cartItem.uploadedImages) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
    }

    // Delete cart item
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('cart')
        .doc(cartItemId)
        .delete();
  }

  // Clear entire cart
  Future<void> clearCart() async {
    if (_auth.currentUser == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('cart')
        .get();

    // Delete all images first
    for (var doc in snapshot.docs) {
      final cartItem = CartItemModel.fromMap(doc.data());
      for (var imageUrl in cartItem.uploadedImages) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
    }

    // Delete all cart items
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File image) async {
    try {
      final fileName = '${_auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('user_uploads/$fileName');
      
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

// Get cart total - SIMPLE FIX
Future<double> getCartTotal() async {
  try {
    final cartItems = await getCartItems().first;
    return cartItems.fold<double>(0.0, (total, item) => total + item.itemTotal);
  } catch (e) {
    print('Error calculating cart total: $e');
    return 0.0;
  }
}

// Get item count - SIMPLE FIX
Future<int> getItemCount() async {
  try {
    final cartItems = await getCartItems().first;
    return cartItems.fold<int>(0, (count, item) => count + item.quantity);
  } catch (e) {
    print('Error calculating item count: $e');
    return 0;
  }
}
}