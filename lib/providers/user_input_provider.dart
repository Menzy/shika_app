import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_model.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/transaction_model.dart';
import 'package:kukuo/services/firebase_service.dart';
import 'dart:async';

class UserInputProvider with ChangeNotifier {
  List<CurrencyAmount> _currencies = [];
  List<double> _balanceHistory = [];
  List<DateTime> _timeHistory = [];
  ExchangeRateProvider? _exchangeRateProvider;
  List<CurrencyTransaction> transactions = [];
  List<Transaction> _transactions = [];
  // Keep FirebaseService for interface compatibility with other parts of the app
  // We'll use it only as a placeholder since we've migrated to local storage
  final FirebaseService _firebaseService = FirebaseService();
  final StreamController<List<CurrencyTransaction>>
      _transactionStreamController =
      StreamController<List<CurrencyTransaction>>.broadcast();
  final StreamController<List<CurrencyAmount>> _currencyStreamController =
      StreamController<List<CurrencyAmount>>.broadcast();
  StreamSubscription? _transactionSubscription;
  StreamSubscription? _currencySubscription;

  List<CurrencyAmount> get currencies => _currencies;
  List<double> get balanceHistory => _balanceHistory;
  List<DateTime> get timeHistory => _timeHistory;

  void addTransaction(CurrencyTransaction transaction) {
    transactions.add(transaction);
    notifyListeners();
  }

  List<CurrencyTransaction> getTransactionsByCurrency(String currencyCode) {
    return transactions.where((t) => t.currencyCode == currencyCode).toList();
  }

  UserInputProvider() {
    // Initialize with local data
    loadTransactions();
    loadCurrencies();
  }

  // Set the exchange rate provider from outside
  void setExchangeRateProvider(ExchangeRateProvider exchangeRateProvider) {
    _exchangeRateProvider = exchangeRateProvider;
    if (_balanceHistory.isNotEmpty && _timeHistory.isNotEmpty) {
      _exchangeRateProvider!.syncBalanceHistory(_balanceHistory, _timeHistory);
    }
  }

  // Setup local listeners for data changes
  void _setupLocalListeners() {
    // Listen to transaction changes
    _transactionSubscription?.cancel();
    _transactionSubscription =
        _transactionStreamController.stream.listen((updatedTransactions) {
      print(
          'Received transaction update: ${updatedTransactions.length} transactions');
      transactions = updatedTransactions;
      _transactions = updatedTransactions
          .map((t) => Transaction(
                currencyCode: t.currencyCode,
                amount: t.amount,
                timestamp: t.timestamp,
                type: t.type,
              ))
          .toList();

      // Update currency totals based on transactions
      _updateCurrencyTotalsFromTransactions();

      if (_exchangeRateProvider != null) {
        recalculateHistory(_exchangeRateProvider!.exchangeRates);
      }
      notifyListeners();
    });

    // Listen to currency changes
    _currencySubscription?.cancel();
    _currencySubscription =
        _currencyStreamController.stream.listen((updatedCurrencies) {
      print('Received currency update: ${updatedCurrencies.length} currencies');
      _currencies = updatedCurrencies;
      notifyListeners();
    });

    // Initial data load
    _loadFromSharedPreferences().then((_) {
      _transactionStreamController.add(transactions);
      _currencyStreamController.add(_currencies);
    });
  }

  // Add this new method to update currency totals
  void _updateCurrencyTotalsFromTransactions() {
    // Create a map to store currency totals
    final Map<String, CurrencyAmount> currencyTotals = {};

    // Sort transactions by timestamp to ensure correct order
    final sortedTransactions = List.from(transactions)
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
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    _currencySubscription?.cancel();
    super.dispose();
  }

  Future<void> loadCurrencies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedCurrencies = prefs.getString('currencies');

      // Load currencies from SharedPreferences
      if (storedCurrencies != null) {
        final List<dynamic> jsonList = jsonDecode(storedCurrencies);
        _currencies =
            jsonList.map((json) => CurrencyAmount.fromJson(json)).toList();
      }

      // Load balance history
      final storedBalanceHistory = prefs.getString('balance_history');
      final storedTimeHistory = prefs.getString('time_history');

      if (storedBalanceHistory != null && storedTimeHistory != null) {
        final List<dynamic> balanceJsonList = jsonDecode(storedBalanceHistory);
        final List<dynamic> timeJsonList = jsonDecode(storedTimeHistory);

        _balanceHistory = balanceJsonList
            .map((json) =>
                (json is int) ? json.toDouble() : (json as num).toDouble())
            .toList();
        _timeHistory = timeJsonList
            .map((json) => DateTime.parse(json.toString()))
            .toList();

        // Sync with exchange rate provider if available
        if (_exchangeRateProvider != null) {
          _exchangeRateProvider!
              .syncBalanceHistory(_balanceHistory, _timeHistory);
        }
      }

      // Update currency stream
      _currencyStreamController.add(_currencies);

      notifyListeners();
    } catch (e) {
      print('Error loading currencies: $e');
      rethrow;
    }
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

      final transaction = CurrencyTransaction(
        currencyCode: currency.code,
        amount: isSubtraction ? -currency.amount.abs() : currency.amount,
        timestamp: DateTime.now(),
        type: isSubtraction ? 'Subtraction' : 'Addition',
      );

      // Save transaction to local storage
      transactions.add(transaction);
      _transactions.add(Transaction(
        currencyCode: transaction.currencyCode,
        amount: transaction.amount,
        timestamp: transaction.timestamp,
        type: transaction.type,
      ));

      // Save to local storage
      await _saveTransactions();

      // Update currency totals
      _updateCurrencyTotalsFromTransactions();

      // Update the balance history
      updateTotalBalance(exchangeRates, localCurrencyCode);

      // Notify listeners about the transaction
      _transactionStreamController.add(transactions);

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
    try {
      // Load from SharedPreferences
      await _loadFromSharedPreferences();

      // Setup local listeners
      _setupLocalListeners();

      // After loading transactions, recalculate history
      if (_exchangeRateProvider != null) {
        await recalculateHistory(_exchangeRateProvider!.exchangeRates);
      }

      notifyListeners();
    } catch (e) {
      print('Error loading transactions: $e');
      rethrow;
    }
  }

  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTransactions = prefs.getString('transactions');

    if (storedTransactions != null) {
      final List<dynamic> jsonList = jsonDecode(storedTransactions);
      transactions =
          jsonList.map((json) => CurrencyTransaction.fromJson(json)).toList();
      _transactions =
          jsonList.map((json) => Transaction.fromJson(json)).toList();
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _currencies.map((c) => c.toJson()).toList();

      // Save to SharedPreferences
      await prefs.setString('currencies', jsonEncode(jsonList));

      // Notify about currency changes
      _currencyStreamController.add(_currencies);

      notifyListeners();
    } catch (e) {
      print('Error saving currencies: $e');
      rethrow;
    }
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
    // Remove the reversed to maintain chronological order
    return List.from(_transactions);
  }

  // Add this new method to recalculate history with new rates
  Future<void> recalculateHistory(Map<String, double> newRates) async {
    if (transactions.isEmpty) return;

    // Clear existing history
    _balanceHistory = [];
    _timeHistory = [];

    // Sort transactions chronologically (oldest to newest)
    final sortedTransactions = List.from(transactions)
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
    double runningTotal = 0;
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

      // Convert all currency totals to USD (or selected local currency)
      runningTotal = 0; // Reset running total for this timestamp
      for (final entry in currencyTotals.entries) {
        final rate = newRates[entry.key] ?? 1.0;
        runningTotal += entry.value / rate * (newRates['USD'] ?? 1.0);
      }

      _balanceHistory.add(runningTotal);
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
