import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:kukuo/providers/auth_provider.dart';
import 'package:kukuo/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/exchange_rate_provider.dart';
import 'providers/user_input_provider.dart';

import 'package:flutter/services.dart';

import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw 'Firebase initialization timed out';
      },
    );
  } catch (e) {
    // Ignore error and let the app run, AuthProvider will handle missing auth
    debugPrint('Firebase initialization failed: $e');
  }
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExchangeRateProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserInputProvider>(
          create: (_) => UserInputProvider(),
          update: (_, auth, userInput) {
            if (userInput != null) {
              userInput.setDatabaseService(auth.databaseService);
            }
            return userInput!;
          },
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Euclid'),
        title: 'Pot of Gold',
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: child!,
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
