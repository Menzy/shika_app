import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/currency_input_formatter.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/currency_model.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/screens/currency_screen.dart';
import 'package:kukuo/widgets/currency_formatter.dart';

class EditCurrencyScreen extends StatefulWidget {
  final CurrencyAmount currency; // Ensure currency includes name and flag
  final int index;

  const EditCurrencyScreen({
    required this.currency,
    required this.index,
    super.key,
  });

  @override
  State<EditCurrencyScreen> createState() => _EditCurrencyScreenState();
}

class _EditCurrencyScreenState extends State<EditCurrencyScreen> {
  late TextEditingController _amountController;
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.currency.amount.toStringAsCurrency(),
    );
    _selectedCurrency = widget.currency.code;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectCurrency() async {
    final selectedCurrency = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CurrencyScreen(),
      ),
    );

    if (selectedCurrency != null) {
      setState(() {
        _selectedCurrency = selectedCurrency;
      });
    }
  }

  void _updateCurrency() {
    final numericString =
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final double? amount = double.tryParse(numericString);

    if (amount != null && amount > 0) {
      // Fetch corresponding Currency (with flag and name) for selected currency code
      final currency = localCurrencyList.firstWhere(
        (c) => c.code == _selectedCurrency,
        orElse: () =>
            Currency(code: _selectedCurrency, name: 'Unknown', flag: '🏳️'),
      );

      final updatedCurrency = CurrencyAmount(
        code: _selectedCurrency,
        name: currency.name, // Assign correct name
        flag: currency.flag, // Assign correct flag
        amount: amount,
      );

      final userInputProvider =
          Provider.of<UserInputProvider>(context, listen: false);
      final exchangeRateProvider =
          Provider.of<ExchangeRateProvider>(context, listen: false);

      const String localCurrencyCode = 'USD'; // Replace with dynamic value

      // Update the currency with the exchange rates and local currency
      userInputProvider.updateCurrency(
        widget.index,
        updatedCurrency,
        exchangeRateProvider.exchangeRates,
        localCurrencyCode,
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Currency'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _selectCurrency,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _selectedCurrency,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateCurrency,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.amber,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
