import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shika_app/currency_input_formatter.dart';
import 'package:shika_app/models/currency_model.dart';
import 'package:shika_app/providers/user_input_provider.dart';
import 'package:shika_app/screens/currency_screen.dart';
import 'package:shika_app/widgets/currency_formatter.dart';

class EditCurrencyScreen extends StatefulWidget {
  final Currency currency;
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
      text: widget.currency.amount
          .toStringAsCurrency(), // Using currency formatter
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
        builder: (context) => CurrencyScreen(),
      ),
    );

    if (selectedCurrency != null) {
      setState(() {
        _selectedCurrency = selectedCurrency;
      });
    }
  }

  void _updateCurrency() {
    // Remove formatting and parse the raw number
    final numericString =
        _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final double? amount = double.tryParse(numericString);

    if (amount != null && amount > 0) {
      final updatedCurrency = Currency(code: _selectedCurrency, amount: amount);
      Provider.of<UserInputProvider>(context, listen: false)
          .updateCurrency(widget.index, updatedCurrency);
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
                FilteringTextInputFormatter.digitsOnly, // Allows only digits
                CurrencyInputFormatter(), // Apply your custom formatter
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
