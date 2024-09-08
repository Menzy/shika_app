import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/common/section_heading.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/currency_model.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/screens/currency_screen.dart';
import 'package:expressions/expressions.dart' as expressions;
import 'package:kukuo/utils/constants/colors.dart';
import 'package:kukuo/widgets/custom_keyboard.dart';

class AddCoinsScreen extends StatefulWidget {
  const AddCoinsScreen({super.key});

  @override
  State<AddCoinsScreen> createState() => _CurrencyInputScreenState();
}

class _CurrencyInputScreenState extends State<AddCoinsScreen> {
  String _selectedCurrency = 'USD'; // Default currency code
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
      // Fetch the corresponding currency details from localCurrencyList
      final currencyDetails = localCurrencyList.firstWhere(
        (c) => c.code == _selectedCurrency,
        orElse: () =>
            Currency(code: _selectedCurrency, name: 'Unknown', flag: '🏳️'),
      );

      final currency = CurrencyAmount(
        code: currencyDetails.code,
        name: currencyDetails.name, // Assign name
        flag: currencyDetails.flag, // Assign flag
        amount: amount,
      );

      // Add the currency to the provider
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
        body: TTopSectionContainer(
      title: const Text(
        'Add Coins',
        style: TextStyle(
          fontFamily: 'Gazpacho',
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Color(0xFFD8FE00),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Color(0xFf00312F),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const TSectionHeading(
            title: 'Amount to add',
            showActionButton: false,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _amountController,
            readOnly: true, // Prevent default keyboard
            decoration: InputDecoration(
              filled: true,
              fillColor: TColors.primaryBGColor, // Light green background
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10.0),
                child: GestureDetector(
                  onTap: () async {
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
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(
                        right: 10), // Add some space between icon and text
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: const Color(0xFF008F8A),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _selectedCurrency,
                      style: const TextStyle(
                          color: Color(0xFFFAFFB5),
                          fontSize: 30,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              // contentPadding:
              //     const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            style: const TextStyle(
              color: Color(0xFFFAFFB5),
              fontSize: 30,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // Custom keyboard
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: TColors.primaryBGColor,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: CustomKeyboard(
                inputController: _amountController,
                onSubmit: _submitInput, // Callback for submitting input
              ),
            ),
          ),
        ]),
      ),
    ));
  }
}
