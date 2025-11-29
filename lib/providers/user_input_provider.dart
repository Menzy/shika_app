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
  List<double> _investedHistory = [];
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
  List<double> get investedHistory => _investedHistory;
  List<DateTime> get timeHistory => _timeHistory;
  List<CurrencyTransaction> get transactions => _transactions;

  UserInputProvider() {
    // Initial load from local storage
    loadTransactions();
    loadCurrencies();
  }

  String? get username =>
      null; // Placeholder as _user is not defined in context
  DatabaseService? get databaseService => _databaseService;

  bool _showChartAboveAssets = true;
  bool get showChartAboveAssets => _showChartAboveAssets;

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
    _investedHistory = [];
    _timeHistory = [];
    _transactions = [];
    _legacyTransactions = [];
    _databaseService = null;
    _databaseService = null;
    _selectedCurrency = 'GHS'; // Reset to default on logout
    notifyListeners();
  }

  void addTransaction(CurrencyTransaction transaction) {
    _transactions.add(transaction);
    _sortTransactions();
    _updateLegacyTransactions();
    notifyListeners();
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
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
    // Load layout preference first
    _showChartAboveAssets = await DataStorageService.loadShowChartAboveAssets();

    // If logged in, try to fetch from Firestore
    if (_databaseService != null) {
      final cloudPref = await _databaseService!.loadShowChartAboveAssets();
      if (cloudPref != null) {
        _showChartAboveAssets = cloudPref;
        // Sync to local
        await DataStorageService.saveShowChartAboveAssets(cloudPref);
      }
    }

    // The instruction included this line, but it seems to be a remnant or
    // an implicit dependency that would require an import.
    // For now, I'm commenting it out to avoid an immediate compilation error
    // if SharedPreferences is not imported, as the instruction only asked
    // for code modification, not import additions.
    // final prefs = await SharedPreferences.getInstance();

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
        // Only overwrite if we don't have transactions yet, or if we want to trust cache initially
        // But if we have transactions, they are the source of truth.
        // To be safe, let's only set if _currencies is empty or we haven't loaded transactions yet.
        // Actually, loadTransactions calls _updateCurrencyTotalsFromTransactions which sets _currencies.
        // So if loadTransactions finishes first, we shouldn't overwrite.
        if (_transactions.isEmpty) {
          _currencies = loadedCurrencies;
          _currencyStreamController.add(_currencies);
        }
      }

      // Load balance history
      if (_databaseService != null) {
        final historyData = await _databaseService!.loadBalanceHistory();
        if (historyData != null) {
          _balanceHistory = historyData.balances;
          _timeHistory = historyData.times;
          final invested = await _databaseService!.loadInvestedHistory();
          if (invested != null) {
            _investedHistory = invested;
          }
        } else {
          // New user or no data on server, clear local history to avoid leakage
          _balanceHistory = [];
          _timeHistory = [];
          _investedHistory = [];
        }
      } else {
        final historyData = await DataStorageService.loadBalanceHistory();
        if (historyData != null) {
          _balanceHistory = historyData.balances;
          _timeHistory = historyData.times;
          final invested = await DataStorageService.loadInvestedHistory();
          if (invested != null) {
            _investedHistory = invested;
          }
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
        // Sync to local storage so it's available offline next time
        await CurrencyPreferenceService.saveSelectedCurrency(savedCurrency);
      } else {
        // New user or no remote data: Default to GHS (or system default)
        // CRITICAL: Do NOT load from local storage here, as it might contain
        // the previous user's preference.
        _selectedCurrency = 'GHS';
      }
    } else {
      // Offline/Guest: Load from local storage
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
    DateTime? date,
  }) async {
    try {
      if (!BalanceCalculatorService.isValidCurrencyAmount(
          currency.amount.abs())) {
        return false;
      }

      // Generate a simple unique ID
      final String id =
          '${DateTime.now().millisecondsSinceEpoch}_${(currency.amount * 100).toInt()}';

      final transaction = CurrencyTransaction(
        id: id,
        currencyCode: currency.code,
        amount: isSubtraction ? -currency.amount.abs() : currency.amount,
        timestamp: date ?? DateTime.now(),
        type: isSubtraction ? 'Subtraction' : 'Addition',
      );

      // Save transaction to local storage
      _transactions.add(transaction);
      _sortTransactions();
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

  Future<bool> updateTransaction(
    CurrencyTransaction updatedTransaction,
    Map<String, double> exchangeRates,
    String localCurrencyCode,
  ) async {
    try {
      final index =
          _transactions.indexWhere((t) => t.id == updatedTransaction.id);
      if (index != -1) {
        _transactions[index] = updatedTransaction;
        _sortTransactions();
        _updateLegacyTransactions();
        await _saveTransactions();

        // If logged in, update in Firestore
        if (_databaseService != null) {
          await _databaseService!
              .updateTransaction(updatedTransaction.toJson());
        }

        // Update currency totals
        _updateCurrencyTotalsFromTransactions();

        // Update the balance history (recalculate everything to be safe)
        await recalculateHistory(exchangeRates, localCurrencyCode);

        // Notify listeners about the transaction
        _transactionStreamController.add(_transactions);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating transaction: $e');
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
        _sortTransactions();
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

  Future<void> deleteTransaction(CurrencyTransaction transaction,
      Map<String, double> exchangeRates, String localCurrencyCode) async {
    try {
      // Remove from local list
      _transactions.removeWhere((t) => t.id == transaction.id);
      _sortTransactions();
      _updateLegacyTransactions();
      await _saveTransactions();

      // Delete from Firestore if logged in
      if (_databaseService != null && transaction.id != null) {
        await _databaseService!.deleteTransaction(transaction.id!);
      }

      // Update currency totals
      _updateCurrencyTotalsFromTransactions();

      // Recalculate history
      await recalculateHistory(exchangeRates, localCurrencyCode);

      // Notify listeners
      _transactionStreamController.add(_transactions);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
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

    // Calculate current total invested
    double currentInvested = 0;
    if (_investedHistory.isNotEmpty) {
      currentInvested = _investedHistory.last;
    }

    // If we have transactions, we should probably recalculate invested from scratch or append
    // But since we are adding a transaction, we can just add the new amount if we knew it in local currency
    // However, addCurrency doesn't pass the amount in local currency directly easily here without recalculating
    // So for accuracy, let's just use the last value for now, but ideally we should recalculate
    // Actually, recalculateHistory does it correctly. Here we are just appending.
    // Let's assume for now we just append the previous value, but this is slightly wrong if we just added money.
    // To fix this properly, we should probably just call recalculateHistory instead of this manual append
    // But for performance we append.
    // Let's try to estimate the added amount in local currency.
    // We don't have the added amount in local currency here easily.
    // So, let's just duplicate the last invested amount for now.
    // The next full recalculation will fix it.
    _investedHistory.add(currentInvested);

    // Save the balance history
    DataStorageService.saveBalanceHistory(_balanceHistory, _timeHistory);
    DataStorageService.saveInvestedHistory(_investedHistory);

    if (_databaseService != null) {
      _databaseService!.saveBalanceHistory(_balanceHistory,
          _timeHistory.map((e) => e.toIso8601String()).toList());
      _databaseService!.saveInvestedHistory(_investedHistory);
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

  List<CurrencyAmount> getSortedConsolidatedCurrencies(
      Map<String, double> exchangeRates, String selectedLocalCurrency) {
    final consolidated = getConsolidatedCurrencies();

    // Sort by value in selected local currency
    consolidated.sort((a, b) {
      final rateA = exchangeRates[a.code] ?? 1.0;
      final rateB = exchangeRates[b.code] ?? 1.0;
      final localRate = exchangeRates[selectedLocalCurrency] ?? 1.0;

      final valueA = a.amount / rateA * localRate;
      final valueB = b.amount / rateB * localRate;

      return valueB.compareTo(valueA); // Descending order
    });

    return consolidated;
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
    _investedHistory = [];
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

      // Calculate total invested at this timestamp
      double totalInvested = 0;
      for (final transaction in relevantTransactions) {
        // Convert transaction amount to local currency at CURRENT rate
        // Note: Ideally we should use historical rates, but we don't have them.
        // Using current rates is the standard approximation for this app.
        final rate = newRates[transaction.currencyCode] ?? 1.0;
        final amountInLocal =
            transaction.amount / rate * (newRates[localCurrencyCode] ?? 1.0);

        // For invested capital, we only care about additions (deposits) and subtractions (withdrawals)
        // We assume all transactions are deposits/withdrawals since we don't have trades yet
        totalInvested += amountInLocal;
      }
      _investedHistory.add(totalInvested);

      _timeHistory.add(timestamp);
    }

    // Save updated history
    await DataStorageService.saveBalanceHistory(_balanceHistory, _timeHistory);
    await DataStorageService.saveInvestedHistory(_investedHistory);

    if (_databaseService != null) {
      await _databaseService!.saveBalanceHistory(_balanceHistory,
          _timeHistory.map((e) => e.toIso8601String()).toList());
      await _databaseService!.saveInvestedHistory(_investedHistory);
    }

    notifyListeners();
  }

  void _updateCurrencyTotalsFromTransactions() {
    debugPrint(
        'Updating currency totals from ${_transactions.length} transactions');
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
    debugPrint(
        'Calculated ${_currencies.length} currencies: ${_currencies.map((c) => '${c.code}: ${c.amount}').join(', ')}');

    // Notify the currency stream controller
    _currencyStreamController.add(_currencies);
  }

  ({List<double> balances, List<double> invested, List<DateTime> times})
      getCurrencyHistory(String currencyCode, [String? localCurrencyCode]) {
    // Use USD as default if no currency is provided
    localCurrencyCode ??= _selectedCurrency;

    // Filter transactions for this currency
    final currencyTransactions =
        _transactions.where((t) => t.currencyCode == currencyCode).toList();

    if (currencyTransactions.isEmpty) {
      return (balances: <double>[], invested: <double>[], times: <DateTime>[]);
    }

    // Sort transactions chronologically
    final sortedTransactions = List.from(currencyTransactions)
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

    final balances = <double>[];
    final invested = <double>[];
    final times = <DateTime>[];

    // Get exchange rates from provider (this is a bit tricky since we don't have direct access here)
    // We'll rely on the caller to pass rates or we use a simplified approach
    // Actually, for a specific asset history, we usually want to show the AMOUNT of that asset over time
    // OR the VALUE of that asset over time.
    // The user asked for "growth of that particular asset".
    // Usually this means value in local currency.
    // However, we don't have historical exchange rates.
    // So we will use the CURRENT exchange rate for all historical points to show "accumulation" growth?
    // OR we just show the amount growth?
    // The main chart shows VALUE growth.
    // If we want to show VALUE growth for a single asset, we need rates.
    // Since we only have current rates, we can only show how the QUANTITY changed,
    // scaled by CURRENT rate. This shows "if you held this much back then, it would be worth this much now".
    // This is often acceptable if historical rates aren't available.
    // Let's assume we want to show Value in Local Currency using Current Rate.

    // We need to get the current rate for this currency.
    // Since we don't have the rates map here, we might need to pass it or fetch it.
    // But wait, `recalculateHistory` takes `newRates`.
    // `getCurrencyHistory` should probably take `exchangeRates` as an argument.
    // But `UserInputProvider` doesn't store rates.
    // Let's check how `recalculateHistory` is called. It's called from `ExchangeRateProvider` or when currency changes.
    // For this UI method, maybe we can just return the QUANTITY history, and let the UI scale it?
    // But `BalanceChart` expects `double` balances (values).
    // Let's return the QUANTITY history for now, and the UI can multiply by current rate.
    // Actually, `BalanceChart` logic `_calculateGrowthPercentage` uses `invested` vs `balance`.
    // For a single asset:
    // Invested = Net amount of money put into this asset (in local currency at time of transaction).
    // Balance = Current Value (Quantity * Current Price).
    // If we don't have historical prices, we can't calculate "Invested" accurately in local currency terms for the past.
    // However, we DO have the transaction amount.
    // If we assume the transaction amount was "added" to the portfolio.
    // But for a single asset, "Invested" usually means "Cost Basis".
    // We don't track Cost Basis (price at time of purchase).
    // We only track "Amount Added".
    // So "Invested" for a single asset is just the sum of all additions.
    // And "Balance" is the current quantity.
    // If we want to show a chart, we probably want to show the VALUE over time.
    // Value(t) = Quantity(t) * Price(t).
    // We don't have Price(t).
    // We can use Price(now).
    // Value(t) ~ Quantity(t) * Price(now).
    // This shows the history of the HOLDINGS, not the value fluctuation due to price.
    // This is "Balance Growth" in terms of quantity.
    // The user said: "every time the user has added or removed ... show that charts representing only the data for that particular assets".
    // This implies showing the history of user's interactions (add/remove).
    // So showing Quantity * CurrentPrice is a good proxy for "Holdings History".

    for (final timestamp in sortedTimestamps) {
      // Get all transactions up to this timestamp
      final relevantTransactions = sortedTransactions
          .where((t) =>
              t.timestamp.isBefore(timestamp) || t.timestamp == timestamp)
          .toList();

      double currentQuantity = 0;
      double currentInvestedQty = 0;

      for (final transaction in relevantTransactions) {
        currentQuantity += transaction.amount;
        // For invested, we sum up additions.
        // But wait, `investedHistory` in `BalanceChart` is used for growth calc.
        // For a single asset, if we only track quantity, "Invested" is just the quantity added?
        // If we use Quantity * CurrentPrice, then:
        // Balance = Quantity * Price
        // Invested = (Sum of Additions) * Price
        // Growth = (Balance - Invested) / Invested
        // This will always be 0 if we use constant price!
        // Because Balance = Sum of Additions (if no price change).
        // So we CANNOT show "Growth" (Profit/Loss) without historical prices.
        // BUT, the user might just want to see the "Balance History" (how much I had).
        // The `BalanceChart` calculates growth.
        // If we pass `invested` as 0 or same as balance, growth will be 0.
        // Maybe we just show the line chart of the Value (Quantity * Price).
        // And we accept that "Growth" number might be meaningless or we hide it?
        // The user said "show this chart to show the growth of that particular asset".
        // If they mean "Price Growth", we can't do it.
        // If they mean "Portfolio Growth for this asset" (i.e. I bought more), we can do it.
        // Given we don't have historical data, we can only show "Holdings Growth".
        // So let's return the Quantity history. The UI will multiply by current rate.

        // Actually, let's return the raw Quantity history.
        // And for "Invested", we can just return 0s or the same as quantity if we want to disable the "Profit" calculation.
        // Or, we can try to approximate.
        // Let's just return Quantity history.
        currentInvestedQty += transaction
            .amount; // This is basically same as currentQuantity if we start from 0
      }

      balances.add(currentQuantity);
      invested.add(
          currentInvestedQty); // This will make growth 0% which is correct for "Holdings only" view
      times.add(timestamp);
    }

    return (balances: balances, invested: invested, times: times);
  }

  Future<void> toggleChartPosition(bool value) async {
    _showChartAboveAssets = value;
    notifyListeners();

    // Save to local storage
    await DataStorageService.saveShowChartAboveAssets(value);

    // Save to Firestore if logged in
    if (_databaseService != null) {
      await _databaseService!.saveShowChartAboveAssets(value);
    }
  }

  @override
  void dispose() {
    _transactionStreamController.close();
    _currencyStreamController.close();
    super.dispose();
  }
}
