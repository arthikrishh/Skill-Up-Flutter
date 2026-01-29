import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new order
  Future<bool> createOrder(OrderModel order) async {
    try {
      await _firestore
          .collection('orders')
          .doc(order.id)
          .set(order.toMap());
      
      // Also save to user's orders subcollection
      if (_auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('orders')
            .doc(order.id)
            .set(order.toMap());
      }
      
      return true;
    } catch (e) {
      print('Error creating order: $e');
      return false;
    }
  }

  // Get user's orders
  Stream<List<OrderModel>> getUserOrders() {
    if (_auth.currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList());
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({
            'status': status,
            'updatedAt': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, 'cancelled');
      return true;
    } catch (e) {
      return false;
    }
  }
}