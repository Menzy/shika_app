import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/widgets/added_list_item.dart';

class AddedList extends StatefulWidget {
  final List<CurrencyAmount> currencies;
  final String selectedLocalCurrency;
  final ExchangeRateProvider exchangeRateProvider;
  final bool isAllAssetsScreen;

  const AddedList({
    super.key,
    required this.currencies,
    required this.selectedLocalCurrency,
    required this.exchangeRateProvider,
    this.isAllAssetsScreen = false,
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
        bool isExpanded = _expandedIndex == index;

        return AddedListItem(
          currency: currency,
          selectedLocalCurrency: widget.selectedLocalCurrency,
          exchangeRateProvider: widget.exchangeRateProvider,
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              _expandedIndex = isExpanded ? null : index;
            });
          },
        );
      }),
    );
  }
}
