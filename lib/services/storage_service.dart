import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload profile image
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Delete old profile image if exists
      await _deleteOldProfileImage(userId);

      // Upload new image
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/profile/$fileName');
      
      await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      return await ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload image: $e';
    }
  }

  // Delete old profile images
  Future<void> _deleteOldProfileImage(String userId) async {
    try {
      final listResult = await _storage
          .ref()
          .child('users/$userId/profile')
          .listAll();

      // Delete all files in the profile folder
      for (var item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // Ignore error if folder doesn't exist
      print('No old profile images to delete: $e');
    }
  }

  // Delete user's profile image
  Future<void> deleteProfileImage(String userId) async {
    try {
      await _deleteOldProfileImage(userId);
    } catch (e) {
      throw 'Failed to delete profile image: $e';
    }
  }
}