import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:kukuo/providers/auth_provider.dart';
import 'package:kukuo/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/exchange_rate_provider.dart';
import 'providers/user_input_provider.dart';

import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        ChangeNotifierProvider(create: (_) => UserInputProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
