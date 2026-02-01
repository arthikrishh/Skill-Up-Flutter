import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:skill_up_flutter/services/local_storage_service.dart';
import 'dart:io';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalStorageService _localStorage = LocalStorageService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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

      // Create user document in Firestore
      UserModel userModel = UserModel(
        uid: userCredential.user!.uid,
        email: email.trim(),
        displayName: name.trim(),
        phoneNumber: phone?.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        emailVerified: false,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());

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

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An error occurred. Please try again.';
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      if (_auth.currentUser != null) {
        await _auth.currentUser!.sendEmailVerification();
      }
    } catch (e) {
      throw 'Failed to send verification email: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    if (_auth.currentUser == null) return null;

    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

 // Update user profile
Future<UserModel?> updateProfile({
  String? displayName,
  String? phoneNumber,
  String? bio,
  String? photoURL,
}) async {
  try {
    if (_auth.currentUser == null) {
      print('❌ No current user');
      return null;
    }

    final userId = _auth.currentUser!.uid;
    print('👤 Current user ID: $userId');
    print('📝 Document path: users/$userId');

    final updateData = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    // Only update fields that are provided AND not empty
    if (displayName != null && displayName.trim().isNotEmpty) {
      updateData['displayName'] = displayName.trim();
      print('  ➕ Adding displayName: "${displayName.trim()}"');
    }
    
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      updateData['phoneNumber'] = phoneNumber.trim();
      print('  ➕ Adding phoneNumber: "${phoneNumber.trim()}"');
    }
    
    // Handle bio differently - if bio is provided (even empty string), update it
    if (bio != null) {
      updateData['bio'] = bio.trim();
      print('  ➕ Adding bio: "${bio.trim()}"');
    }
    
    if (photoURL != null) {
      updateData['photoURL'] = photoURL;
      print('  ➕ Adding photoURL: "$photoURL"');
    }

    print('📦 Update data to save: $updateData');
    
    try {
      // Try to update
      await _firestore
          .collection('users')
          .doc(userId)
          .update(updateData);
      
      print('✅ Firestore update successful!');
      
      // Verify the update immediately
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      print('📊 Verification - Current document AFTER update:');
      print('  displayName: "${doc.data()?['displayName']}"');
      print('  phoneNumber: "${doc.data()?['phoneNumber']}"');
      print('  bio: "${doc.data()?['bio']}"');
      print('  photoURL: "${doc.data()?['photoURL']}"');
      print('  updatedAt: "${doc.data()?['updatedAt']}"');
      
    } catch (e) {
      print('❌ Firestore update error: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Error details: $e');
      
      // Re-throw the error so it can be caught by the provider
      rethrow;
    }
    
    // Return updated user data
    final updatedData = await getCurrentUserData();
    print('🔄 Returning updated user data: ${updatedData?.phoneNumber}');
    return updatedData;
  } catch (e) {
    print('❌ AuthService.updateProfile() complete error: $e');
    print('❌ Stack trace: ${e.toString()}');
    rethrow;
  }
}


// Add this to your AuthService class
Future<void> debugUserData() async {
  try {
    if (_auth.currentUser == null) {
      print('No user logged in');
      return;
    }
    
    final userDoc = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();
    
    if (userDoc.exists) {
      print('=== FIRESTORE USER DATA ===');
      print('Document ID: ${userDoc.id}');
      print('Data: ${userDoc.data()}');
      print('Fields:');
      userDoc.data()!.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });
      print('==========================');
    } else {
      print('User document not found in Firestore');
    }
  } catch (e) {
    print('Error debugging user data: $e');
  }
}
 
 Future<String?> uploadProfileImage(File imageFile) async {
    try {
      if (_auth.currentUser == null) {
        throw 'User not authenticated';
      }

      // Save to local storage instead of Firebase Storage
      final filePath = await _localStorage.saveProfileImage(
        imageFile, 
        _auth.currentUser!.uid
      );
      
      if (filePath == null) {
        throw 'Failed to save image locally';
      }
      
      print('✅ Profile image saved locally at: $filePath');
      
      // Return the local file path
      return filePath;
    } catch (e) {
      print('❌ Error saving profile image locally: $e');
      rethrow;
    }
  }
 
  // Get profile image from local storage
  Future<File?> getProfileImage() async {
    try {
      return await _localStorage.getProfileImageFile();
    } catch (e) {
      print('❌ Error getting profile image: $e');
      return null;
    }
  }

// In AuthService class, add/update this method:
Future<void> deleteProfileImage() async {
  try {
    // Call LocalStorageService to delete the image
    await _localStorage.deleteProfileImage();
    print('✅ Profile image deleted from local storage');
  } catch (e) {
    print('❌ Error deleting profile image from local storage: $e');
    rethrow;
  }
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
        return 'Password is too weak. Please use a stronger password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}