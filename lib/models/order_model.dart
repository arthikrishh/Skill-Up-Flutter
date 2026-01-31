import 'package:skill_up_flutter/models/cart_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double subtotal;
  final double shippingFee;
  final double tax;
  final double totalAmount;
  final String status;
  final String shippingAddress;
  final String paymentMethod;
  final String? trackingNumber;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final String? specialInstructions;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    this.shippingFee = 4.99,
    this.tax = 0.0,
    required this.totalAmount,
    this.status = 'pending',
    required this.shippingAddress,
    required this.paymentMethod,
    this.trackingNumber,
    DateTime? orderDate,
    this.deliveryDate,
    this.specialInstructions,
  }) : orderDate = orderDate ?? DateTime.now();

  // Calculate totals
  double get calculateSubtotal {
    return items.fold(0, (sum, item) => sum + item.itemTotal);
  }

  double get calculateTotal {
    return calculateSubtotal + shippingFee + tax;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'tax': tax,
      'totalAmount': totalAmount,
      'status': status,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'trackingNumber': trackingNumber,
      'orderDate': orderDate.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
  // Handle items conversion safely
  List<CartItemModel> items = [];
  if (map['items'] != null && map['items'] is List) {
    try {
      items = List<CartItemModel>.from(
        (map['items'] as List).map((item) => CartItemModel.fromMap(item)),
      );
    } catch (e) {
      print('Error parsing cart items: $e');
      items = [];
    }
  }

  // Parse dates safely
  DateTime orderDate;
  try {
    orderDate = map['orderDate'] != null 
        ? DateTime.parse(map['orderDate']) 
        : DateTime.now();
  } catch (e) {
    orderDate = DateTime.now();
  }

  DateTime? deliveryDate;
  if (map['deliveryDate'] != null) {
    try {
      deliveryDate = DateTime.parse(map['deliveryDate']);
    } catch (e) {
      deliveryDate = null;
    }
  }

  return OrderModel(
    id: map['id']?.toString() ?? '',
    userId: map['userId']?.toString() ?? '',
    items: items,
    subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
    shippingFee: (map['shippingFee'] as num?)?.toDouble() ?? 0.0,
    tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
    totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    status: map['status']?.toString() ?? 'pending',
    shippingAddress: map['shippingAddress']?.toString() ?? '',
    paymentMethod: map['paymentMethod']?.toString() ?? '',
    trackingNumber: map['trackingNumber']?.toString(),
    orderDate: orderDate,
    deliveryDate: deliveryDate,
    specialInstructions: map['specialInstructions']?.toString(),
  );
}
}