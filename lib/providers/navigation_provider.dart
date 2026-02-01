import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  int get currentIndex => _currentIndex;
  PageController get pageController => _pageController;

  void navigateToTab(int index) {
    _currentIndex = index;
    _pageController.jumpToPage(index);
    notifyListeners();
  }
}