import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_up_flutter/providers/auth_provider.dart';
import 'package:skill_up_flutter/providers/cart_provider.dart';
import 'package:skill_up_flutter/providers/navigation_provider.dart';
import 'package:skill_up_flutter/screens/cart/cart_screen.dart';
import 'package:skill_up_flutter/screens/home/home_screen.dart';
import 'package:skill_up_flutter/screens/orders/orders_screen.dart';
import 'package:skill_up_flutter/screens/profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const HomeScreen(),
    const CartScreen(),
    const OrdersScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        return Scaffold(
          body: PageView(
            controller: navProvider.pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _screens,
            onPageChanged: (index) {
              navProvider.navigateToTab(index);
            },
          ),
          bottomNavigationBar: _buildBottomNavigationBar(navProvider),
        );
      },
    );
  }
  // **UPDATED METHOD WITH CART BADGE**
  Widget _buildBottomNavigationBar(NavigationProvider navProvider) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            // Calculate total items in cart
            final cartItemCount = _calculateCartItemCount(cartProvider);
            
            return BottomNavigationBar(
                currentIndex: navProvider.currentIndex,
        onTap: (index) {
          navProvider.navigateToTab(index);
        },
              type: BottomNavigationBarType.fixed,
           
              backgroundColor: Colors.white,
              selectedItemColor: Colors.deepOrange,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              items: [
                // Home Tab
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home),
                  label: 'Home',
                ),
                
                // Cart Tab with Badge
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.shopping_bag_outlined),
                      ),
                      if (cartItemCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                cartItemCount > 9 ? '9+' : cartItemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  activeIcon: Stack(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(Icons.shopping_bag),
                      ),
                      if (cartItemCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Center(
                              child: Text(
                                cartItemCount > 9 ? '9+' : cartItemCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  label: 'Cart',
                ),
                
                // Orders Tab
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long_outlined),
                  activeIcon: const Icon(Icons.receipt_long),
                  label: 'Orders',
                ),
                
                // Profile Tab
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline),
                  activeIcon: const Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

int _calculateCartItemCount(CartProvider cartProvider) {
  try {
    int totalQuantity = 0;
    
    // Iterate through cart items
    for (var item in cartProvider.cartItems) {
      // Access the quantity property directly from CartItemModel
      // Make sure to cast to int
      if (item.quantity != null) {
        // Convert to int (if quantity is double, round it)
        totalQuantity += item.quantity.toInt();
      } else {
        totalQuantity += 1; // Default to 1 if quantity is null
      }
    }
    
    return totalQuantity;
  } catch (e) {
    print('Error calculating cart item count: $e');
    // Fallback: return number of items (not quantities)
    return cartProvider.cartItems.length;
  }
}
}