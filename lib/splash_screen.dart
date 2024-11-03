// splash_screen.dart

import 'package:flutter/material.dart';
import 'package:kukuo/navigation_menu.dart';
import 'package:kukuo/loading_screen.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/providers/auth_provider.dart';
import 'package:kukuo/screens/login_screen.dart';

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

    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const LoadingScreen();
        }

        if (auth.isLoggedIn) {
          return const NavigationMenu();
        }

        return const LoginScreen();
      },
    );
  }
}
