// splash_screen.dart

import 'package:flutter/material.dart';
import 'package:kukuo/navigation_menu.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for 2 seconds then check auth
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSplash = false);
        context.read<AuthProvider>().checkAuthState();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return Scaffold(
        backgroundColor: const Color(0xFF000D0C),
        body: Image.asset(
          'assets/splash/splash_screen.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    // Skip authentication and go directly to the main app
    // We'll automatically log in a default user in the background
    Future.microtask(() {
      // Auto-login with default user if not already logged in
      if (!context.read<AuthProvider>().isLoggedIn) {
        context.read<AuthProvider>().autoLogin();
      }
    });
    
    // Always return the NavigationMenu
    return const NavigationMenu();
  }
}
