import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/screens/currency_details_screen.dart';
import 'package:kukuo/widgets/currency_formatter.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/widgets/asset_growth_chart.dart';

class AddedList extends StatefulWidget {
  final List<CurrencyAmount> currencies;
  final String selectedLocalCurrency;
  final ExchangeRateProvider exchangeRateProvider;
  final bool isAllAssetsScreen; // Add this parameter

  const AddedList({
    super.key,
    required this.currencies,
    required this.selectedLocalCurrency,
    required this.exchangeRateProvider,
    this.isAllAssetsScreen = false, // Default to false for home screen
  });

  @override
  State<AddedList> createState() => _AddedListState();
}

class _AddedListState extends State<AddedList> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.currencies.length, (index) {
        final currency = widget.currencies[index];
        final rateForCurrency =
            widget.exchangeRateProvider.exchangeRates[currency.code] ?? 1.0;
        final rateForLocalCurrency = widget.exchangeRateProvider
                .exchangeRates[widget.selectedLocalCurrency] ??
            1.0;
        final convertedAmount =
            currency.amount / rateForCurrency * rateForLocalCurrency;

        bool isExpanded = _expandedIndex == index;

        return GestureDetector(
          onTap: () {
            if (widget.isAllAssetsScreen) {
              // For All Assets Screen - expand/collapse with chart
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            } else {
              // For Home Screen - navigate to details
              final transactions =
                  Provider.of<UserInputProvider>(context, listen: false)
                      .getTransactionsByCurrency(currency.code);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CurrencyDetailScreen(
                    currencyCode: currency.code,
                    transactions: transactions,
                  ),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            margin: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF001817),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  leading: Text(
                    currency.flag,
                    style: const TextStyle(fontSize: 29),
                  ),
                  title: Text(
                    '${currency.code} ${currency.amount.toStringAsCurrency()}',
                    style:
                        const TextStyle(color: Color(0xFFFAFFB5), fontSize: 20),
                  ),
                  subtitle: Text(
                    '${widget.selectedLocalCurrency} ${convertedAmount.toStringAsCurrency()}',
                    style:
                        const TextStyle(color: Color(0xFF00514F), fontSize: 10),
                  ),
                ),
                // Only show expanded content in All Assets Screen
                if (widget.isAllAssetsScreen && isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Consumer<UserInputProvider>(
                      builder: (context, provider, _) {
                        final transactions =
                            provider.getTransactionsByCurrency(currency.code);
                        final amounts =
                            transactions.map((t) => t.amount).toList();
                        final timestamps =
                            transactions.map((t) => t.timestamp).toList();

                        return AssetGrowthChart(
                          currencyCode: currency.code,
                          amounts: amounts,
                          timestamps: timestamps,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
