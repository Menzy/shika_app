import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/widgets/currency_formatter.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/widgets/balance_chart.dart';
import 'package:kukuo/navigation_menu.dart';

class AddedListItem extends StatefulWidget {
  final CurrencyAmount currency;
  final String selectedLocalCurrency;
  final ExchangeRateProvider exchangeRateProvider;
  final bool isExpanded;
  final VoidCallback onTap;

  const AddedListItem({
    super.key,
    required this.currency,
    required this.selectedLocalCurrency,
    required this.exchangeRateProvider,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<AddedListItem> createState() => _AddedListItemState();
}

class _AddedListItemState extends State<AddedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AddedListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rateForCurrency =
        widget.exchangeRateProvider.exchangeRates[widget.currency.code] ?? 1.0;
    final rateForLocalCurrency = widget
            .exchangeRateProvider.exchangeRates[widget.selectedLocalCurrency] ??
        1.0;
    final convertedAmount =
        widget.currency.amount / rateForCurrency * rateForLocalCurrency;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
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
              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
              leading: Text(
                widget.currency.flag,
                style: const TextStyle(fontSize: 29),
              ),
              title: Text(
                '${widget.currency.code} ${widget.currency.amount.toStringAsCurrency()}',
                style: const TextStyle(color: Color(0xFFFAFFB5), fontSize: 20),
              ),
              subtitle: Text(
                '${widget.selectedLocalCurrency} ${convertedAmount.toStringAsCurrency()}',
                style: const TextStyle(color: Color(0xFF00514F), fontSize: 10),
              ),
              trailing: widget.isExpanded
                  ? GestureDetector(
                      onTap: () {
                        context
                            .findAncestorStateOfType<NavigationMenuState>()
                            ?.startAdding(widget.currency,
                                showDatePicker: false, isEditingBalance: true);
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
            // Expanded content with SizeTransition and FadeTransition
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Consumer<UserInputProvider>(
                      builder: (context, userInputProvider, _) {
                        final history = userInputProvider.getCurrencyHistory(
                            widget.currency.code, widget.selectedLocalCurrency);

                        // Scale balances by current rate to show value history
                        final scaledBalances = history.balances.map((amount) {
                          return amount /
                              rateForCurrency *
                              rateForLocalCurrency;
                        }).toList();

                        // Scale invested by current rate
                        final scaledInvested = history.invested.map((amount) {
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
