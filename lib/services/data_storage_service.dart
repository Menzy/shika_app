import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DataStorageService {
  // Exchange rates storage
  static Future<void> saveExchangeRates(Map<String, double> rates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('exchange_rates', jsonEncode(rates));
    await prefs.setString('last_fetch_time', DateTime.now().toIso8601String());
  }

  static Future<Map<String, double>?> loadExchangeRates() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRates = prefs.getString('exchange_rates');

    if (storedRates != null) {
      return Map<String, double>.from(jsonDecode(storedRates));
    }
    return null;
  }

  // Balance history storage
  static Future<void> saveBalanceHistory(
      List<double> balances, List<DateTime> times) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('balance_history', jsonEncode(balances));
    await prefs.setString('time_history',
        jsonEncode(times.map((e) => e.toIso8601String()).toList()));
  }

  static Future<({List<double> balances, List<DateTime> times})?>
      loadBalanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final storedBalanceHistory = prefs.getString('balance_history');
    final storedTimeHistory = prefs.getString('time_history');

    if (storedBalanceHistory != null && storedTimeHistory != null) {
      final balances = List<double>.from(jsonDecode(storedBalanceHistory));
      final times = (jsonDecode(storedTimeHistory) as List)
          .map((e) => DateTime.parse(e))
          .toList();

      return (balances: balances, times: times);
    }
    return null;
  }

  // Invested history storage
  static Future<void> saveInvestedHistory(List<double> investedHistory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invested_history', jsonEncode(investedHistory));
  }

  static Future<List<double>?> loadInvestedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final storedInvestedHistory = prefs.getString('invested_history');

    if (storedInvestedHistory != null) {
      return List<double>.from(jsonDecode(storedInvestedHistory));
    }
    return null;
  }

  // Currencies storage
  static Future<void> saveCurrencies<T>(
      List<T> currencies, Map<String, dynamic> Function(T) toJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = currencies.map((c) => toJson(c)).toList();
    await prefs.setString('currencies', jsonEncode(jsonList));
  }

  static Future<List<T>?> loadCurrencies<T>(
      T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCurrencies = prefs.getString('currencies');

    if (storedCurrencies != null) {
      final List<dynamic> jsonList = jsonDecode(storedCurrencies);
      return jsonList.map((json) => fromJson(json)).toList();
    }
    return null;
  }

  // Transactions storage
  static Future<void> saveTransactions<T>(
      List<T> transactions, Map<String, dynamic> Function(T) toJson) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => toJson(t)).toList();
    await prefs.setString('transactions', jsonEncode(jsonList));
  }

  static Future<List<T>?> loadTransactions<T>(
      T Function(Map<String, dynamic>) fromJson) async {
    final prefs = await SharedPreferences.getInstance();
    final storedTransactions = prefs.getString('transactions');

    if (storedTransactions != null) {
      final List<dynamic> jsonList = jsonDecode(storedTransactions);
      return jsonList.map((json) => fromJson(json)).toList();
    }
    return null;
  }

  // Generic storage methods
  static Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> loadString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  static Future<double?> loadDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  static Future<void> saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<bool?> loadBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
