import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Stream for user document changes
  Stream<UserModel?> userDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            return UserModel.fromMap(snapshot.data()!);
          }
          return null;
        });
  }

  // ==================== EMAIL/PASSWORD AUTH ====================

  // Sign up with email and password
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user in Firestore
      UserModel userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email.trim(),
        displayName: name.trim(),
        phoneNumber: phone?.trim(),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _saveUserToFirestore(userModel);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update last login time
      await _updateUserLastLogin(userCredential.user!.uid);

      // Get user data
      return await _getUserFromFirestore(userCredential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  // ==================== GOOGLE SIGN IN ====================

  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);

      // Check if user is new
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      UserModel userModel;
      
      if (isNewUser) {
        // Create new user in Firestore
        userModel = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          displayName: userCredential.user!.displayName,
          photoURL: userCredential.user!.photoURL,
          phoneNumber: userCredential.user!.phoneNumber,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          emailVerified: userCredential.user!.emailVerified,
        );
        
        await _saveUserToFirestore(userModel);
      } else {
        // Update existing user's last login
        await _updateUserLastLogin(userCredential.user!.uid);
        userModel = await _getUserFromFirestore(userCredential.user!.uid) ??
          UserModel(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email!,
            displayName: userCredential.user!.displayName,
            photoURL: userCredential.user!.photoURL,
            phoneNumber: userCredential.user!.phoneNumber,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            emailVerified: userCredential.user!.emailVerified,
          );
      }

      return userModel;
    } catch (e) {
      throw 'Google sign in failed. Please try again.';
    }
  }

  // ==================== PASSWORD RESET ====================

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  // ==================== USER MANAGEMENT ====================

  // Get current user data
  Future<UserModel?> getCurrentUserData() async {
    if (_auth.currentUser == null) return null;
    return await _getUserFromFirestore(_auth.currentUser!.uid);
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      if (_auth.currentUser == null) return;

      // Update in Firebase Auth
      if (displayName != null) {
        await _auth.currentUser!.updateDisplayName(displayName);
      }
      if (photoURL != null) {
        await _auth.currentUser!.updatePhotoURL(photoURL);
      }

      // Update in Firestore
      final Map<String, dynamic> updates = {
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      if (displayName != null) updates['displayName'] = displayName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (photoURL != null) updates['photoURL'] = photoURL;

      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update(updates);
    } catch (e) {
      throw 'Failed to update profile';
    }
  }

  // Update email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Failed to update email';
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Failed to update password';
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      await _firestore.collection('users').doc(_auth.currentUser!.uid).delete();
      await _auth.currentUser!.delete();
    } catch (e) {
      throw 'Failed to delete account';
    }
  }

  // ==================== E-COMMERCE METHODS ====================

  // Add to cart
  Future<void> addToCart(String productId, {int quantity = 1}) async {
    try {
      final userId = _auth.currentUser!.uid;
      final userDoc = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        
        if (!snapshot.exists) return;
        
        final data = snapshot.data()!;
        final cartItems = List<String>.from(data['cartItems'] ?? []);
        final cartQuantities = Map<String, int>.from(data['cartQuantities'] ?? {});
        
        if (!cartItems.contains(productId)) {
          cartItems.add(productId);
        }
        
        cartQuantities[productId] = (cartQuantities[productId] ?? 0) + quantity;
        
        transaction.update(userDoc, {
          'cartItems': cartItems,
          'cartQuantities': cartQuantities,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      throw 'Failed to add item to cart';
    }
  }

  // Remove from cart
  Future<void> removeFromCart(String productId) async {
    try {
      final userId = _auth.currentUser!.uid;
      final userDoc = _firestore.collection('users').doc(userId);
      
      await userDoc.update({
        'cartItems': FieldValue.arrayRemove([productId]),
        'cartQuantities.${productId}': FieldValue.delete(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to remove item from cart';
    }
  }

  // Update cart quantity
  Future<void> updateCartQuantity(String productId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeFromCart(productId);
        return;
      }
      
      final userId = _auth.currentUser!.uid;
      final userDoc = _firestore.collection('users').doc(userId);
      
      await userDoc.update({
        'cartQuantities.${productId}': quantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to update cart quantity';
    }
  }

  // Toggle favorite
  Future<void> toggleFavorite(String productId) async {
    try {
      final userId = _auth.currentUser!.uid;
      final userDoc = _firestore.collection('users').doc(userId);
      
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        
        if (!snapshot.exists) return;
        
        final data = snapshot.data()!;
        final favorites = List<String>.from(data['favoriteProducts'] ?? []);
        
        if (favorites.contains(productId)) {
          favorites.remove(productId);
        } else {
          favorites.add(productId);
        }
        
        transaction.update(userDoc, {
          'favoriteProducts': favorites,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      throw 'Failed to update favorites';
    }
  }

  // Add address
  Future<void> addAddress(String address) async {
    try {
      final userId = _auth.currentUser!.uid;
      final userDoc = _firestore.collection('users').doc(userId);
      
      await userDoc.update({
        'addresses': FieldValue.arrayUnion([address]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to add address';
    }
  }

  // Remove address
  Future<void> removeAddress(String address) async {
    try {
      final userId = _auth.currentUser!.uid;
      final userDoc = _firestore.collection('users').doc(userId);
      
      await userDoc.update({
        'addresses': FieldValue.arrayRemove([address]),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw 'Failed to remove address';
    }
  }

  // ==================== HELPER METHODS ====================

  Future<void> _saveUserToFirestore(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap());
  }

  Future<UserModel?> _getUserFromFirestore(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      
      if (snapshot.exists) {
        return UserModel.fromMap(snapshot.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateUserLastLogin(String uid) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .update({
          'lastLoginAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Handle auth errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}