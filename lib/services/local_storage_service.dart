import 'dart:convert';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _currenciesKey = 'currencies';
  static const String _balanceHistoryKey = 'balance_history';
  static const String _timeHistoryKey = 'time_history';
  static const String _transactionsKey = 'transactions';
  static const String _lastFetchTimeKey = 'last_fetch_time';
  static const String _exchangeRatesKey = 'exchange_rates';

  // Currency Operations
  Future<List<CurrencyAmount>> loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCurrencies = prefs.getString(_currenciesKey);
    if (storedCurrencies != null) {
      final List<dynamic> jsonList = jsonDecode(storedCurrencies);
      return jsonList.map((json) => CurrencyAmount.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> saveCurrencies(List<CurrencyAmount> currencies) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = currencies.map((c) => c.toJson()).toList();
    await prefs.setString(_currenciesKey, jsonEncode(jsonList));
  }

  // Transaction Operations
  Future<List<CurrencyTransaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTransactions = prefs.getString(_transactionsKey);
    if (storedTransactions != null) {
      final List<dynamic> jsonList = jsonDecode(storedTransactions);
      return jsonList.map((json) => CurrencyTransaction.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> saveTransactions(List<CurrencyTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => t.toJson()).toList();
    await prefs.setString(_transactionsKey, jsonEncode(jsonList));
  }

  // Balance History Operations
  Future<Map<String, dynamic>> loadBalanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final storedBalances = prefs.getString(_balanceHistoryKey);
    final storedTimes = prefs.getString(_timeHistoryKey);

    if (storedBalances != null && storedTimes != null) {
      return {
        'balances': List<double>.from(jsonDecode(storedBalances)),
        'times': (jsonDecode(storedTimes) as List)
            .map((e) => DateTime.parse(e))
            .toList(),
      };
    }
    return {'balances': <double>[], 'times': <DateTime>[]};
  }

  Future<void> saveBalanceHistory(
      List<double> balances, List<DateTime> times) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_balanceHistoryKey, jsonEncode(balances));
    await prefs.setString(
        _timeHistoryKey,
        jsonEncode(
            times.map((time) => time.toIso8601String()).toList()));
  }

  // Exchange Rate Operations
  Future<Map<String, double>?> loadExchangeRates() async {
    final prefs = await SharedPreferences.getInstance();
    final rates = prefs.getString(_exchangeRatesKey);
    if (rates != null) {
      Map<String, dynamic> ratesMap = jsonDecode(rates);
      return ratesMap.map((key, value) => MapEntry(key, value.toDouble()));
    }
    return null;
  }

  Future<void> saveExchangeRates(Map<String, double> rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_exchangeRatesKey, jsonEncode(rates));
  }

  Future<DateTime?> getLastFetchTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastFetchTimeKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  Future<void> saveLastFetchTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFetchTimeKey, time.toIso8601String());
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}