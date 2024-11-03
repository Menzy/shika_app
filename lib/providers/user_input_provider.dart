import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_model.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/transaction_model.dart';

class UserInputProvider with ChangeNotifier {
  List<CurrencyAmount> _currencies = [];
  List<double> _balanceHistory = [];
  List<DateTime> _timeHistory = [];
  ExchangeRateProvider? _exchangeRateProvider; // Add this
  List<CurrencyTransaction> transactions = [];
  List<Transaction> _transactions = [];

  List<CurrencyAmount> get currencies => _currencies;
  List<double> get balanceHistory => _balanceHistory;
  List<DateTime> get timeHistory => _timeHistory;

  // Add this setter
  void setExchangeRateProvider(ExchangeRateProvider provider) {
    _exchangeRateProvider = provider;
  }

  void addTransaction(CurrencyTransaction transaction) {
    transactions.add(transaction);
    notifyListeners();
  }

  List<CurrencyTransaction> getTransactionsByCurrency(String currencyCode) {
    return transactions.where((t) => t.currencyCode == currencyCode).toList();
  }

UserInputProvider() {
    loadCurrencies(); // Ensure currencies are loaded on initialization
    _loadTransactions();
  }

  Future<void> loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCurrencies = prefs.getString('currencies');
    final storedBalanceHistory = prefs.getString('balance_history');
    final storedTimeHistory = prefs.getString('time_history');

    if (storedCurrencies != null) {
      final List<dynamic> jsonList = jsonDecode(storedCurrencies);
      _currencies = jsonList.map((json) => CurrencyAmount.fromJson(json)).toList();
    }

    // Initialize empty lists if no stored data
    _balanceHistory = [];
    _timeHistory = [];

    // Load balance history
    if (storedBalanceHistory != null && storedTimeHistory != null) {
      _balanceHistory = List<double>.from(jsonDecode(storedBalanceHistory));
      _timeHistory = (jsonDecode(storedTimeHistory) as List)
          .map((e) => DateTime.parse(e))
          .toList();
      
      // Sync with exchange rate provider if available
      if (_exchangeRateProvider != null) {
        _exchangeRateProvider!.syncBalanceHistory(_balanceHistory, _timeHistory);
      }
    } else if (_currencies.isNotEmpty) {
      // If we have currencies but no history, initialize with current balance
      final currentBalance = calculateTotalInLocalCurrency(
          'USD', _exchangeRateProvider?.exchangeRates ?? {'USD': 1.0});
      _balanceHistory = [currentBalance];
      _timeHistory = [DateTime.now()];
      
      // Save the initial history
      await prefs.setString('balance_history', jsonEncode(_balanceHistory));
      await prefs.setString('time_history',
          jsonEncode(_timeHistory.map((e) => e.toIso8601String()).toList()));
      
      // Sync with exchange rate provider
      if (_exchangeRateProvider != null) {
        _exchangeRateProvider!.syncBalanceHistory(_balanceHistory, _timeHistory);
      }
    }

    notifyListeners();
  }

  // Add input validation
  bool isValidCurrencyAmount(double amount) {
    return amount > 0 && amount < double.infinity;
  }

  // Improve error handling for currency operations
  Future<bool> addCurrency(
    CurrencyAmount currency,
    Map<String, double> exchangeRates,
    String localCurrencyCode, {
    bool isSubtraction = false,
  }) async {
    try {
      if (!isValidCurrencyAmount(currency.amount.abs())) {
        return false;
      }

      // Find existing currency with the same code
      final existingIndex =
          _currencies.indexWhere((c) => c.code == currency.code);

      if (existingIndex != -1) {
        // Update existing currency amount
        final existingAmount = _currencies[existingIndex].amount;
        final newAmount = isSubtraction
            ? existingAmount - currency.amount.abs()
            : existingAmount + currency.amount;

        if (newAmount < 0) {
          throw Exception('Insufficient balance');
        }

        _currencies[existingIndex] = CurrencyAmount(
          code: currency.code,
          name: currency.name,
          flag: currency.flag,
          amount: newAmount,
        );
      } else {
        // Add new currency
        if (isSubtraction) {
          throw Exception('Cannot subtract from non-existent currency');
        }
        _currencies.insert(0, currency);
      }

      final transaction = CurrencyTransaction(
        currencyCode: currency.code,
        amount: isSubtraction ? -currency.amount.abs() : currency.amount,
        timestamp: DateTime.now(),
        type: isSubtraction ? 'Subtraction' : 'Addition',
      );
      transactions.add(transaction);

      // Create and add transaction
      final newTransaction = Transaction(
        currencyCode: currency.code,
        amount: isSubtraction ? -currency.amount : currency.amount,
        timestamp: DateTime.now(),
        type: isSubtraction ? 'Subtraction' : 'Addition',
      );
      _transactions.add(newTransaction);

      await Future.wait([
        _saveCurrencies(),
        _saveTransactions(),
      ]);

      updateTotalBalance(exchangeRates, localCurrencyCode);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error adding/subtracting currency: $e');
      return false;
    }
  }

  // Add method to save transactions
  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString('transactions', jsonEncode(jsonList));
    final newJsonList = _transactions.map((t) => t.toJson()).toList();
    await prefs.setString('transactions', jsonEncode(newJsonList));
  }

  // Add method to load transactions
  Future<void> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTransactions = prefs.getString('transactions');

    if (storedTransactions != null) {
      final List<dynamic> jsonList = jsonDecode(storedTransactions);
      transactions =
          jsonList.map((json) => CurrencyTransaction.fromJson(json)).toList();
    }
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTransactions = prefs.getString('transactions');
    
    if (storedTransactions != null) {
      final List<dynamic> jsonList = jsonDecode(storedTransactions);
      _transactions = jsonList.map((json) => Transaction.fromJson(json)).toList();
    }
  }

  Future<void> updateCurrency(int index, CurrencyAmount currency,
      Map<String, double> exchangeRates, String localCurrencyCode) async {
    _currencies[index] = currency;
    await _saveCurrencies();
    updateTotalBalance(
        exchangeRates, localCurrencyCode); // Update balance and history
  }

  Future<void> removeCurrency(int index, Map<String, double> exchangeRates,
      String localCurrencyCode) async {
    _currencies.removeAt(index);
    await _saveCurrencies();
    updateTotalBalance(
        exchangeRates, localCurrencyCode); // Update balance and history
  }

  Future<void> _saveCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _currencies
        .map((c) => {
              'code': c.code,
              'amount': c.amount,
            })
        .toList();
    await prefs.setString('currencies', jsonEncode(jsonList));
    notifyListeners();
  }

  // Modify updateTotalBalance to use the provider reference
  void updateTotalBalance(
      Map<String, double> exchangeRates, String localCurrencyCode) {
    double totalBalance =
        calculateTotalInLocalCurrency(localCurrencyCode, exchangeRates);

    _balanceHistory.add(totalBalance);
    _timeHistory.add(DateTime.now());

    // Notify listeners immediately to update the UI
    notifyListeners();

    // Save the balance history to SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('balance_history', jsonEncode(_balanceHistory));
      prefs.setString('time_history',
          jsonEncode(_timeHistory.map((e) => e.toIso8601String()).toList()));

      // Sync with ExchangeRateProvider if available
      if (_exchangeRateProvider != null) {
        _exchangeRateProvider!
            .syncBalanceHistory(_balanceHistory, _timeHistory);
      }
    });
  }

  double calculateTotalInLocalCurrency(
      String localCurrencyCode, Map<String, double> exchangeRates) {
    double total = 0.0;

    for (CurrencyAmount currency in _currencies) {
      final rate = exchangeRates[currency.code];
      if (rate != null) {
        total += currency.amount / rate * exchangeRates[localCurrencyCode]!;
      }
    }

    return total;
  }

  List<CurrencyAmount> getConsolidatedCurrencies() {
    final Map<String, double> consolidated = {};

    for (var currency in _currencies) {
      if (consolidated.containsKey(currency.code)) {
        consolidated[currency.code] =
            consolidated[currency.code]! + currency.amount;
      } else {
        consolidated[currency.code] = currency.amount;
      }
    }

    return consolidated.entries.map((entry) {
      final code = entry.key;
      final amount = entry.value;

      // Find name and flag from localCurrencyList
      final currencyDetails = localCurrencyList.firstWhere(
        (c) => c.code == code,
        orElse: () => Currency(code: code, name: 'Unknown', flag: '🏳️'),
      );

      return CurrencyAmount(
        code: code,
        amount: amount,
        name: currencyDetails.name,
        flag: currencyDetails.flag,
      );
    }).toList();
  }

  List<Transaction> getTransactions() {
    return List.from(_transactions.reversed); // Return newest first
  }

  // Add this new method to recalculate history with new rates
  Future<void> recalculateHistory(Map<String, double> newRates) async {
    if (_currencies.isEmpty) return;

    // Clear existing history
    _balanceHistory = [];
    _timeHistory = [];

    // Get all unique timestamps from transactions
    final Set<DateTime> uniqueTimestamps = transactions
        .map((t) => DateTime(
              t.timestamp.year,
              t.timestamp.month,
              t.timestamp.day,
              t.timestamp.hour,
              t.timestamp.minute,
            ))
        .toSet()
      ..add(DateTime.now()); // Add current time

    // Sort timestamps
    final sortedTimestamps = uniqueTimestamps.toList()..sort();

    // Calculate balance at each timestamp
    for (final timestamp in sortedTimestamps) {
      // Get all transactions up to this timestamp
      final relevantTransactions = transactions
          .where((t) => t.timestamp.isBefore(timestamp) || t.timestamp == timestamp)
          .toList();

      // Calculate total balance at this timestamp
      double totalBalance = 0;
      final Map<String, double> currencyTotals = {};

      for (final transaction in relevantTransactions) {
        currencyTotals[transaction.currencyCode] =
            (currencyTotals[transaction.currencyCode] ?? 0) + transaction.amount;
      }

      // Convert all currency totals to USD (or selected local currency)
      for (final entry in currencyTotals.entries) {
        final rate = newRates[entry.key] ?? 1.0;
        totalBalance += entry.value / rate * (newRates['USD'] ?? 1.0);
      }

      _balanceHistory.add(totalBalance);
      _timeHistory.add(timestamp);
    }

    // Save updated history
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('balance_history', jsonEncode(_balanceHistory));
    prefs.setString('time_history',
        jsonEncode(_timeHistory.map((e) => e.toIso8601String()).toList()));

    // Sync with exchange rate provider
    if (_exchangeRateProvider != null) {
      _exchangeRateProvider!.syncBalanceHistory(_balanceHistory, _timeHistory);
    }

    notifyListeners();
  }
}
