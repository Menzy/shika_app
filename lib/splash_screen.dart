// splash_screen.dart

import 'package:flutter/material.dart';
import 'package:kukuo/navigation_menu.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/providers/auth_provider.dart';
import 'package:kukuo/screens/login_screen.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/services/database_service.dart';

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
    final userInputProvider = context.read<UserInputProvider>();
    final exchangeRateProvider = context.read<ExchangeRateProvider>();

    // Wait for both the minimum splash duration and the auth check
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      authProvider.checkAuthState(),
    ]);

    if (mounted) {
      if (authProvider.isLoggedIn) {
        // Initialize data if logged in
        if (authProvider.user != null) {
          final databaseService = DatabaseService(uid: authProvider.user!.uid);
          userInputProvider.setDatabaseService(databaseService);
        } else {
          userInputProvider.setDatabaseService(null);
        }

        exchangeRateProvider.setUserInputProvider(userInputProvider);
        userInputProvider.setExchangeRateProvider(exchangeRateProvider);

        try {
          // Load transactions first (this also recalculates currencies)
          await userInputProvider.loadTransactions();

          // Load exchange rates
          await exchangeRateProvider.fetchExchangeRates();
          await userInputProvider.loadCurrencies();

          // Recalculate balance history with current exchange rates
          if (exchangeRateProvider.exchangeRates.isNotEmpty) {
            await userInputProvider.recalculateHistory(
                exchangeRateProvider.exchangeRates,
                userInputProvider.selectedCurrency);
          }
        } catch (e) {
          debugPrint('Error initializing data: $e');
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const NavigationMenu()),
          );
        }
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
