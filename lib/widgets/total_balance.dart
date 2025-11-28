import 'package:flutter/material.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/widgets/currency_formatter.dart'; // Import the formatter

class TotalBalance extends StatelessWidget {
  final String selectedLocalCurrency;
  final UserInputProvider userInputProvider;
  final ExchangeRateProvider exchangeRateProvider;
  final VoidCallback? onTap;

  const TotalBalance({
    super.key,
    required this.selectedLocalCurrency,
    required this.userInputProvider,
    required this.exchangeRateProvider,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = userInputProvider.calculateTotalInLocalCurrency(
      selectedLocalCurrency,
      exchangeRateProvider.exchangeRates,
    );

    if (onTap == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$selectedLocalCurrency ${totalAmount.toStringAsCurrency()}',
            style: const TextStyle(
              fontFamily: 'Gazpacho',
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD8FE00),
            ),
          ),
          const Text(
            'Total Balance:',
            style: TextStyle(color: Color(0xFFF8FF99), fontSize: 12),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$selectedLocalCurrency ${totalAmount.toStringAsCurrency()}',
            style: const TextStyle(
              fontFamily: 'Gazpacho',
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD8FE00),
            ),
          ),
          const Text(
            'Total Balance:',
            style: TextStyle(color: Color(0xFFF8FF99), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
