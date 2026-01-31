import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new order
  Future<bool> createOrder(OrderModel order) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Save to Firestore under user's orders subcollection
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('orders')
          .doc(order.id)
          .set(order.toMap());

      // ALSO save to top-level orders collection for global access
      await _firestore
          .collection('orders')
          .doc(order.id)
          .set({
            ...order.toMap(),
            'userId': currentUser.uid, // Make sure userId is included
          });

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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get order by ID - FIXED: Check both user's orders and global orders
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      // First try to get from user's orders
      final userOrderDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('orders')
          .doc(orderId)
          .get();

      if (userOrderDoc.exists) {
        return OrderModel.fromMap(userOrderDoc.data()!);
      }

      // If not found in user's orders, try global orders collection
      final globalOrderDoc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (globalOrderDoc.exists) {
        return OrderModel.fromMap(globalOrderDoc.data()!);
      }

      return null;
    } catch (e) {
      print('Error getting order by ID: $e');
      return null;
    }
  }

  // Update order status - FIXED: Update both user's orders and global orders
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final updateData = {
        'status': status,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // Update in user's orders
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('orders')
          .doc(orderId)
          .update(updateData);

      // Update in global orders
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update(updateData);

      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      await updateOrderStatus(orderId, 'cancelled');
      return true;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }

  // NEW: Get all orders for admin purposes
  Stream<List<OrderModel>> getAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data()))
              .toList(),
        );
  }
}