// constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Modern pastel/neon color scheme
  static const Color primary = Color(0xFF6C63FF); // Modern purple
  static const Color secondary = Color(0xFFFF6584); // Coral pink
  static const Color accent = Color(0xFF36D1DC); // Cyan blue

  // Background and surface
  static const Color background = Color(0xFFFAFAFF); // Off-white
  static const Color surface = Colors.white;

  // Text
  static const Color textPrimary = Color(0xFF2D2B55); // Dark blue/purple
  static const Color textSecondary = Color(0xFF8C8AA7); // Muted purple

  // Additional accent colors
  static const Color success = Color(0xFF4CD964);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
}

class CategoriesHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  CategoriesHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.background, child: child);
  }

  @override
  double get maxExtent => 80;

  @override
  double get minExtent => 80;

  @override
  bool shouldRebuild(CategoriesHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
