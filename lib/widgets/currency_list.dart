import 'package:flutter/material.dart';
import 'package:shika_app/models/currency_model.dart';
import 'package:shika_app/providers/exchange_rate_provider.dart';
import 'package:shika_app/screens/currency_details_screen.dart';
import 'package:shika_app/widgets/currency_formatter.dart';

class CurrencyList extends StatelessWidget {
  final List<Currency> currencies;
  final String selectedLocalCurrency;
  final ExchangeRateProvider exchangeRateProvider;

  const CurrencyList({
    super.key,
    required this.currencies,
    required this.selectedLocalCurrency,
    required this.exchangeRateProvider,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: currencies.length,
      itemBuilder: (context, index) {
        final currency = currencies[index];
        final rateForCurrency =
            exchangeRateProvider.exchangeRates[currency.code] ?? 1.0;
        final rateForLocalCurrency =
            exchangeRateProvider.exchangeRates[selectedLocalCurrency] ?? 1.0;
        final convertedAmount =
            currency.amount / rateForCurrency * rateForLocalCurrency;

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(8.0),
            title: Text(
                '${currency.code}: ${currency.amount.toStringAsCurrency()}'),
            subtitle: Text(
                '$selectedLocalCurrency ${convertedAmount.toStringAsCurrency()}'),
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
      },
    );
  }
}
