import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/screens/edit_balance_screen.dart';
import 'package:kukuo/widgets/currency_formatter.dart';

class AddedList extends StatefulWidget {
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
  State<AddedList> createState() => _AddedListState();
}

class _AddedListState extends State<AddedList> {
  // Keep track of the expanded index
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

        bool isExpanded =
            _expandedIndex == index; // Check if the current tile is expanded

        return GestureDetector(
          onTap: () {
            setState(() {
              // Toggle expanded state
              _expandedIndex = isExpanded ? null : index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
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
                // Expanded content
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Here are the details for ${currency.code}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditBalanceScreen(
                                    index: index,
                                    currency: currency,
                                  ),
                                ),
                              );
                            },
                            child: const Text('View Details',
                                style: TextStyle(
                                  color: Colors.red,
                                ))),
                      ],
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
