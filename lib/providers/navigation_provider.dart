import 'package:flutter/material.dart';
import 'package:kukuo/screens/all_assets_screen.dart';
import 'package:kukuo/screens/home_screen.dart';
import 'package:kukuo/screens/papertrail_screen.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  Widget get currentScreen {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();
      case 1:
        return const AllAssetsScreen();
      case 2:
        return const PaperTrailScreen();
      default:
        return const HomeScreen();
    }
  }

  set selectedIndex(int index) {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
    }
  }
}