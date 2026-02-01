import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _profileImageKey = 'profile_image';
  static const String _profileImagePathKey = 'profile_image_path';

  // Save profile image to local storage
  Future<String?> saveProfileImage(File imageFile, String userId) async {
    try {
      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      
      // Create unique filename
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(directory.path, fileName);
      
      // Copy image to app directory
      await imageFile.copy(filePath);
      
      // Save the file path to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImagePathKey, filePath);
      
      print('✅ Profile image saved locally: $filePath');
      return filePath;
    } catch (e) {
      print('❌ Error saving profile image locally: $e');
      return null;
    }
  }

  // Get saved profile image path
  Future<String?> getProfileImagePath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profileImagePathKey);
    } catch (e) {
      print('❌ Error getting profile image path: $e');
      return null;
    }
  }

  // Convert image to base64 and save (alternative method)
  Future<String?> saveProfileImageBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileImageKey, base64Image);
      
      print('✅ Profile image saved as base64');
      return base64Image;
    } catch (e) {
      print('❌ Error saving profile image as base64: $e');
      return null;
    }
  }

  // Get base64 image
  Future<String?> getProfileImageBase64() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_profileImageKey);
    } catch (e) {
      print('❌ Error getting base64 image: $e');
      return null;
    }
  }

  // Delete profile image
  Future<void> deleteProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Delete file if path exists
      final filePath = prefs.getString(_profileImagePathKey);
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Remove from shared preferences
      await prefs.remove(_profileImagePathKey);
      await prefs.remove(_profileImageKey);
      
      print('✅ Profile image deleted from local storage');
    } catch (e) {
      print('❌ Error deleting profile image: $e');
    }
  }

  // Clear all local storage
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ All local storage cleared');
    } catch (e) {
      print('❌ Error clearing local storage: $e');
    }
  }

  // Check if profile image exists
  Future<bool> hasProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPath = prefs.containsKey(_profileImagePathKey);
      final hasBase64 = prefs.containsKey(_profileImageKey);
      return hasPath || hasBase64;
    } catch (e) {
      print('❌ Error checking profile image: $e');
      return false;
    }
  }

  // Get profile image as File
  Future<File?> getProfileImageFile() async {
    try {
      final filePath = await getProfileImagePath();
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          return file;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting profile image file: $e');
      return null;
    }
  }

  // Get profile image as bytes
  Future<Uint8List?> getProfileImageBytes() async {
    try {
      final file = await getProfileImageFile();
      if (file != null) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print('❌ Error getting profile image bytes: $e');
      return null;
    }
  }
}

 