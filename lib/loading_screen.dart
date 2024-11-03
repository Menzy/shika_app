import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF000D0C),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD8FE00),
        ),
      ),
    );
  }
}
