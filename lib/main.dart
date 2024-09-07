import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shika_app/screens/home_screen.dart';
import 'providers/exchange_rate_provider.dart';
import 'providers/user_input_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env"); // Load environment variables
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
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Currency Converter',
        home: HomeScreen(),
      ),
    );
  }
}
