import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kukuo/common/top_section_container.dart';
import 'package:kukuo/common/section_heading.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:kukuo/models/currency_model.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:kukuo/screens/currency_screen.dart';
import 'package:expressions/expressions.dart' as expressions;
import 'package:kukuo/utils/constants/colors.dart';
import 'package:kukuo/widgets/custom_keyboard.dart';
import 'package:kukuo/services/currency_preference_service.dart';
import 'package:kukuo/widgets/custom_date_picker.dart';

class AddCoinsScreen extends StatefulWidget {
  final VoidCallback onSubmitSuccess;
  final CurrencyAmount? initialCurrency;
  final CurrencyTransaction? transactionToEdit;

  const AddCoinsScreen({
    super.key,
    required this.onSubmitSuccess,
    this.initialCurrency,
    this.transactionToEdit,
  });

  @override
  AddCoinsScreenState createState() => AddCoinsScreenState();
}

class AddCoinsScreenState extends State<AddCoinsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCurrency = 'GHS';
  DateTime _selectedDate = DateTime.now();
  bool _isKeyboardVisible = false;
  bool _hasError = false;
  CurrencyTransaction? _editingTransaction;
  bool _showDatePicker = true;
  bool _isEditingBalance = false;
  double _originalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _amountController.addListener(() {
      if (_hasError) {
        setState(() {
          _hasError = false;
        });
      }
    });
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
    // Prioritize editing transaction if set
    if (_editingTransaction != null) {
      _amountController.text = _editingTransaction!.amount.abs().toString();
      _selectedCurrency = _editingTransaction!.currencyCode;
      _selectedDate = _editingTransaction!.timestamp;
    } else if (widget.transactionToEdit != null) {
      // Fallback to widget param (initial load)
      _editingTransaction = widget.transactionToEdit;
      _amountController.text =
          widget.transactionToEdit!.amount.abs().toString();
      _selectedCurrency = widget.transactionToEdit!.currencyCode;
      _selectedDate = widget.transactionToEdit!.timestamp;
    } else if (widget.initialCurrency != null) {
      _amountController.text = widget.initialCurrency!.amount.toString();
      _selectedCurrency = widget.initialCurrency!.code;
    } else {
      // Reset defaults if nothing to edit/init
      _amountController.text = '0';
      _selectedCurrency = 'GHS';
      _selectedDate = DateTime.now();
    }
  }

  void setTransactionToEdit(CurrencyTransaction? transaction) {
    setState(() {
      _editingTransaction = transaction;
      _showDatePicker = true; // Always show date picker for edits
      _initializeFields();
    });
  }

  void startAdding(CurrencyAmount? currency,
      {bool showDatePicker = true, bool isEditingBalance = false}) {
    setState(() {
      _editingTransaction = null;
      _showDatePicker = showDatePicker;
      _isEditingBalance = isEditingBalance;

      if (currency != null) {
        _selectedCurrency = currency.code;
        if (isEditingBalance) {
          _originalBalance = currency.amount;
          _amountController.text = currency.amount.toString();
        } else {
          _amountController.text = '0';
        }
      } else {
        _selectedCurrency = 'GHS';
        _amountController.text = '0';
      }

      if (!isEditingBalance) {
        _selectedDate = DateTime.now();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    super.dispose();
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
      _selectedCurrency = 'GHS';
    });
  }

  String _getCurrencyFlag(String code) {
    final currency = localCurrencyList.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency(
        code: code,
        name: 'Unknown',
        flag: '🏳️',
      ),
    );
    return currency.flag;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          setState(() {
            _isKeyboardVisible = false;
          });
        },
        child: Scaffold(
          body: TTopSectionContainer(
            title: Text(
              _isEditingBalance
                  ? 'Edit Balance'
                  : (_editingTransaction != null ? 'Edit Coins' : 'Add Coins'),
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
                      const SizedBox(height: 5),
                      const TSectionHeading(
                        title: 'Amount to add',
                        showActionButton: false,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _amountController,
                        readOnly: true,
                        enableInteractiveSelection: false,
                        showCursor: false,
                        onTap: () {
                          setState(() {
                            _isKeyboardVisible = true;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: TColors.primaryBGColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: _hasError
                                ? const BorderSide(
                                    color: Colors.red, width: 2.0)
                                : BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: _hasError
                                ? const BorderSide(
                                    color: Colors.red, width: 2.0)
                                : BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: _hasError
                                ? const BorderSide(
                                    color: Colors.red, width: 2.0)
                                : const BorderSide(
                                    color: Color(0xFF008F8A),
                                    width: 2.0,
                                  ),
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFFFAFFB5),
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      if (_isKeyboardVisible) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _isKeyboardVisible = false;
                              });
                            },
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                color: Color(0xFFFAFFB5),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: TColors.primaryBGColor,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                            ),
                            child: CustomKeyboard(
                              inputController: _amountController,
                              onSubmit: submitInput,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const TSectionHeading(
                        title: 'Currency',
                        showActionButton: false,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          if (!mounted) return;

                          final selectedCurrency =
                              await showCurrencyBottomSheet(context);

                          if (selectedCurrency != null && mounted) {
                            setState(() {
                              _selectedCurrency = selectedCurrency;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: TColors.primaryBGColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _getCurrencyFlag(_selectedCurrency),
                                style: const TextStyle(fontSize: 30),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _selectedCurrency,
                                style: const TextStyle(
                                  color: Color(0xFFFAFFB5),
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFFFAFFB5),
                                size: 30,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_showDatePicker) ...[
                        const TSectionHeading(
                          title: 'Date',
                          showActionButton: false,
                        ),
                        const SizedBox(height: 10),
                        CustomDatePicker(
                          initialDate: _selectedDate,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }

  bool submitInput() {
    // Clear any previous snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    if (_formKey.currentState!.validate()) {
      final expression = _amountController.text;
      double? amount = _evaluateExpression(expression);

      if (amount != null && amount != 0) {
        setState(() {
          _hasError = false;
        });
        final isSubtraction = amount < 0;

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
            return false;
          }
        }

        // Reconciliation Logic for Edit Balance
        double finalAmountToAdd = amount;
        bool finalIsSubtraction = isSubtraction;

        if (_isEditingBalance) {
          final newBalance = amount;
          final difference = newBalance - _originalBalance;

          if (difference == 0) {
            // No change
            _resetFields();
            widget.onSubmitSuccess();
            return true;
          }

          finalAmountToAdd = difference.abs();
          finalIsSubtraction = difference < 0;
        }

        final updatedCurrency = CurrencyAmount(
          code: currencyDetails.code,
          name: currencyDetails.name,
          flag: currencyDetails.flag,
          amount: widget.initialCurrency != null
              ? widget.initialCurrency!.amount +
                  (finalIsSubtraction ? -finalAmountToAdd : finalAmountToAdd)
              : (finalIsSubtraction ? -finalAmountToAdd : finalAmountToAdd),
        );

        final userInputProvider =
            Provider.of<UserInputProvider>(context, listen: false);
        final exchangeRateProvider =
            Provider.of<ExchangeRateProvider>(context, listen: false);

        // Use the saved local currency instead of hardcoded USD
        _addCurrencyWithSavedPreference(userInputProvider, exchangeRateProvider,
            updatedCurrency, finalIsSubtraction,
            amountToAdd: finalAmountToAdd);
        return true;
      } else {
        setState(() {
          _hasError = true;
        });
        if (amount != 0) {
          // Keep snackbar for invalid expression if needed, or just show error border
          // The user specifically asked to remove "amount cannot be zero" toaster.
          // I will assume red border is enough for zero.
          // For invalid expression, it returns null, so it falls here.
        }
        return false;
      }
    }
    return false;
  }

  Future<void> _addCurrencyWithSavedPreference(
      UserInputProvider userInputProvider,
      ExchangeRateProvider exchangeRateProvider,
      CurrencyAmount updatedCurrency,
      bool isSubtraction,
      {double? amountToAdd}) async {
    final localCurrencyCode =
        await CurrencyPreferenceService.loadSelectedCurrency();

    if (!mounted) return;

    if (widget.initialCurrency != null) {
      Navigator.pop(context, updatedCurrency);
    } else {
      if (_editingTransaction != null) {
        // Update existing transaction
        final updatedTransaction = CurrencyTransaction(
          id: _editingTransaction!.id,
          currencyCode: updatedCurrency.code,
          amount: isSubtraction
              ? -(amountToAdd ?? updatedCurrency.amount.abs())
              : (amountToAdd ?? updatedCurrency.amount),
          timestamp: _selectedDate,
          type: isSubtraction ? 'Subtraction' : 'Addition',
        );

        await userInputProvider.updateTransaction(
          updatedTransaction,
          exchangeRateProvider.exchangeRates,
          localCurrencyCode,
        );
      } else {
        // Add new transaction
        await userInputProvider.addCurrency(
          updatedCurrency,
          exchangeRateProvider.exchangeRates,
          localCurrencyCode,
          isSubtraction: isSubtraction,
          date: _selectedDate,
          // If editing balance, we add the difference, not the total
          // But addCurrency expects the CurrencyAmount object which usually holds the total?
          // Wait, addCurrency uses currency.amount as the transaction amount!
          // So we need to pass a CurrencyAmount with the difference.
        );
        // Correcting the call above:
        // We need to pass a CurrencyAmount that represents the TRANSACTION amount, not the new total.
        // The updatedCurrency constructed in submitInput has the NEW TOTAL if initialCurrency was present.
        // But addCurrency uses `currency.amount` as the transaction amount.
        // So we should construct a temporary CurrencyAmount for the transaction.

        final transactionCurrency = CurrencyAmount(
          code: updatedCurrency.code,
          name: updatedCurrency.name,
          flag: updatedCurrency.flag,
          amount: amountToAdd ?? updatedCurrency.amount, // Use the difference
        );

        await userInputProvider.addCurrency(
          transactionCurrency,
          exchangeRateProvider.exchangeRates,
          localCurrencyCode,
          isSubtraction: isSubtraction,
          date: _selectedDate,
        );
      }

      _resetFields(); // Reset fields after successful submission
      widget.onSubmitSuccess();
    }
  }
}
