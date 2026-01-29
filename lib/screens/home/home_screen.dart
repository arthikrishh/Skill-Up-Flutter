import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_up_flutter/constants/app_colors.dart';
import 'package:skill_up_flutter/models/product_model.dart';
import 'package:skill_up_flutter/providers/auth_provider.dart';
import 'package:skill_up_flutter/providers/cart_provider.dart';
import 'package:skill_up_flutter/providers/product_provider.dart';
import 'package:skill_up_flutter/screens/products/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  int _selectedCategoryIndex = 0;
  double _scrollOffset = 0.0;
  bool _showSearchBar = false;

  // Animation controllers
  late AnimationController _bounceController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.all_inclusive, 'color': AppColors.primary},
    {'name': 'Classic', 'icon': Icons.camera_alt, 'color': AppColors.secondary},
    {'name': 'Mini', 'icon': Icons.crop_3_2, 'color': AppColors.accent},
    {'name': 'Square', 'icon': Icons.crop_square, 'color': Colors.purpleAccent},
    {'name': 'Wide', 'icon': Icons.crop_16_9, 'color': Colors.orangeAccent},
    {'name': 'Special', 'icon': Icons.star, 'color': Colors.pinkAccent},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize animations - NON-LATE INITIALIZATION
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_fadeController);

    // Start fade animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _fadeController.isDismissed) {
        _fadeController.forward();
      }
    });
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
        _showSearchBar = _scrollController.offset > 50;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _bounceController.dispose();
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          return Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (productProvider.isLoading) {
                return _buildLoadingScreen();
              }

              List<ProductModel> displayProducts =
                  _selectedCategoryIndex == 0
                      ? productProvider.products
                      : productProvider.getProductsByCategory(
                        _categories[_selectedCategoryIndex]['name'],
                      );

              return NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollUpdateNotification) {
                    _onScroll();
                  }
                  return false;
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Animated App Bar
                    SliverAppBar(
                      floating: false,
                      pinned: true,
                      snap: false,
                      expandedHeight: 180.0,
                      backgroundColor: AppColors.background,
                      elevation: 0,
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          final safeTop = MediaQuery.of(context).padding.top;
                          final expandedHeight = 180.0;
                          const toolbarHeight = kToolbarHeight;

                          // Calculate scroll percentage (0 = fully expanded, 1 = fully collapsed)
                          final scrollPercentage =
                              (expandedHeight - constraints.biggest.height) /
                              (expandedHeight - toolbarHeight);

                          return Stack(
                            children: [
                              _buildAppBarContent(cartProvider),

                              // Collapsing title
                              if (constraints.biggest.height < expandedHeight)
                                Positioned(
                                  top: safeTop,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: toolbarHeight,
                                    alignment: Alignment.center,
                                    child: Opacity(
                                      opacity: (scrollPercentage * 2).clamp(
                                        0,
                                        1,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppColors.primary,
                                                  AppColors.secondary,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'POLAROID',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      bottom: PreferredSize(
                        preferredSize: Size.fromHeight(
                          _showSearchBar ? 80 : 60,
                        ),
                        child: _buildSearchBar(),
                      ),
                    ),
                    // Categories with sticky header
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: CategoriesHeaderDelegate(
                        child: _buildCategories(),
                      ),
                    ),

                    // Popular Section
                    if (productProvider.popularProducts.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _buildPopularSection(
                          productProvider,
                          cartProvider,
                        ),
                      ),

                    // Explore Collection Header
                    SliverToBoxAdapter(child: _buildExploreHeader()),

                    // Products Grid
                    _searchController.text.isEmpty
                        ? _buildProductGrid(displayProducts, cartProvider)
                        : _buildProductGrid(
                          productProvider.searchProducts(
                            _searchController.text,
                          ),
                          cartProvider,
                        ),

                    // Bottom spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              );
            },
          );
        },
      ),
      // Floating Action Button for cart
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          // Get cart item count
          final itemCount = _getCartItemCount(cartProvider);

          return Transform.translate(
            offset: Offset(0, _scrollOffset > 100 ? 100 : 0),
            child: Opacity(
              opacity: _scrollOffset > 100 ? 0 : 1,
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: FloatingActionButton.extended(
                      onPressed: () {
                        Navigator.pushNamed(context, '/cart');
                      },
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      icon: Badge(
                        label: Text(itemCount.toString()),
                        backgroundColor: AppColors.accent,
                        child: const Icon(Icons.shopping_bag_outlined),
                      ),
                      label: const Text('View Cart'),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Helper method to get cart item count
  int _getCartItemCount(CartProvider cartProvider) {
    // Try different possible property names
    try {
      // Only cartItems exists in CartProvider
      return cartProvider.cartItems.length;
    } catch (e) {
      // Return 0 if there's an error
      return 0;
    }
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _bounceController.value * 6.28,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                        AppColors.accent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_enhance,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Loading Polaroids...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '📸✨ Get ready for instant memories!',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarContent(CartProvider cartProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.secondary.withOpacity(0.1),
            AppColors.accent.withOpacity(0.1),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'POLAROID',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          '🎞️ Instant Memories',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: AppColors.background),
      child: Center(
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search polaroids...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 15,
              ),
              prefixIcon: Icon(Icons.search, color: AppColors.primary),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                      : Icon(
                        Icons.tune,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 13,
              ),
            ),
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 80,
      color: AppColors.background,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final color = _categories[index]['color'] as Color;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategoryIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.fastOutSlowIn,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient:
                          _selectedCategoryIndex == index
                              ? LinearGradient(
                                colors: [color, color.withOpacity(0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : null,
                      color:
                          _selectedCategoryIndex == index
                              ? null
                              : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow:
                          _selectedCategoryIndex == index
                              ? [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                              : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                    ),
                    child: Icon(
                      _categories[index]['icon'],
                      color:
                          _selectedCategoryIndex == index
                              ? Colors.white
                              : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _categories[index]['name'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        _selectedCategoryIndex == index
                            ? color
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularSection(
    ProductProvider productProvider,
    CartProvider cartProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Popular This Week 🔥',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to all popular products
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      'See all →',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 10),
              physics: const BouncingScrollPhysics(),
              itemCount: productProvider.popularProducts.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right:
                        index == productProvider.popularProducts.length - 1
                            ? 20
                            : 15,
                  ),
                  child: _buildPopularProductCard(
                    productProvider.popularProducts[index],
                    cartProvider,
                    index,
                    productProvider.popularProducts.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularProductCard(
    ProductModel product,
    CartProvider cartProvider,
    int index,
    int totalProducts,
  ) {
    final isInCart = cartProvider.isProductInCart(product.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    ProductDetailScreen(product: product),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Product Image with fixed height
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(product.imageUrls.first),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Handle image error
                        },
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        // Trending Badge
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.trending_up,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'TRENDING',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Product Info with fixed padding and spacing
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product.size,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product.hasDiscount)
                                    Text(
                                      '\$${product.price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  Text(
                                    '\$${product.finalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: product.hasDiscount ? 18 : 16,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ProductDetailScreen(
                                            product: product,
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        isInCart
                                            ? AppColors.primary
                                            : AppColors.primary.withOpacity(
                                              0.1,
                                            ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isInCart
                                              ? Colors.transparent
                                              : AppColors.primary.withOpacity(
                                                0.3,
                                              ),
                                    ),
                                  ),
                                  child: Icon(
                                    isInCart ? Icons.check : Icons.add,
                                    color:
                                        isInCart
                                            ? Colors.white
                                            : AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExploreHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 30, bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.explore, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Explore Collection 🌈',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    List<ProductModel> products,
    CartProvider cartProvider,
  ) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
                const SizedBox(height: 20),
                Text(
                  'No polaroids found 😢',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Try searching something else!',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.75, // CHANGED THIS LINE
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          return _buildProductCard(products[index], cartProvider);
        }, childCount: products.length),
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, CartProvider cartProvider) {
    final isInCart = cartProvider.isProductInCart(product.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image - Fixed height
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 130, // FIXED HEIGHT
                width: double.infinity,
                color: Colors.grey[100],
                child: Image.network(
                  product.imageUrls.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Icons.photo, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
            ),
            // Content - Fixed padding, no flexible widgets
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name - Single line
                  Text(
                    product.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Size
                  Text(
                    product.size,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  // Price and button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price only
                      Text(
                        '\$${product.finalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      // Add button - smaller
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Icon(
                          isInCart ? Icons.check : Icons.add,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
