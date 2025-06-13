import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_model.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/transaction_model.dart';
import 'package:kukuo/services/data_storage_service.dart';
import 'package:kukuo/services/balance_calculator_service.dart';
import 'dart:async';

class UserInputProvider with ChangeNotifier {
  List<CurrencyAmount> _currencies = [];
  List<double> _balanceHistory = [];
  List<DateTime> _timeHistory = [];
  List<CurrencyTransaction> _transactions = [];
  List<Transaction> _legacyTransactions = [];

  final StreamController<List<CurrencyTransaction>>
      _transactionStreamController =
      StreamController<List<CurrencyTransaction>>.broadcast();
  final StreamController<List<CurrencyAmount>> _currencyStreamController =
      StreamController<List<CurrencyAmount>>.broadcast();

  List<CurrencyAmount> get currencies => _currencies;
  List<double> get balanceHistory => _balanceHistory;
  List<DateTime> get timeHistory => _timeHistory;
  List<CurrencyTransaction> get transactions => _transactions;

  UserInputProvider() {
    loadTransactions();
    loadCurrencies();
  }

  void addTransaction(CurrencyTransaction transaction) {
    _transactions.add(transaction);
    _updateLegacyTransactions();
    notifyListeners();
  }

  List<CurrencyTransaction> getTransactionsByCurrency(String currencyCode) {
    return _transactions.where((t) => t.currencyCode == currencyCode).toList();
  }

  void _updateLegacyTransactions() {
    _legacyTransactions = _transactions
        .map((t) => Transaction(
              currencyCode: t.currencyCode,
              amount: t.amount,
              timestamp: t.timestamp,
              type: t.type,
            ))
        .toList();
  }

  // Set the exchange rate provider from outside - kept for backward compatibility
  void setExchangeRateProvider(dynamic exchangeRateProvider) {
    // This method is kept for backward compatibility
    // The coupling is now handled differently through the service layer
  }

  Future<void> loadCurrencies() async {
    try {
      final loadedCurrencies =
          await DataStorageService.loadCurrencies<CurrencyAmount>(
        (json) => CurrencyAmount.fromJson(json),
      );

      if (loadedCurrencies != null) {
        _currencies = loadedCurrencies;
        _currencyStreamController.add(_currencies);
      }

      // Load balance history
      final historyData = await DataStorageService.loadBalanceHistory();
      if (historyData != null) {
        _balanceHistory = historyData.balances;
        _timeHistory = historyData.times;
      }

      notifyListeners();
    } catch (e) {
      print('Error loading currencies: $e');
      rethrow;
    }
  }

  Future<bool> addCurrency(
    CurrencyAmount currency,
    Map<String, double> exchangeRates,
    String localCurrencyCode, {
    bool isSubtraction = false,
  }) async {
    try {
      if (!BalanceCalculatorService.isValidCurrencyAmount(
          currency.amount.abs())) {
        return false;
      }

      final transaction = CurrencyTransaction(
        currencyCode: currency.code,
        amount: isSubtraction ? -currency.amount.abs() : currency.amount,
        timestamp: DateTime.now(),
        type: isSubtraction ? 'Subtraction' : 'Addition',
      );

      // Save transaction to local storage
      _transactions.add(transaction);
      _updateLegacyTransactions();
      await _saveTransactions();

      // Update currency totals
      _updateCurrencyTotalsFromTransactions();

      // Update the balance history
      updateTotalBalance(exchangeRates, localCurrencyCode);

      // Notify listeners about the transaction
      _transactionStreamController.add(_transactions);

      notifyListeners(); // Add this to notify Consumer widgets

      return true;
    } catch (e) {
      print('Error adding/subtracting currency: $e');
      return false;
    }
  }

  Future<void> _saveTransactions() async {
    await DataStorageService.saveTransactions<CurrencyTransaction>(
      _transactions,
      (transaction) => transaction.toJson(),
    );
  }

  Future<void> loadTransactions() async {
    try {
      final loadedTransactions =
          await DataStorageService.loadTransactions<CurrencyTransaction>(
        (json) => CurrencyTransaction.fromJson(json),
      );

      if (loadedTransactions != null) {
        _transactions = loadedTransactions;
        _updateLegacyTransactions();
        _transactionStreamController.add(_transactions);

        // Recalculate currencies from transactions
        _updateCurrencyTotalsFromTransactions();

        // Save the recalculated currencies
        await _saveCurrencies();
      }

      notifyListeners();
    } catch (e) {
      print('Error loading transactions: $e');
      rethrow;
    }
  }

  Future<void> updateCurrency(int index, CurrencyAmount currency,
      Map<String, double> exchangeRates, String localCurrencyCode) async {
    if (index >= 0 && index < _currencies.length) {
      _currencies[index] = currency;
      await _saveCurrencies();
      updateTotalBalance(exchangeRates, localCurrencyCode);
    }
  }

  Future<void> removeCurrency(int index, Map<String, double> exchangeRates,
      String localCurrencyCode) async {
    if (index >= 0 && index < _currencies.length) {
      _currencies.removeAt(index);
      await _saveCurrencies();
      updateTotalBalance(exchangeRates, localCurrencyCode);
    }
  }

  Future<void> _saveCurrencies() async {
    try {
      await DataStorageService.saveCurrencies<CurrencyAmount>(
        _currencies,
        (currency) => currency.toJson(),
      );

      _currencyStreamController.add(_currencies);
      notifyListeners();
    } catch (e) {
      print('Error saving currencies: $e');
      rethrow;
    }
  }

  void updateTotalBalance(
      Map<String, double> exchangeRates, String localCurrencyCode) {
    double totalBalance =
        calculateTotalInLocalCurrency(localCurrencyCode, exchangeRates);

    _balanceHistory.add(totalBalance);
    _timeHistory.add(DateTime.now());

    // Save the balance history
    DataStorageService.saveBalanceHistory(_balanceHistory, _timeHistory);

    notifyListeners();
  }

  double calculateTotalInLocalCurrency(
      String localCurrencyCode, Map<String, double> exchangeRates) {
    return BalanceCalculatorService.calculateTotalInLocalCurrency(
      _currencies,
      localCurrencyCode,
      exchangeRates,
      getCode: (currency) => (currency as CurrencyAmount).code,
      getAmount: (currency) => (currency as CurrencyAmount).amount,
    );
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

    return consolidated.entries
        .map((entry) {
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
        })
        .where((c) => c.amount > 0)
        .toList();
  }

  List<Transaction> getTransactions() {
    return List.from(_legacyTransactions);
  }

  Future<void> recalculateHistory(Map<String, double> newRates,
      [String? localCurrencyCode]) async {
    if (_transactions.isEmpty) return;

    // Use USD as default if no currency is provided
    localCurrencyCode ??= 'USD';

    // Clear existing history
    _balanceHistory = [];
    _timeHistory = [];

    // Sort transactions chronologically
    final sortedTransactions = List.from(_transactions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Get all unique timestamps from transactions
    final Set<DateTime> uniqueTimestamps = sortedTransactions
        .map((t) => DateTime(
              t.timestamp.year,
              t.timestamp.month,
              t.timestamp.day,
              t.timestamp.hour,
              t.timestamp.minute,
            ))
        .toSet()
      ..add(DateTime.now());

    // Sort timestamps chronologically
    final sortedTimestamps = uniqueTimestamps.toList()..sort();

    // Calculate balance at each timestamp
    for (final timestamp in sortedTimestamps) {
      // Get all transactions up to this timestamp
      final relevantTransactions = sortedTransactions
          .where((t) =>
              t.timestamp.isBefore(timestamp) || t.timestamp == timestamp)
          .toList();

      // Calculate total balance at this timestamp
      final Map<String, double> currencyTotals = {};

      for (final transaction in relevantTransactions) {
        currencyTotals[transaction.currencyCode] =
            (currencyTotals[transaction.currencyCode] ?? 0) +
                transaction.amount;
      }

      // Convert all currency totals to the specified local currency
      double runningTotal = 0;
      for (final entry in currencyTotals.entries) {
        final rate = newRates[entry.key] ?? 1.0;
        runningTotal +=
            entry.value / rate * (newRates[localCurrencyCode] ?? 1.0);
      }

      _balanceHistory.add(runningTotal);
      _timeHistory.add(timestamp);
    }

    // Save updated history
    await DataStorageService.saveBalanceHistory(_balanceHistory, _timeHistory);

    notifyListeners();
  }

  void _updateCurrencyTotalsFromTransactions() {
    // Create a map to store currency totals
    final Map<String, CurrencyAmount> currencyTotals = {};

    // Sort transactions by timestamp to ensure correct order
    final sortedTransactions = List.from(_transactions)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Calculate totals from transactions
    for (var transaction in sortedTransactions) {
      if (!currencyTotals.containsKey(transaction.currencyCode)) {
        // Find currency details from existing currencies or create new
        final existingCurrency = _currencies.firstWhere(
          (c) => c.code == transaction.currencyCode,
          orElse: () => CurrencyAmount(
            code: transaction.currencyCode,
            amount: 0,
            name: transaction.currencyCode,
            flag: '🏳️',
          ),
        );

        currencyTotals[transaction.currencyCode] = CurrencyAmount(
          code: existingCurrency.code,
          name: existingCurrency.name,
          flag: existingCurrency.flag,
          amount: 0,
        );
      }

      // Update the amount
      final current = currencyTotals[transaction.currencyCode]!;
      currencyTotals[transaction.currencyCode] = CurrencyAmount(
        code: current.code,
        name: current.name,
        flag: current.flag,
        amount: current.amount + transaction.amount,
      );
    }

    // Update _currencies with the calculated totals
    _currencies = currencyTotals.values.where((c) => c.amount > 0).toList();

    // Notify the currency stream controller
    _currencyStreamController.add(_currencies);
  }

  @override
  void dispose() {
    _transactionStreamController.close();
    _currencyStreamController.close();
    super.dispose();
  }
}
