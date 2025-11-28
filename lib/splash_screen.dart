// splash_screen.dart

import 'package:flutter/material.dart';
import 'package:kukuo/navigation_menu.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/providers/auth_provider.dart';
import 'package:kukuo/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = context.read<AuthProvider>();

    // Wait for both the minimum splash duration and the auth check
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      authProvider.checkAuthState(),
    ]);

    if (mounted) {
      if (authProvider.isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const NavigationMenu()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
}
