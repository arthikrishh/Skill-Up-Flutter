import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  List<ProductModel> _products = [];
  List<ProductModel> _popularProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  List<ProductModel> get popularProducts => _popularProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductProvider() {
    _loadProducts();
    _loadPopularProducts();
  }

  // Load all products
  Future<void> _loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _productService.getProducts().listen((products) {
        _products = products;
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load popular products
  Future<void> _loadPopularProducts() async {
    try {
      _productService.getPopularProducts().listen((products) {
        _popularProducts = products;
        notifyListeners();
      });
    } catch (e) {
      print('Error loading popular products: $e');
    }
  }

  // Get products by category
  List<ProductModel> getProductsByCategory(String category) {
    return _products.where((product) => product.category == category).toList();
  }

  // Search products
  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return _products;
    
    return _products.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
             product.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get product by ID
  ProductModel? getProductById(String productId) {
    return _products.firstWhere(
      (product) => product.id == productId,
      orElse: () => ProductModel(
        id: '',
        name: '',
        description: '',
        price: 0,
        category: '',
        imageUrls: [],
        size: '',
        paperType: '',
      ),
    );
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}