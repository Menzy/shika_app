import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/providers/user_input_provider.dart';

import 'package:kukuo/widgets/currency_formatter.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/widgets/balance_chart.dart';
import 'package:kukuo/navigation_menu.dart';

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
            setState(() {
              _expandedIndex = isExpanded ? null : index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF001817),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 0,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -4),
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
                  trailing: isExpanded
                      ? GestureDetector(
                          onTap: () {
                            context
                                .findAncestorStateOfType<NavigationMenuState>()
                                ?.startAdding(currency,
                                    showDatePicker: false,
                                    isEditingBalance: true);
                          },
                          child: const Text(
                            'Edit Balance',
                            style: TextStyle(
                              color: Color(0xFFD8FE00),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                // Expanded content

                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: isExpanded
                      ? Column(
                          children: [
                            const SizedBox(height: 24),
                            Consumer<UserInputProvider>(
                              builder: (context, userInputProvider, _) {
                                final history =
                                    userInputProvider.getCurrencyHistory(
                                        currency.code,
                                        widget.selectedLocalCurrency);

                                // Scale balances by current rate to show value history
                                final scaledBalances =
                                    history.balances.map((amount) {
                                  return amount /
                                      rateForCurrency *
                                      rateForLocalCurrency;
                                }).toList();

                                // Scale invested by current rate
                                final scaledInvested =
                                    history.invested.map((amount) {
                                  return amount /
                                      rateForCurrency *
                                      rateForLocalCurrency;
                                }).toList();

                                return BalanceChart(
                                  balanceHistory: scaledBalances,
                                  investedHistory: scaledInvested,
                                  timeHistory: history.times,
                                  currencySymbol: widget.selectedLocalCurrency,
                                  showBackground: false,
                                  showTitle: false,
                                  padding: EdgeInsets.zero,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
