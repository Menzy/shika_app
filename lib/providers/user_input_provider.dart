import 'package:flutter/material.dart';
import 'package:kukuo/models/currency_model.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:kukuo/providers/exchange_rate_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/transaction_model.dart';
import 'package:kukuo/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class UserInputProvider with ChangeNotifier {
  List<CurrencyAmount> _currencies = [];
  List<double> _balanceHistory = [];
  List<DateTime> _timeHistory = [];
  ExchangeRateProvider? _exchangeRateProvider; // Add this
  List<CurrencyTransaction> transactions = [];
  List<Transaction> _transactions = [];
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _transactionSubscription;
  StreamSubscription? _currencySubscription;

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
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User logged in, setup listeners
        _setupFirebaseListeners();
        loadTransactions(); // Load initial data
        loadCurrencies();
      } else {
        // User logged out, cancel listeners
        _transactionSubscription?.cancel();
        _currencySubscription?.cancel();
        // Clear local data
        transactions = [];
        _transactions = [];
        _currencies = [];
        notifyListeners();
      }
    });
  }

  void _setupFirebaseListeners() {
    final user = _auth.currentUser;
    if (user != null) {
      // Listen to transaction changes
      _transactionSubscription?.cancel(); // Cancel existing subscription if any
      _transactionSubscription = _firebaseService
          .watchTransactions(user.uid)
          .listen((updatedTransactions) {
        print(
            'Received transaction update: ${updatedTransactions.length} transactions'); // Debug log
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
      }, onError: (error) {
        print('Error in transaction stream: $error'); // Error logging
      });

      // Listen to currency changes
      _currencySubscription?.cancel(); // Cancel existing subscription if any
      _currencySubscription = _firebaseService.watchCurrencies(user.uid).listen(
          (updatedCurrencies) {
        print(
            'Received currency update: ${updatedCurrencies.length} currencies'); // Debug log
        _currencies = updatedCurrencies;
        notifyListeners();
      }, onError: (error) {
        print('Error in currency stream: $error'); // Error logging
      });
    }
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
      // Load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final storedCurrencies = prefs.getString('currencies');

      // Load from Firebase if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        final firebaseCurrencies =
            await _firebaseService.loadCurrencies(user.uid);
        if (firebaseCurrencies.isNotEmpty) {
          _currencies = firebaseCurrencies;
        } else if (storedCurrencies != null) {
          // Use local data if Firebase is empty
          final List<dynamic> jsonList = jsonDecode(storedCurrencies);
          _currencies =
              jsonList.map((json) => CurrencyAmount.fromJson(json)).toList();
          // Sync to Firebase
          await _firebaseService.saveCurrencyData(user.uid, _currencies);
        }
      } else if (storedCurrencies != null) {
        // Fallback to local storage if not logged in
        final List<dynamic> jsonList = jsonDecode(storedCurrencies);
        _currencies =
            jsonList.map((json) => CurrencyAmount.fromJson(json)).toList();
      }

      final storedBalanceHistory = prefs.getString('balance_history');
      final storedTimeHistory = prefs.getString('time_history');

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
          _exchangeRateProvider!
              .syncBalanceHistory(_balanceHistory, _timeHistory);
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
          _exchangeRateProvider!
              .syncBalanceHistory(_balanceHistory, _timeHistory);
        }
      }

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

      // Save to Firebase first
      final user = _auth.currentUser;
      if (user != null) {
        await _firebaseService.saveTransaction(user.uid, transaction);
        // Currency totals will be updated through the Firebase listener
      }

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
      // Load from Firebase if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        final firebaseTransactions =
            await _firebaseService.loadTransactions(user.uid);
        if (firebaseTransactions.isNotEmpty) {
          transactions = firebaseTransactions;
          _transactions = firebaseTransactions
              .map((t) => Transaction(
                    currencyCode: t.currencyCode,
                    amount: t.amount,
                    timestamp: t.timestamp,
                    type: t.type,
                  ))
              .toList();
        } else {
          // Load from SharedPreferences as fallback
          await _loadFromSharedPreferences();
          // Sync local data to Firebase
          for (var transaction in transactions) {
            await _firebaseService.saveTransaction(user.uid, transaction);
          }
        }

        // Setup real-time listeners
        _setupFirebaseListeners();
      } else {
        // Load from SharedPreferences if not logged in
        await _loadFromSharedPreferences();
      }

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

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTransactions = prefs.getString('transactions');

    if (storedTransactions != null) {
      final List<dynamic> jsonList = jsonDecode(storedTransactions);
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

      // Save to Firebase if user is logged in
      final user = _auth.currentUser;
      if (user != null) {
        await _firebaseService.saveCurrencyData(user.uid, _currencies);
      }

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
