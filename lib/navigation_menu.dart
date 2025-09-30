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
  bool _isAdding = false;

  final GlobalKey<AddCoinsScreenState> _addCoinsScreenKey =
      GlobalKey<AddCoinsScreenState>();

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isAdding = (index == 3);
    });
  }

  late final List<Widget> _screens = [
    HomeScreen(
      onSeeAllPressed: () => _onItemTapped(1),
    ),
    const AllAssetsScreen(),
    const PaperTrailScreen(),
    AddCoinsScreen(
      key: _addCoinsScreenKey,
      onSubmitSuccess: () => _onItemTapped(0),
    ),
  ];

  void _onAddPressed() {
    if (_selectedIndex == 3 && _isAdding) {
      _addCoinsScreenKey.currentState?.submitInput();
      setState(() {
        _isAdding = false;
      });
    } else {
      setState(() {
        _selectedIndex = 3;
        _isAdding = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double pillWidth = MediaQuery.of(context).size.width * 0.43;
    const double buttonSize = 50;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // Gradient overlay to mask content below the nav bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00001817),
                      Color(0xFF001817),
                      Color(0xFF001817),
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: (MediaQuery.of(context).size.width - pillWidth) / 2,
            child: Container(
              width: pillWidth,
              height: buttonSize,
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
          Positioned(
            bottom: 30,
            left: (MediaQuery.of(context).size.width - pillWidth) / 2 +
                pillWidth +
                11,
            child: GestureDetector(
              onTap: _onAddPressed,
              child: Container(
                width: buttonSize,
                height: buttonSize,
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
                    key: ValueKey<bool>(_isAdding),
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
