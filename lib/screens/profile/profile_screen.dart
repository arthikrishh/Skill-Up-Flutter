import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skill_up_flutter/constants/app_colors.dart';
import 'package:skill_up_flutter/providers/auth_provider.dart';
import 'package:skill_up_flutter/screens/auth/login_screen.dart';
import 'package:skill_up_flutter/screens/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        
        if (user == null) {
          return const Center(
            child: Text('Please login to view profile'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            centerTitle: true,
           
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Profile Picture
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                _showChangePhotoDialog();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // User Name
                      Text(
                        user.displayName ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 5),
                      
                      // User Email
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 5),
                      
                      // Verification Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            user.emailVerified ? 
                              Icons.verified : Icons.warning,
                            color: user.emailVerified ? 
                              Colors.green : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            user.emailVerified ? 
                              'Verified Account' : 'Not Verified',
                            style: TextStyle(
                              color: user.emailVerified ? 
                                Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Menu Items
                Column(
                  children: [
                  _buildMenuTile(
  icon: Icons.person_outline,
  title: 'Personal Information',
  subtitle: 'Update your personal details',
  onTap: () {
    // REMOVE the dialog and use the full screen
    // _showEditProfileDialog(context, authProvider, user); // REMOVE THIS
    
    // ADD this instead:
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  },
),
                    _buildMenuTile(
                      icon: Icons.location_on_outlined,
                      title: 'Shipping Addresses',
                      subtitle: 'Manage your delivery addresses',
                      onTap: () {
                        _showShippingAddresses();
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Payment Methods',
                      subtitle: 'Manage your payment options',
                      onTap: () {
                        _showPaymentMethods();
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: 'Manage your notification preferences',
                      onTap: () {
                        _showNotificationSettings();
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.security_outlined,
                      title: 'Privacy & Security',
                      subtitle: 'Manage your privacy settings',
                      onTap: () {
                        _showPrivacySettings();
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      subtitle: 'FAQ, Contact us, About us',
                      onTap: () {
                        _showHelpSupport();
                      },
                    ),
                    _buildMenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      subtitle: 'App settings and preferences',
                      onTap: () {
                        _showAppSettings();
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // Sign Out Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showSignOutConfirmation(context, authProvider);
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: BorderSide(color: Colors.red.shade200),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Delete Account
                TextButton(
                  onPressed: () {
                    _showDeleteAccountConfirmation(context, authProvider);
                  },
                  child: const Text(
                    'Delete Account',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // App Version
                Text(
                  'Polaroid Prints v1.0.0',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  void _showChangePhotoDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
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
                'Change Profile Photo',
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
                  // Implement camera functionality
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement gallery picker
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement remove photo
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

  
  void _showSignOutConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? '
          'This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Implement delete account functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion feature coming soon!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showShippingAddresses() {
    // Implement shipping addresses screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shipping addresses feature coming soon!'),
      ),
    );
  }

  void _showPaymentMethods() {
    // Implement payment methods screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment methods feature coming soon!'),
      ),
    );
  }

  void _showNotificationSettings() {
    // Implement notification settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings feature coming soon!'),
      ),
    );
  }

  void _showPrivacySettings() {
    // Implement privacy settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Privacy settings feature coming soon!'),
      ),
    );
  }

  void _showHelpSupport() {
    // Implement help & support screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Help & support feature coming soon!'),
      ),
    );
  }

  void _showAppSettings() {
    // Implement app settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App settings feature coming soon!'),
      ),
    );
  }
}