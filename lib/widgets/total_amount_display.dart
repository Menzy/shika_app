import 'package:flutter/material.dart';
import 'package:shika_app/providers/user_input_provider.dart';
import 'package:shika_app/providers/exchange_rate_provider.dart';
import 'package:shika_app/widgets/currency_formatter.dart'; // Import the formatter

class TotalAmountDisplay extends StatelessWidget {
  final String selectedLocalCurrency;
  final UserInputProvider userInputProvider;
  final ExchangeRateProvider exchangeRateProvider;
  final VoidCallback onTap;

  const TotalAmountDisplay({
    super.key,
    required this.selectedLocalCurrency,
    required this.userInputProvider,
    required this.exchangeRateProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalAmount = userInputProvider.calculateTotalInLocalCurrency(
      selectedLocalCurrency,
      exchangeRateProvider.exchangeRates,
    );

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${selectedLocalCurrency} ${totalAmount.toStringAsCurrency()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Text('Total Balance'),
        ],
      ),
    );
  }
}