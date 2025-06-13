import 'package:flutter/material.dart';
import 'package:kukuo/providers/exchange_rate_provider_new.dart';
import 'package:kukuo/providers/currency_provider.dart';
import 'package:kukuo/providers/transaction_provider.dart';
import 'package:kukuo/providers/balance_history_provider.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:kukuo/models/transaction_model.dart';
import 'package:kukuo/services/balance_calculator_service.dart';
import 'package:kukuo/services/currency_preference_service.dart';

/// Compatibility layer for UserInputProvider to ease migration
/// This class wraps the new providers to maintain the old interface
class UserInputProviderAdapter with ChangeNotifier {
  final CurrencyProvider _currencyProvider;
  final TransactionProvider _transactionProvider;
  final BalanceHistoryProvider _balanceHistoryProvider;
  ExchangeRateProvider? _exchangeRateProvider;

  UserInputProviderAdapter({
    required CurrencyProvider currencyProvider,
    required TransactionProvider transactionProvider,
    required BalanceHistoryProvider balanceHistoryProvider,
  })  : _currencyProvider = currencyProvider,
        _transactionProvider = transactionProvider,
        _balanceHistoryProvider = balanceHistoryProvider {
    _setupListeners();
    loadTransactions();
  }

  void _setupListeners() {
    _currencyProvider.addListener(notifyListeners);
    _transactionProvider.addListener(notifyListeners);
    _balanceHistoryProvider.addListener(notifyListeners);
  }

  // Getters that delegate to the new providers
  List<CurrencyAmount> get currencies => _currencyProvider.currencies;
  List<double> get balanceHistory => _balanceHistoryProvider.balanceHistory;
  List<DateTime> get timeHistory => _balanceHistoryProvider.timeHistory;
  List<CurrencyTransaction> get transactions =>
      _transactionProvider.transactions;

  // Set the exchange rate provider from outside
  void setExchangeRateProvider(ExchangeRateProvider exchangeRateProvider) {
    _exchangeRateProvider = exchangeRateProvider;
    if (_balanceHistoryProvider.balanceHistory.isNotEmpty &&
        _balanceHistoryProvider.timeHistory.isNotEmpty) {
      // Sync balance history if needed
      notifyListeners();
    }
  }

  Future<void> loadTransactions() async {
    await _transactionProvider.loadTransactions();
    if (_exchangeRateProvider != null &&
        _exchangeRateProvider!.exchangeRates.isNotEmpty) {
      await recalculateHistory(_exchangeRateProvider!.exchangeRates);
    }
  }

  Future<void> loadCurrencies() async {
    await _currencyProvider.loadCurrencies();
  }

  Future<bool> addCurrency(
    CurrencyAmount currency,
    Map<String, double> exchangeRates,
    String localCurrencyCode, {
    bool isSubtraction = false,
  }) async {
    final success = await _transactionProvider.addCurrencyTransaction(
      currencyCode: currency.code,
      amount: currency.amount,
      isSubtraction: isSubtraction,
    );

    if (success) {
      // Update currency totals
      final currencyTotals = _transactionProvider.calculateCurrencyTotals();
      _currencyProvider.updateCurrencyTotalsFromTransactions(currencyTotals);

      // Update balance history
      updateTotalBalance(exchangeRates, localCurrencyCode);
    }

    return success;
  }

  Future<void> updateCurrency(int index, CurrencyAmount currency,
      Map<String, double> exchangeRates, String localCurrencyCode) async {
    await _currencyProvider.updateCurrency(index, currency);
    updateTotalBalance(exchangeRates, localCurrencyCode);
  }

  Future<void> removeCurrency(int index, Map<String, double> exchangeRates,
      String localCurrencyCode) async {
    await _currencyProvider.removeCurrency(index);
    updateTotalBalance(exchangeRates, localCurrencyCode);
  }

  void updateTotalBalance(
      Map<String, double> exchangeRates, String localCurrencyCode) {
    _balanceHistoryProvider.updateBalanceHistory(
      localCurrencyCode,
      exchangeRates,
      _currencyProvider.currencies,
      getCode: (currency) => (currency as CurrencyAmount).code,
      getAmount: (currency) => (currency as CurrencyAmount).amount,
    );
  }

  double calculateTotalInLocalCurrency(
      String localCurrencyCode, Map<String, double> exchangeRates) {
    return BalanceCalculatorService.calculateTotalInLocalCurrency(
      _currencyProvider.currencies,
      localCurrencyCode,
      exchangeRates,
      getCode: (currency) => (currency as CurrencyAmount).code,
      getAmount: (currency) => (currency as CurrencyAmount).amount,
    );
  }

  List<CurrencyAmount> getConsolidatedCurrencies() {
    return _currencyProvider.getConsolidatedCurrencies();
  }

  List<Transaction> getTransactions() {
    return _transactionProvider.legacyTransactions;
  }

  Future<void> recalculateHistory(Map<String, double> newRates) async {
    final localCurrency =
        await CurrencyPreferenceService.loadSelectedCurrency();
    await _balanceHistoryProvider.recalculateHistoryFromTransactions(
      _transactionProvider.transactions,
      newRates,
      localCurrency, // Use saved local currency instead of hardcoded USD
    );
  }

  void addTransaction(CurrencyTransaction transaction) {
    _transactionProvider.addTransaction(transaction);
  }

  List<CurrencyTransaction> getTransactionsByCurrency(String currencyCode) {
    return _transactionProvider.getTransactionsByCurrency(currencyCode);
  }

  @override
  void dispose() {
    _currencyProvider.removeListener(notifyListeners);
    _transactionProvider.removeListener(notifyListeners);
    _balanceHistoryProvider.removeListener(notifyListeners);
    super.dispose();
  }
}
