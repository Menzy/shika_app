import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/screens/currency_details_screen.dart';
import 'package:kukuo/widgets/currency_formatter.dart';

class AddedList extends StatelessWidget {
  final List<CurrencyAmount> currencies;
  final String selectedLocalCurrency;
  final ExchangeRateProvider exchangeRateProvider;

  const AddedList({
    super.key,
    required this.currencies,
    required this.selectedLocalCurrency,
    required this.exchangeRateProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(currencies.length, (index) {
        final currency = currencies[index];
        final rateForCurrency =
            exchangeRateProvider.exchangeRates[currency.code] ?? 1.0;
        final rateForLocalCurrency =
            exchangeRateProvider.exchangeRates[selectedLocalCurrency] ?? 1.0;
        final convertedAmount =
            currency.amount / rateForCurrency * rateForLocalCurrency;

        return Card(
          color: const Color(0xFF001817),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 21),
            leading: Text(
              currency.flag,
              style: const TextStyle(fontSize: 29),
            ),
            title: Text(
              '${currency.code} ${currency.amount.toStringAsCurrency()}',
              style: const TextStyle(color: Color(0xFFFAFFB5), fontSize: 20),
            ),
            subtitle: Text(
              '$selectedLocalCurrency ${convertedAmount.toStringAsCurrency()}',
              style: const TextStyle(color: Color(0xFF00514F), fontSize: 10),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CurrencyDetailsScreen(
                    index: index,
                    currency: currency,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
