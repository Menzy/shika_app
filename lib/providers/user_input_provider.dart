import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_model.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/transaction_model.dart';
import 'package:kukuo/services/data_storage_service.dart';
import 'package:kukuo/services/balance_calculator_service.dart';
import 'package:kukuo/services/database_service.dart';
import 'package:kukuo/services/currency_preference_service.dart';
import 'dart:async';

class UserInputProvider with ChangeNotifier {
  String _selectedCurrency = 'USD';
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

  DatabaseService? _databaseService;

  String get selectedCurrency => _selectedCurrency;
  List<CurrencyAmount> get currencies => _currencies;
  List<double> get balanceHistory => _balanceHistory;
  List<DateTime> get timeHistory => _timeHistory;
  List<CurrencyTransaction> get transactions => _transactions;

  UserInputProvider() {
    // Initial load from local storage
    loadTransactions();
    loadCurrencies();
  }

  void setDatabaseService(DatabaseService? dbService) {
    _databaseService = dbService;
    if (_databaseService != null) {
      // Reload data from Firestore when user logs in
      loadTransactions();
      loadCurrencies();
    }
  }

  void clearData() {
    _currencies = [];
    _balanceHistory = [];
    _timeHistory = [];
    _transactions = [];
    _legacyTransactions = [];
    _databaseService = null;
    _databaseService = null;
    _selectedCurrency = 'USD'; // Reset to default on logout
    notifyListeners();
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
      List<CurrencyAmount>? loadedCurrencies;

      if (_databaseService != null) {
        // Load from Firestore
        final currenciesJson = await _databaseService!.loadCurrencies();
        if (currenciesJson != null) {
          loadedCurrencies = currenciesJson
              .map((json) => CurrencyAmount.fromJson(json))
              .toList();
        }
      } else {
        // Load from local storage
        loadedCurrencies =
            await DataStorageService.loadCurrencies<CurrencyAmount>(
          (json) => CurrencyAmount.fromJson(json),
        );
      }

      if (loadedCurrencies != null) {
        _currencies = loadedCurrencies;
        _currencyStreamController.add(_currencies);
      }

      // Load balance history
      if (_databaseService != null) {
        final historyData = await _databaseService!.loadBalanceHistory();
        if (historyData != null) {
          _balanceHistory = historyData.balances;
          _timeHistory = historyData.times;
        }
      } else {
        final historyData = await DataStorageService.loadBalanceHistory();
        if (historyData != null) {
          _balanceHistory = historyData.balances;
          _timeHistory = historyData.times;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading currencies: $e');
      // Don't rethrow, just log
    }

    // Load selected currency
    if (_databaseService != null) {
      final savedCurrency = await _databaseService!.loadSelectedCurrency();
      if (savedCurrency != null) {
        _selectedCurrency = savedCurrency;
      } else {
        // If no remote currency, try local but prioritize default if fresh login
        // Actually, let's stick to local if remote is missing, or default
        _selectedCurrency =
            await CurrencyPreferenceService.loadSelectedCurrency();
      }
    } else {
      _selectedCurrency =
          await CurrencyPreferenceService.loadSelectedCurrency();
    }
    notifyListeners();
  }

  Future<void> setSelectedCurrency(
      String currencyCode, Map<String, double> exchangeRates) async {
    if (_selectedCurrency == currencyCode) return;

    _selectedCurrency = currencyCode;
    notifyListeners();

    // Save preference
    await CurrencyPreferenceService.saveSelectedCurrency(currencyCode);

    if (_databaseService != null) {
      await _databaseService!.saveSelectedCurrency(currencyCode);
    }

    // Recalculate history with new currency
    await recalculateHistory(exchangeRates, currencyCode);
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
      debugPrint('Error adding/subtracting currency: $e');
      return false;
    }
  }

  Future<void> _saveTransactions() async {
    // Always save to local storage for offline/backup
    await DataStorageService.saveTransactions<CurrencyTransaction>(
      _transactions,
      (transaction) => transaction.toJson(),
    );

    // If logged in, save the NEWest transaction to Firestore
    // Note: This is a simplification. Ideally we sync everything.
    // Since we add one by one, we can just add the last one.
    if (_databaseService != null && _transactions.isNotEmpty) {
      await _databaseService!.saveTransaction(_transactions.last.toJson());
    }
  }

  Future<void> loadTransactions() async {
    try {
      List<CurrencyTransaction>? loadedTransactions;

      if (_databaseService != null) {
        // Load from Firestore
        final transactionsJson = await _databaseService!.loadTransactions();
        loadedTransactions = transactionsJson
            .map((json) => CurrencyTransaction.fromJson(json))
            .toList();
      } else {
        // Load from local storage
        loadedTransactions =
            await DataStorageService.loadTransactions<CurrencyTransaction>(
          (json) => CurrencyTransaction.fromJson(json),
        );
      }

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
      debugPrint('Error loading transactions: $e');
      // Don't rethrow
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
      // Save local
      await DataStorageService.saveCurrencies<CurrencyAmount>(
        _currencies,
        (currency) => currency.toJson(),
      );

      // Save remote
      if (_databaseService != null) {
        await _databaseService!
            .saveCurrencies(_currencies.map((c) => c.toJson()).toList());
      }

      _currencyStreamController.add(_currencies);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving currencies: $e');
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

    if (_databaseService != null) {
      _databaseService!.saveBalanceHistory(_balanceHistory,
          _timeHistory.map((e) => e.toIso8601String()).toList());
    }

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

    if (_databaseService != null) {
      await _databaseService!.saveBalanceHistory(_balanceHistory,
          _timeHistory.map((e) => e.toIso8601String()).toList());
    }

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
