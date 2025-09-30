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
        // Check auth and auto-login if needed
        _initializeAuth();
      }
    });
  }

  Future<void> _initializeAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.checkAuthState();

    // Auto-login with default user if not already logged in
    if (mounted && !authProvider.isLoggedIn) {
      await authProvider.autoLogin();
    }
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

    // Always return the NavigationMenu
    return const NavigationMenu();
  }
}
