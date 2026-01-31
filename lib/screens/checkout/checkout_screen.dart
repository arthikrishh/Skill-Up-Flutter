import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen>
    with SingleTickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  // Focus nodes for text fields
  late FocusNode _firstNameFocusNode;
  late FocusNode _lastNameFocusNode;
  late FocusNode _emailFocusNode;
  late FocusNode _phoneFocusNode;
  late FocusNode _addressFocusNode;
  late FocusNode _cityFocusNode;
  late FocusNode _stateFocusNode;
  late FocusNode _zipCodeFocusNode;
  late FocusNode _countryFocusNode;

  String _selectedPaymentMethod = 'credit_card';
  bool _saveAddress = true;
  bool _isProcessing = false;
  String? _errorMessage;
  int _currentStep = 0;
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late ConfettiController _confettiController;
  bool _showDeliveryAnimation = false;
  double _deliveryProgress = 0.0;
  bool _userIsTyping = false; // Flag to track if user is typing

  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _countryController.text = 'United States';

    // Initialize focus nodes
    _firstNameFocusNode = FocusNode();
    _lastNameFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    _phoneFocusNode = FocusNode();
    _addressFocusNode = FocusNode();
    _cityFocusNode = FocusNode();
    _stateFocusNode = FocusNode();
    _zipCodeFocusNode = FocusNode();
    _countryFocusNode = FocusNode();

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 50, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    // Dispose all focus nodes
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _cityFocusNode.dispose();
    _stateFocusNode.dispose();
    _zipCodeFocusNode.dispose();
    _countryFocusNode.dispose();

    // Dispose controllers
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _countryController.dispose();
    _specialInstructionsController.dispose();
    _animationController.dispose();
    _confettiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null) {
      _firstNameController.text = user.displayName?.split(' ').first ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  void _nextStep() {
    // Unfocus any active text field
    FocusScope.of(context).unfocus();
    setState(() {
      _userIsTyping = false;
    });

    // Validate current step before proceeding
    if (_currentStep == 0 && !_validateDeliveryFields()) {
      // Show error for delivery step
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage ?? 'Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _previousStep() {
    // Unfocus any active text field
    FocusScope.of(context).unfocus();
    setState(() {
      _userIsTyping = false;
    });

    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _pageController.previousPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  bool _validateDeliveryFields() {
    if (_firstNameController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your first name';
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your last name';
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your email address';
      return false;
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      _errorMessage = 'Please enter a valid email address';
      return false;
    }
    if (_phoneController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your phone number';
      return false;
    }
    if (_addressController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your street address';
      return false;
    }
    if (_cityController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your city';
      return false;
    }
    if (_stateController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your state';
      return false;
    }
    if (_zipCodeController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your ZIP code';
      return false;
    }
    if (_countryController.text.trim().isEmpty) {
      _errorMessage = 'Please enter your country';
      return false;
    }

    _errorMessage = null;
    return true;
  }

  void _playDeliveryAnimation() {
    // Reset and start animation
    setState(() {
      _showDeliveryAnimation = true;
      _deliveryProgress = 0.0;
    });

    // Animate delivery progress
    Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_deliveryProgress < 1.0) {
        setState(() {
          _deliveryProgress += 0.015; // Slower for better visibility
        });
      } else {
        timer.cancel();
        // Don't auto-hide, let user see completion
      }
    });
  }

  Future<void> _placeOrder(BuildContext context) async {
    // Unfocus all text fields before showing animation
    FocusScope.of(context).unfocus();
    setState(() {
      _userIsTyping = false;
    });

    // Validate all fields before placing order
    if (!_validateDeliveryFields()) {
      // Navigate back to delivery step
      setState(() {
        _currentStep = 0;
      });
      _pageController.jumpToPage(0);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Please fill all required fields'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final cartProvider = context.read<CartProvider>();

      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        throw Exception('Please login to place an order');
      }

      final cartItems = cartProvider.cartItems;
      if (cartItems.isEmpty) {
        throw Exception('Your cart is empty');
      }

      final subtotal = cartProvider.subtotal;
      final shippingFee = 4.99;
      final tax = subtotal * 0.08;
      final totalAmount = subtotal + shippingFee + tax;

      // Create shipping address
      final shippingAddress = '''
${_firstNameController.text.trim()} ${_lastNameController.text.trim()}
${_addressController.text.trim()}
${_cityController.text.trim()}, ${_stateController.text.trim()} ${_zipCodeController.text.trim()}
${_countryController.text.trim()}
Phone: ${_phoneController.text.trim()}
Email: ${_emailController.text.trim()}
''';

      // Create order
      final order = OrderModel(
        id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
        userId: currentUser.uid,
        items: cartItems,
        subtotal: subtotal,
        shippingFee: shippingFee,
        tax: tax,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        paymentMethod: _getPaymentMethodName(_selectedPaymentMethod),
        specialInstructions:
            _specialInstructionsController.text.isNotEmpty
                ? _specialInstructionsController.text.trim()
                : null,
      );

      // SHOW ANIMATION FIRST (before Firestore operations)
      _playDeliveryAnimation();
      _confettiController.play();

      // Save order to Firestore AFTER animation starts
      final success = await _orderService.createOrder(order);

      if (success) {
        // Clear cart
        await cartProvider.clearCart();

        // Complete the progress animation
        setState(() {
          _deliveryProgress = 1.0;
        });

        // Wait for animation to complete
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Navigate to order confirmation
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) =>
                      OrderConfirmationScreen(order: order),
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
        }
      } else {
        throw Exception('Failed to save order. Please try again.');
      }
    } catch (e) {
      // Hide animation on error
      setState(() {
        _showDeliveryAnimation = false;
        _isProcessing = false;
        _errorMessage = e.toString();
      });

      // Debug logging
      print('Order placement error details:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      // Show error to user
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _errorMessage?.replaceAll('Exception: ', '') ??
                    'An error occurred',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(20),
            ),
          );
        });
      }
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'credit_card':
        return 'Credit Card';
      case 'paypal':
        return 'PayPal';
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      default:
        return 'Credit Card';
    }
  }

  Widget _buildCheckoutProgress() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildProgressStep(0, 'Delivery'),
              _buildProgressStep(1, 'Payment'),
              _buildProgressStep(2, 'Review'),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              alignment: Alignment.centerLeft,
              child: Container(
                width:
                    (MediaQuery.of(context).size.width * 0.9) *
                    ((_currentStep + 1) / 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7B61FF), Color(0xFFFF6B9D)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                _currentStep >= step
                    ? const Color(0xFF7B61FF)
                    : Colors.grey[300],
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  _currentStep > step
                      ? const Color(0xFF7B61FF)
                      : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              _currentStep > step ? Icons.check : Icons.circle,
              size: _currentStep > step ? 20 : 16,
              color: _currentStep >= step ? Colors.white : Colors.grey[500],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color:
                _currentStep >= step
                    ? const Color(0xFF7B61FF)
                    : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFF),
      body: Stack(
        children: [
          // Main Content
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value),
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                // App Bar
                Container(
                  padding: const EdgeInsets.only(
                    top: 48,
                    left: 20,
                    right: 20,
                    bottom: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.black,
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Checkout',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF7B61FF,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${cartProvider.cartItems.length} items',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF7B61FF),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildCheckoutProgress(),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildDeliveryStep(),
                      _buildPaymentStep(),
                      _buildReviewStep(),
                    ],
                  ),
                ),

                // Navigation Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _currentStep < 2
                                  ? _nextStep
                                  : () {
                                    // For the final step, place the order
                                    _placeOrder(context);
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B61FF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentStep < 2 ? 'Continue' : 'Place Order',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confetti - Only show if user is not typing
          if (!_userIsTyping)
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 40,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Color(0xFF7B61FF),
                Color(0xFFFF6B9D),
                Color(0xFF00E0FF),
                Colors.amber,
              ],
            ),

          // Delivery Animation - Only show if user is not typing (will appear in front)
          if (_showDeliveryAnimation && !_userIsTyping)
            _buildDeliveryAnimation(),
        ],
      ),
    );
  }

  Widget _buildDeliveryAnimation() {
    return Container(
      color: Colors.black.withOpacity(
        0.85,
      ), // Darker background for better contrast
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Instax Camera Printing Animation
            Container(
              width: 250, // Increased size
              height: 250,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 5,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Camera body
                  Container(
                    margin: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  // Film ejection animation
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOut,
                    left: _deliveryProgress * 120,
                    right: _deliveryProgress * -120,
                    child: Transform.rotate(
                      angle: -0.1,
                      child: Container(
                        width: 140,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(5, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.photo_camera,
                            size: 50,
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Loading spinner overlay
                  if (_deliveryProgress < 1.0)
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF7B61FF),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Progress Bar Container
            Container(
              width: 320,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 50,
                    spreadRadius: 5,
                    offset: const Offset(0, 30),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🎞️ Processing Your Polaroids',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Animated progress with percentage
                  Stack(
                    children: [
                      LinearProgressIndicator(
                        value: _deliveryProgress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF7B61FF),
                        ),
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      Positioned.fill(
                        child: Center(
                          child: Text(
                            '${(_deliveryProgress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Status messages
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child:
                        _deliveryProgress < 0.3
                            ? const Text(
                              'Preparing your order...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            )
                            : _deliveryProgress < 0.7
                            ? const Text(
                              'Processing payment...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            )
                            : const Text(
                              'Creating your polaroids...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                  ),

                  const SizedBox(height: 12),

                  // Cancel button
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showDeliveryAnimation = false;
                        _isProcessing = false;
                      });
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Where should we deliver your prints?',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          if (_errorMessage != null && _currentStep == 0)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          Column(
            children: [
              // Name and Email Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextInput(
                      controller: _firstNameController,
                      focusNode: _firstNameFocusNode,
                      label: 'First Name*',
                      icon: Icons.person,
                      onChanged: (value) {
                        if (_errorMessage != null && value.isNotEmpty) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextInput(
                      controller: _lastNameController,
                      focusNode: _lastNameFocusNode,
                      label: 'Last Name*',
                      icon: Icons.person_outline,
                      onChanged: (value) {
                        if (_errorMessage != null && value.isNotEmpty) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email
              _buildTextInput(
                controller: _emailController,
                focusNode: _emailFocusNode,
                label: 'Email Address*',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) {
                  if (_errorMessage != null && value.isNotEmpty) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Phone
              _buildTextInput(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                label: 'Phone Number*',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  if (_errorMessage != null && value.isNotEmpty) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Address
              _buildTextInput(
                controller: _addressController,
                focusNode: _addressFocusNode,
                label: 'Street Address*',
                icon: Icons.home,
                onChanged: (value) {
                  if (_errorMessage != null && value.isNotEmpty) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // City, State, ZIP
              Row(
                children: [
                  Expanded(
                    child: _buildTextInput(
                      controller: _cityController,
                      focusNode: _cityFocusNode,
                      label: 'City*',
                      onChanged: (value) {
                        if (_errorMessage != null && value.isNotEmpty) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextInput(
                      controller: _stateController,
                      focusNode: _stateFocusNode,
                      label: 'State*',
                      onChanged: (value) {
                        if (_errorMessage != null && value.isNotEmpty) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextInput(
                      controller: _zipCodeController,
                      focusNode: _zipCodeFocusNode,
                      label: 'ZIP Code*',
                      onChanged: (value) {
                        if (_errorMessage != null && value.isNotEmpty) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Country
              _buildTextInput(
                controller: _countryController,
                focusNode: _countryFocusNode,
                label: 'Country*',
                onChanged: (value) {
                  if (_errorMessage != null && value.isNotEmpty) {
                    setState(() {
                      _errorMessage = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 24),

              // Save Address Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Transform.scale(
                      scale: 1.2,
                      child: Switch(
                        value: _saveAddress,
                        onChanged: (value) {
                          setState(() {
                            _saveAddress = value;
                          });
                        },
                        activeColor: const Color(0xFF7B61FF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Save this address for future orders',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.bookmark,
                      color:
                          _saveAddress
                              ? const Color(0xFF7B61FF)
                              : Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'How would you like to pay?',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Payment Options
          Column(
            children: [
              _buildPaymentOption(
                value: 'credit_card',
                title: 'Credit/Debit Card',
                icon: Icons.credit_card_rounded,
                description: 'Pay securely with your card',
                color: const Color(0xFF7B61FF),
              ),
              _buildPaymentOption(
                value: 'paypal',
                title: 'PayPal',
                icon: Icons.payment_rounded,
                description: 'Fast checkout with PayPal',
                color: const Color(0xFF00A0E9),
              ),
              _buildPaymentOption(
                value: 'apple_pay',
                title: 'Apple Pay',
                icon: Icons.apple,
                description: 'Pay with Apple Pay',
                color: Colors.black,
              ),
              _buildPaymentOption(
                value: 'google_pay',
                title: 'Google Pay',
                icon: Icons.phone_android_rounded,
                description: 'Pay with Google Pay',
                color: const Color(0xFF4285F4),
              ),
              _buildPaymentOption(
                value: 'cash_on_delivery',
                title: 'Cash on Delivery',
                icon: Icons.money_rounded,
                description: 'Pay when you receive',
                color: const Color(0xFF34C759),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Security Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF7B61FF).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B61FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Secure Payment',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your payment information is encrypted and secure',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review your order before placing',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),

          // Order Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Consumer<CartProvider>(
              builder: (context, cartProvider, child) {
                final cartItems = cartProvider.cartItems;
                final subtotal = cartProvider.subtotal;
                final shippingFee = 4.99;
                final tax = subtotal * 0.08;
                final total = subtotal + shippingFee + tax;

                if (cartItems.isEmpty) {
                  return const Center(child: Text('Your cart is empty'));
                }

                return Column(
                  children: [
                    // Order Items Preview
                    for (int i = 0; i < cartItems.length && i < 3; i++)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    cartItems[i].productImage,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cartItems[i].productName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Quantity: ${cartItems[i].quantity}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${(cartItems[i].price * cartItems[i].quantity).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (cartItems.length > 3)
                      Text(
                        '+ ${cartItems.length - 3} more items',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Price Breakdown
                    _buildPriceRow(
                      'Subtotal',
                      '\$${subtotal.toStringAsFixed(2)}',
                    ),
                    _buildPriceRow(
                      'Shipping',
                      '\$${shippingFee.toStringAsFixed(2)}',
                    ),
                    _buildPriceRow('Tax (8%)', '\$${tax.toStringAsFixed(2)}'),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF7B61FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Shipping Address Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shipping Address',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _addressController.text.trim(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_cityController.text.trim()}, ${_stateController.text.trim()} ${_zipCodeController.text.trim()}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  _countryController.text.trim(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Phone: ${_phoneController.text.trim()}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  'Email: ${_emailController.text.trim()}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment Method Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B61FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedPaymentMethod == 'credit_card'
                            ? Icons.credit_card_rounded
                            : _selectedPaymentMethod == 'paypal'
                            ? Icons.payment_rounded
                            : _selectedPaymentMethod == 'apple_pay'
                            ? Icons.apple
                            : _selectedPaymentMethod == 'google_pay'
                            ? Icons.phone_android_rounded
                            : Icons.money_rounded,
                        color: const Color(0xFF7B61FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getPaymentMethodName(_selectedPaymentMethod),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Special Instructions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Special Instructions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _specialInstructionsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any special notes for your order...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7B61FF)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Place Order Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : () => _placeOrder(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B61FF),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child:
                  _isProcessing
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 24,
                            color: Colors.white,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    FocusNode? focusNode,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onTap: () {
          // Set flag when user starts typing
          setState(() {
            _userIsTyping = true;
          });
        },
        onEditingComplete: () {
          // Clear flag when done editing
          setState(() {
            _userIsTyping = false;
          });
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[500]) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF7B61FF), width: 2),
          ),
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required IconData icon,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedPaymentMethod = value;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _selectedPaymentMethod == value ? color : Colors.grey[200]!,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              _selectedPaymentMethod == value
                                  ? color
                                  : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                if (_selectedPaymentMethod == value)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class OrderConfirmationScreen extends StatefulWidget {
  final OrderModel order;

  const OrderConfirmationScreen({Key? key, required this.order})
    : super(key: key);

  @override
  _OrderConfirmationScreenState createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _animationController.forward();
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFF),
      body: Stack(
        children: [
          // Confetti Celebration
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.03,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: const [
              Color(0xFF7B61FF),
              Color(0xFFFF6B9D),
              Color(0xFF00E0FF),
              Colors.amber,
              Colors.green,
            ],
          ),

          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // Success Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B61FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B61FF).withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Order Confirmed! 🎉',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Order Number
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B61FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Order #${widget.order.id.substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7B61FF),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Your polaroids are on their way!',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // Order Details Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Order Summary
                          _buildOrderDetailRow(
                            'Order Total',
                            '\$${widget.order.totalAmount.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          const SizedBox(height: 12),
                          _buildOrderDetailRow(
                            'Payment Method',
                            widget.order.paymentMethod,
                          ),
                          const SizedBox(height: 12),
                          _buildOrderDetailRow(
                            'Items Ordered',
                            '${widget.order.items.length} items',
                          ),
                          const SizedBox(height: 12),
                          _buildOrderDetailRow(
                            'Delivery Time',
                            '3-5 business days',
                          ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 24),

                          // Shipping Address
                          const Text(
                            'Shipping to',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.order.shippingAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Tracking Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7B61FF).withOpacity(0.1),
                            const Color(0xFFFF6B9D).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_shipping_rounded,
                            size: 40,
                            color: Color(0xFF7B61FF),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Track Your Order',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You\'ll receive tracking information via email',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // CTA Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/home',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B61FF),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Continue Shopping',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/orders');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: const BorderSide(color: Color(0xFF7B61FF)),
                            ),
                            child: const Text(
                              'View Order History',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7B61FF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(Icons.close_rounded, color: Colors.black),
              ),
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: isBold ? const Color(0xFF7B61FF) : Colors.black,
          ),
        ),
      ],
    );
  }
}
