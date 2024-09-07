import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shika_app/models/currency_model.dart';
import 'package:shika_app/providers/user_input_provider.dart';
import 'package:shika_app/screens/currency_screen.dart';
import 'package:expressions/expressions.dart' as expressions;
import 'package:shika_app/widgets/custom_keyboard.dart';

class CurrencyInputScreen extends StatefulWidget {
  const CurrencyInputScreen({super.key});

  @override
  State<CurrencyInputScreen> createState() => _CurrencyInputScreenState();
}

class _CurrencyInputScreenState extends State<CurrencyInputScreen> {
  String _selectedCurrency = 'USD'; // Default currency
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = '0'; // Initialize with 0
  }

  /// Evaluates the math expression entered by the user
  double? _evaluateExpression(String expression) {
    try {
      final parsedExpression = expressions.Expression.parse(expression);
      const evaluator = expressions.ExpressionEvaluator();
      final result = evaluator.eval(parsedExpression, {});

      if (result is num) {
        return result.toDouble();
      } else {
        throw Exception('Invalid result type');
      }
    } catch (e) {
      print('Error in expression parsing or evaluation: $e');
      return null;
    }
  }

  /// Submit the final input value
  void _submitInput() {
    final expression = _amountController.text;

    // Evaluate the expression
    final double? amount = _evaluateExpression(expression);

    if (amount != null && amount > 0) {
      final currency = Currency(code: _selectedCurrency, amount: amount);
      Provider.of<UserInputProvider>(context, listen: false)
          .addCurrency(currency);
      Navigator.pop(context); // Close the screen after saving
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid input!'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Currency'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
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
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_selectedCurrency),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: TextField(
                    controller: _amountController,
                    readOnly: true, // Prevent default keyboard
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Custom keyboard
            Expanded(
              child: CustomKeyboard(
                inputController: _amountController,
                onSubmit: _submitInput, // Callback for submitting input
              ),
            ),
          ],
        ),
      ),
    );
  }
}
