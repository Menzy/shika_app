import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kukuo/screens/add_coins_screen.dart.dart';
import 'package:kukuo/screens/home_screen.dart';
import 'package:kukuo/screens/all_assets_screen.dart';
import 'package:kukuo/screens/papertrail_screen.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;
  bool _isAdding = false; // State variable to manage add/check icon state

  // GlobalKey to access AddCoinsScreenState
  final GlobalKey<AddCoinsScreenState> _addCoinsScreenKey =
      GlobalKey<AddCoinsScreenState>();

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isAdding = (index == 3); // Only enable adding state if on AddCoinsScreen
    });
  }

  // List of screens for bottom navigation
  late final List<Widget> _screens = [
    HomeScreen(
      onSeeAllPressed: () => _onItemTapped(1), // Go to AllAssetsScreen
    ),
    const AllAssetsScreen(),
    const PaperTrailScreen(),
    AddCoinsScreen(
      key: _addCoinsScreenKey, // Assign the GlobalKey to AddCoinsScreen
      onSubmitSuccess: () => _onItemTapped(0), // Go back to the HomeScreen
    ),
  ];

  void _onAddPressed() {
    if (_selectedIndex == 3 && _isAdding) {
      // Call the submit function via GlobalKey
      _addCoinsScreenKey.currentState?.submitInput();
      setState(() {
        _isAdding = false; // Change back to add icon after submission
      });
    } else {
      setState(() {
        _selectedIndex = 3; // Go to AddCoinsScreen
        _isAdding = true; // Change to check icon
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double pillWidth = MediaQuery.of(context).size.width * 0.43;
    const double buttonSize = 50; // Match the height of the pill container

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 30,
            left: (MediaQuery.of(context).size.width - pillWidth) / 2,
            child: Container(
              width: pillWidth,
              height: buttonSize, // Set height to match the button size
              decoration: BoxDecoration(
                color: const Color(0xFF000D0C),
                borderRadius: BorderRadius.circular(35),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Iconsax.home,
                        color: _selectedIndex == 0
                            ? const Color(0xFFD8FE00)
                            : const Color(0xFF00514F)),
                    onPressed: () => _onItemTapped(0),
                  ),
                  IconButton(
                    icon: Icon(Iconsax.chart,
                        color: _selectedIndex == 1
                            ? const Color(0xFFD8FE00)
                            : const Color(0xFF00514F)),
                    onPressed: () => _onItemTapped(1),
                  ),
                  IconButton(
                    icon: Icon(Iconsax.personalcard,
                        color: _selectedIndex == 2
                            ? const Color(0xFFD8FE00)
                            : const Color(0xFF00514F)),
                    onPressed: () => _onItemTapped(2),
                  ),
                ],
              ),
            ),
          ),

          // Custom Icon Button positioned to the right of the pill navbar
          Positioned(
            bottom: 30, // Align with the bottom of the pill navbar
            left: (MediaQuery.of(context).size.width - pillWidth) / 2 +
                pillWidth +
                11, // Position 11px to the right of the pill
            child: GestureDetector(
              onTap: _onAddPressed, // Handle icon tap logic
              child: Container(
                width: buttonSize, // Match the button size
                height: buttonSize, // Match the button size
                decoration: const BoxDecoration(
                  color: Color(0xFFD8FE00),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    _isAdding ? Icons.check : Icons.add,
                    key: ValueKey<bool>(
                        _isAdding), // Unique key for AnimatedSwitcher
                    size: 30,
                    color: const Color(0xFF00312F),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
