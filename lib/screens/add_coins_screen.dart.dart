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
  final VoidCallback onSubmitSuccess;

  const AddCoinsScreen({super.key, required this.onSubmitSuccess});

  @override
  AddCoinsScreenState createState() => AddCoinsScreenState();
}

class AddCoinsScreenState extends State<AddCoinsScreen> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCurrency = 'GHS';

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void submitInput() {
    if (_formKey.currentState!.validate()) {
      final expression = _amountController.text;
      final double? amount = _evaluateExpression(expression);

      if (amount != null && amount > 0) {
        final currencyDetails = localCurrencyList.firstWhere(
          (c) => c.code == _selectedCurrency,
          orElse: () =>
              Currency(code: _selectedCurrency, name: 'Unknown', flag: '🏳️'),
        );

        final currency = CurrencyAmount(
          code: currencyDetails.code,
          name: currencyDetails.name,
          flag: currencyDetails.flag,
          amount: amount,
        );

        Provider.of<UserInputProvider>(context, listen: false)
            .addCurrency(currency);
        widget.onSubmitSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid input!'),
          ),
        );
        _amountController.clear();
        _amountController.text = '';
      }
    }
    _amountController.clear();
  }

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
            color: Color(0xFF00312F),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TSectionHeading(
                  title: 'Amount to add',
                  showActionButton: false,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  readOnly: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: TColors.primaryBGColor,
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
                          margin: const EdgeInsets.only(right: 10),
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
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFFFAFFB5),
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty || value == '0') {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: TColors.primaryBGColor,
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: CustomKeyboard(
                      inputController: _amountController,
                      onSubmit: submitInput, // Use the submit function
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
