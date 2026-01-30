import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  final Uuid _uuid = Uuid();

  // Save image locally and return local path
  Future<String> saveImageLocally(File image) async {
    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/cart_images');
      
      // Create directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Generate unique filename
      final fileName = '${_uuid.v4()}.jpg';
      final newPath = '${imagesDir.path}/$fileName';
      
      // Copy the file to permanent storage
      await image.copy(newPath);
      
      return newPath;
    } catch (e) {
      print('Error saving image locally: $e');
      rethrow;
    }
  }

  // Save multiple images
  Future<List<String>> saveImagesLocally(List<File> images) async {
    final List<String> savedPaths = [];
    
    for (var image in images) {
      final path = await saveImageLocally(image);
      savedPaths.add(path);
    }
    
    return savedPaths;
  }

  // Save cart item with image references
  Future<void> saveCartItemLocally({
    required String productId,
    required String productName,
    required String productImage,
    required String size,
    required String paperType,
    required double price,
    required List<String> localImagePaths,
    int quantity = 1,
    String? specialInstructions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Generate cart item ID
    final cartItemId = '${productId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create cart item map
    final cartItem = {
      'id': cartItemId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'size': size,
      'paperType': paperType,
      'price': price,
      'quantity': quantity,
      'localImagePaths': localImagePaths,
      'specialInstructions': specialInstructions,
      'addedAt': DateTime.now().toIso8601String(),
    };
    
    // Get existing cart items
    final cartItemsJson = prefs.getStringList('cart_items') ?? [];
    cartItemsJson.add(json.encode(cartItem));
    
    // Save back
    await prefs.setStringList('cart_items', cartItemsJson);
  }

  // Get all cart items
  Future<List<Map<String, dynamic>>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList('cart_items') ?? [];
    
    return cartItemsJson.map((jsonString) {
      return Map<String, dynamic>.from(json.decode(jsonString));
    }).toList();
  }

  // Remove cart item
  Future<void> removeCartItem(String cartItemId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList('cart_items') ?? [];
    
    // Remove the item
    final updatedItems = cartItemsJson.where((itemJson) {
      final item = json.decode(itemJson);
      return item['id'] != cartItemId;
    }).toList();
    
    await prefs.setStringList('cart_items', updatedItems);
  }

  // Clear all cart items
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_items');
    
    // Optional: Also delete image files
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/cart_images');
    if (await imagesDir.exists()) {
      await imagesDir.delete(recursive: true);
    }
  }

  // Check if image file exists
  Future<bool> imageExists(String path) async {
    final file = File(path);
    return await file.exists();
  }

  // Get image file
  Future<File> getImageFile(String path) async {
    return File(path);
  }

  // Get cart count
  Future<int> getCartCount() async {
    final prefs = await SharedPreferences.getInstance();
    final cartItemsJson = prefs.getStringList('cart_items') ?? [];
    return cartItemsJson.length;
  }
}