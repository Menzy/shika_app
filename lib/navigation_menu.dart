import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kukuo/screens/add_coins_screen.dart.dart';
import 'package:kukuo/screens/all_assets_screen.dart';
import 'package:kukuo/screens/home_screen.dart';
import 'package:kukuo/screens/papertrail_screen.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AllAssetsScreen(),
    const PaperTrailScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double pillWidth = MediaQuery.of(context).size.width *
        0.43; // Set pill width as 43% of screen width

    return Scaffold(
      body: Stack(
        children: [
          _screens[_selectedIndex], // Show the current screen based on index

          // Pill-shaped bottom navbar
          Positioned(
            bottom:
                30, // Position the navbar 30px above the bottom of the screen
            left: (MediaQuery.of(context).size.width - pillWidth) /
                2, // Center the pill dynamically
            child: Container(
              width: pillWidth,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF000D0C),
                borderRadius: BorderRadius.circular(35), // Pill shape
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceEvenly, // Evenly space icons
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

          // Floating Action Button positioned to the right of the pill navbar
          Positioned(
            bottom:
                45, // Align vertically with the bottom navbar (adjust as needed)
            right: (MediaQuery.of(context).size.width - pillWidth) / 2 -
                55, // Align 10px to the right of the pill
            child: SizedBox(
              width: 45, // Set FAB size to 45px
              height: 45,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddCoinsScreen(),
                    ),
                  );
                },
                backgroundColor: const Color(0xFFD8FE00),
                shape: const CircleBorder(),
                child: const Icon(
                  Icons.add,
                  size: 20, // Set icon size to 20px
                  color: Color(0xFF00312F),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
