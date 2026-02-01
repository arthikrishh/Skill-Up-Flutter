import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_up_flutter/constants/app_colors.dart';
import 'package:skill_up_flutter/providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  File? _profileImage;
  bool _isLoading = false;
  String? _profileImageUrl;
  bool _emailVerified = false;

 @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProfileImageFromLocal();
  }

Future<void> _loadProfileImageFromLocal() async {
  try {
    final authProvider = context.read<AuthProvider>();
    
    // Try to get image from AuthProvider (which loads from local storage)
    final imageFile = await authProvider.getProfileImage();
    
    if (imageFile != null && await imageFile.exists()) {
      setState(() {
        _profileImageUrl = imageFile.path;
      });
      print('✅ Loaded profile image from local storage: ${imageFile.path}');
    } else {
      // Check if user has photoURL from previous Firebase storage
      final user = authProvider.currentUser;
      if (user?.photoURL != null && user!.photoURL!.startsWith('http')) {
        // This is a network URL from old Firebase storage
        setState(() {
          _profileImageUrl = user.photoURL;
        });
        print('✅ Loaded profile image from network: ${user.photoURL}');
      }
    }
  } catch (e) {
    print('❌ Error loading profile image from local: $e');
  }
}

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user != null) {
      print('📱 EditProfileScreen - Loading user data:');
      print('  displayName: "${user.displayName}"');
      print('  phoneNumber: "${user.phoneNumber}"');
      print('  bio: "${user.bio}"');
      print('  photoURL: "${user.photoURL}"');
      print('  emailVerified: ${user.emailVerified}');
      
      _nameController.text = user.displayName ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber ?? '';
      _bioController.text = user.bio ?? '';
      _profileImageUrl = user.photoURL;
      _emailVerified = user.emailVerified;
    } else {
      print('❌ EditProfileScreen - No user found');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        setState(() {
          _profileImage = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      
      print('💾 Saving profile with:');
      print('  displayName: "${_nameController.text.trim()}"');
      print('  phoneNumber: "${_phoneController.text.trim()}"');
      print('  bio: "${_bioController.text.trim()}"');
      print('  Has new image: ${_profileImage != null}');
      
      // Upload profile image to local storage if selected
      String? imageUrl = _profileImageUrl;
      if (_profileImage != null) {
        print('📤 Saving profile image to local storage...');
        imageUrl = await authProvider.uploadProfileImage(_profileImage!);
        if (imageUrl == null) {
          throw 'Failed to save profile image locally';
        }
        print('✅ Image saved locally: $imageUrl');
      }

      // Update profile in Firestore (without photoURL since it's local)
      final success = await authProvider.updateProfile(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
        photoURL: null, // Don't save local path to Firestore
      );

      if (success && mounted) {
        print('✅ Profile saved successfully!');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        throw authProvider.errorMessage ?? 'Failed to update profile';
      }
    } catch (e) {
      print('❌ Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


   

  Future<void> _resendVerificationEmail() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.sendEmailVerification();

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        throw authProvider.errorMessage ?? 'Failed to send verification email';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send verification email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerDialog() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            // Show remove option only if there's a profile image
            if (_profileImage != null || 
                (_profileImageUrl != null && _profileImageUrl!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _removeProfileImage();
                },
              ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}


Future<void> _removeProfileImage() async {
  try {
    final authProvider = context.read<AuthProvider>();
    
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Profile Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true) {
      // Show loading
      setState(() {
        _isLoading = true;
      });
      
      await authProvider.deleteProfileImage();
      
      // Clear local state
      setState(() {
        _profileImage = null;
        _profileImageUrl = null;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing image: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

  

   

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving your profile...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture Section
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _showImagePickerDialog,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: _buildProfileImage(),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImagePickerDialog,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Tap to change photo',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Email Verification Status
                    if (!_emailVerified)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Email Not Verified',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Verify your email to access all features',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _resendVerificationEmail,
                              child: const Text('Resend'),
                            ),
                          ],
                        ),
                      ),

                    // Form Fields
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email,
                      enabled: false,
                      suffixIcon: _emailVerified
                          ? const Icon(Icons.verified, color: Colors.green)
                          : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio (Optional)',
                      icon: Icons.info,
                      maxLines: 3,
                      hintText: 'Tell us about yourself...',
                    ),
                    const SizedBox(height: 30),
  
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'SAVE CHANGES',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Cancel Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

    Widget _buildProfileImage() {
  // 1. Check for newly selected image
  if (_profileImage != null) {
    return Image.file(
      _profileImage!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
  
  // 2. Check for local file path
  if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
    if (_profileImageUrl!.startsWith('/')) {
      // Local file path
      final file = File(_profileImageUrl!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        );
      }
    } else if (_profileImageUrl!.startsWith('http')) {
      // Network URL (from previous Firebase storage)
      return Image.network(
        _profileImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
  }
  
  // 3. Default avatar
  return _buildDefaultAvatar();
}

  Widget _buildDefaultAvatar() {
    final name = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'User';
    
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      child: Center(
        child: Text(
          name.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
    int maxLines = 1,
    String? hintText,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        filled: !enabled,
        fillColor: enabled ? null : Colors.grey.shade100,
      ),
      style: TextStyle(
        color: enabled ? Colors.black : Colors.grey[600],
        fontSize: 16,
      ),
      validator: validator,
    );
  }
}