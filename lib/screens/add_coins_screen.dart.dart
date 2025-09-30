import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/common/section_heading.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/currency_model.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/screens/currency_screen.dart';
import 'package:expressions/expressions.dart' as expressions;
import 'package:kukuo/utils/constants/colors.dart';
import 'package:kukuo/widgets/custom_keyboard.dart';
import 'package:kukuo/services/currency_preference_service.dart';

class AddCoinsScreen extends StatefulWidget {
  final VoidCallback onSubmitSuccess;
  final CurrencyAmount? initialCurrency;

  const AddCoinsScreen({
    super.key,
    required this.onSubmitSuccess,
    this.initialCurrency,
  });

  @override
  AddCoinsScreenState createState() => AddCoinsScreenState();
}

class AddCoinsScreenState extends State<AddCoinsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCurrency = 'GHS';
  bool isSubtraction = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFields();
  }

  @override
  void didUpdateWidget(covariant AddCoinsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCurrency != oldWidget.initialCurrency) {
      _initializeFields();
    }
  }

  void _initializeFields() {
    if (widget.initialCurrency != null) {
      _amountController.text = widget.initialCurrency!.amount.toString();
      _selectedCurrency = widget.initialCurrency!.code;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    super.dispose();
  }

  void _clearInput() {
    _amountController.clear();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
      debugPrint('Error in expression parsing or evaluation: $e');
      return null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resetFields();
    }
  }

  void _resetFields() {
    setState(() {
      _amountController.text = '0';
      isSubtraction = false;
      _selectedCurrency = 'GHS';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TTopSectionContainer(
        title: Text(
          isSubtraction ? 'Subtract Coins' : 'Add Coins',
          style: const TextStyle(
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
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add operation toggle
                  // Operation Toggle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: TColors.primaryBGColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isSubtraction = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isSubtraction
                                    ? const Color(0xFF008F8A)
                                    : TColors.primaryBGColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Add',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFFAFFB5),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => isSubtraction = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSubtraction
                                    ? const Color(0xFF008F8A)
                                    : TColors.primaryBGColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Subtract',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFFAFFB5),
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  TSectionHeading(
                    title:
                        isSubtraction ? 'Amount to subtract' : 'Amount to add',
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
                            if (!mounted) return;
                            
                            final selectedCurrency = await showCurrencyBottomSheet(context);

                            if (selectedCurrency != null && mounted) {
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
                        onSubmit: submitInput,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void submitInput() {
    if (_formKey.currentState!.validate()) {
      final expression = _amountController.text;
      double? amount = _evaluateExpression(expression);

      if (amount != null && amount > 0) {
        if (isSubtraction) {
          amount = -amount; // Make the amount negative for subtraction
        }

        final currencyDetails = localCurrencyList.firstWhere(
          (c) => c.code == _selectedCurrency,
          orElse: () => Currency(
            code: _selectedCurrency,
            name: 'Unknown',
            flag: '🏳️',
          ),
        );

        // Add validation for subtraction
        if (isSubtraction && widget.initialCurrency != null) {
          if (amount.abs() > widget.initialCurrency!.amount) {
            _showErrorSnackbar(
                'Cannot subtract more than the available balance');
            return;
          }
        }

        final updatedCurrency = CurrencyAmount(
          code: currencyDetails.code,
          name: currencyDetails.name,
          flag: currencyDetails.flag,
          amount: widget.initialCurrency != null
              ? widget.initialCurrency!.amount + amount
              : amount,
        );

        final userInputProvider =
            Provider.of<UserInputProvider>(context, listen: false);
        final exchangeRateProvider =
            Provider.of<ExchangeRateProvider>(context, listen: false);

        // Use the saved local currency instead of hardcoded USD
        _addCurrencyWithSavedPreference(
            userInputProvider, exchangeRateProvider, updatedCurrency);
      } else {
        _showErrorSnackbar('Invalid input!');
        _clearInput();
      }
    }
  }

  Future<void> _addCurrencyWithSavedPreference(
      UserInputProvider userInputProvider,
      ExchangeRateProvider exchangeRateProvider,
      CurrencyAmount updatedCurrency) async {
    final localCurrencyCode =
        await CurrencyPreferenceService.loadSelectedCurrency();

    if (!mounted) return;

    if (widget.initialCurrency != null) {
      Navigator.pop(context, updatedCurrency);
    } else {
      userInputProvider.addCurrency(
        updatedCurrency,
        exchangeRateProvider.exchangeRates,
        localCurrencyCode,
        isSubtraction: isSubtraction,
      );
      _resetFields(); // Reset fields after successful submission
      widget.onSubmitSuccess();
    }
  }
}
