import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';


class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
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

  String _selectedPaymentMethod = 'credit_card';
  bool _saveAddress = true;
  bool _isProcessing = false;
  String? _errorMessage;

  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user != null) {
      _firstNameController.text = user.displayName?.split(' ').first ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final cartProvider = context.read<CartProvider>();

      if (authProvider.currentUser == null) {
        throw 'Please login to place an order';
      }

      if (cartProvider.cartItems.isEmpty) {
        throw 'Your cart is empty';
      }

      // Create shipping address
      final shippingAddress = '''
${_firstNameController.text.trim()} ${_lastNameController.text.trim()}
${_addressController.text.trim()}
${_cityController.text.trim()}, ${_stateController.text.trim()} ${_zipCodeController.text.trim()}
${_countryController.text.trim()}
Phone: ${_phoneController.text.trim()}
Email: ${_emailController.text.trim()}
''';

      // Calculate totals
      final subtotal = cartProvider.subtotal;
      final shippingFee = 4.99;
      final tax = subtotal * 0.08; // 8% tax
      final totalAmount = subtotal + shippingFee + tax;

      // Create order
      final order = OrderModel(
        id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
        userId: authProvider.currentUser!.uid,
        items: cartProvider.cartItems,
        subtotal: subtotal,
        shippingFee: shippingFee,
        tax: tax,
        totalAmount: totalAmount,
        shippingAddress: shippingAddress,
        paymentMethod: _getPaymentMethodName(_selectedPaymentMethod),
        specialInstructions: _specialInstructionsController.text.isNotEmpty
            ? _specialInstructionsController.text.trim()
            : null,
      );

      // Save order to Firestore
      final success = await _orderService.createOrder(order);

      if (success && context.mounted) {
        // Clear cart
        await cartProvider.clearCart();

        // Navigate to order confirmation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(order: order),
          ),
        );
      } else {
        throw 'Failed to place order. Please try again.';
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isProcessing = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                // Shipping Address Section
                _buildSectionHeader('Shipping Address'),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    prefixIcon: Icon(Icons.home),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your city';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          labelText: 'State/Province',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your state';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _zipCodeController,
                        decoration: const InputDecoration(
                          labelText: 'ZIP/Postal Code',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your ZIP code';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                        ),
                        initialValue: 'United States',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your country';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                CheckboxListTile(
                  title: const Text('Save this address for future orders'),
                  value: _saveAddress,
                  onChanged: (value) {
                    setState(() {
                      _saveAddress = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 32),

                // Payment Method Section
                _buildSectionHeader('Payment Method'),
                const SizedBox(height: 12),

                _buildPaymentMethodTile(
                  value: 'credit_card',
                  title: 'Credit/Debit Card',
                  icon: Icons.credit_card,
                  description: 'Pay with your credit or debit card',
                ),
                _buildPaymentMethodTile(
                  value: 'paypal',
                  title: 'PayPal',
                  icon: Icons.payment,
                  description: 'Pay with your PayPal account',
                ),
                _buildPaymentMethodTile(
                  value: 'apple_pay',
                  title: 'Apple Pay',
                  icon: Icons.apple,
                  description: 'Pay with Apple Pay',
                ),
                _buildPaymentMethodTile(
                  value: 'google_pay',
                  title: 'Google Pay',
                  icon: Icons.phone_android,
                  description: 'Pay with Google Pay',
                ),
                _buildPaymentMethodTile(
                  value: 'cash_on_delivery',
                  title: 'Cash on Delivery',
                  icon: Icons.money,
                  description: 'Pay when you receive your order',
                ),

                const SizedBox(height: 32),

                // Order Instructions
                _buildSectionHeader('Order Instructions (Optional)'),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _specialInstructionsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Any special instructions for delivery or packaging?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Order Summary
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    final subtotal = cartProvider.subtotal;
                    final shippingFee = 4.99;
                    final tax = subtotal * 0.08;
                    final total = subtotal + shippingFee + tax;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Order Summary'),
                          const SizedBox(height: 12),
                          
                          _buildSummaryRow('Items', cartProvider.itemCount.toInt()),
                          _buildSummaryRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
                          _buildSummaryRow('Shipping', '\$${shippingFee.toStringAsFixed(2)}'),
                          _buildSummaryRow('Tax (8%)', '\$${tax.toStringAsFixed(2)}'),
                          
                          const Divider(height: 24),
                          
                          _buildSummaryRow(
                            'Total',
                            '\$${total.toStringAsFixed(2)}',
                            isTotal: true,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            '${cartProvider.cartItems.length} item(s) in your order',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Place Order Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _placeOrder(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'PLACE ORDER',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Security Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your payment information is secure and encrypted',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String value,
    required String title,
    required IconData icon,
    required String description,
  }) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedPaymentMethod,
      onChanged: (value) {
        setState(() {
          _selectedPaymentMethod = value!;
        });
      },
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      secondary: _getPaymentMethodIcon(value),
    );
  }

  Widget? _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'credit_card':
        return Image.asset('assets/visa.png', width: 40, height: 25);
      case 'paypal':
        return Image.asset('assets/paypal.png', width: 40, height: 25);
      case 'apple_pay':
        return Image.asset('assets/apple_pay.png', width: 40, height: 25);
      case 'google_pay':
        return Image.asset('assets/google_pay.png', width: 40, height: 25);
      default:
        return null;
    }
  }

  Widget _buildSummaryRow(String label, dynamic value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.black : Colors.grey,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value is String ? value : value.toString(),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.deepOrange : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Order Confirmation Screen
class OrderConfirmationScreen extends StatelessWidget {
  final OrderModel order;

  const OrderConfirmationScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 24),
            const Text(
              'Order Confirmed!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Order #${order.id}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you for your order!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _buildConfirmationRow('Order Total', '\$${order.totalAmount.toStringAsFixed(2)}'),
                  _buildConfirmationRow('Payment Method', order.paymentMethod),
                  _buildConfirmationRow('Estimated Delivery', '3-5 business days'),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'You will receive an email confirmation shortly with tracking information.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                    child: const Text('Continue Shopping'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to order tracking screen
                      Navigator.pushNamed(context, '/orders');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: const Text('Track Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}