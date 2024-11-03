import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kukuo/services/api_service.dart';
import 'dart:convert';
import 'package:kukuo/providers/user_input_provider.dart';

class ExchangeRateProvider with ChangeNotifier {
  Map<String, double> _exchangeRates = {};
  List<double> _balanceHistory = [];
  List<DateTime> _timeHistory = [];
  UserInputProvider? _userInputProvider; // Reference to UserInputProvider

  Map<String, double> get exchangeRates => _exchangeRates;
  List<double> get balanceHistory => _balanceHistory;
  List<DateTime> get timeHistory => _timeHistory;

  // Add a cache duration constant
  static const cacheDuration = Duration(hours: 12);

  Future<void> fetchExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getString('last_fetch_time');
      final storedRates = prefs.getString('exchange_rates');

      if (_shouldUseCachedData(lastFetchTime) && storedRates != null) {
        _loadCachedRates(storedRates);
      } else {
        await _fetchAndUpdateRates(prefs);
      }

      // Load balance history if it hasn't been synced yet
      if (_balanceHistory.isEmpty) {
        final storedBalanceHistory = prefs.getString('balance_history');
        final storedTimeHistory = prefs.getString('time_history');
        
        if (storedBalanceHistory != null && storedTimeHistory != null) {
          _balanceHistory = List<double>.from(jsonDecode(storedBalanceHistory));
          _timeHistory = (jsonDecode(storedTimeHistory) as List)
              .map((e) => DateTime.parse(e))
              .toList();
          notifyListeners();
        }
      }
    } catch (e) {
      // Load cached data as fallback
      final prefs = await SharedPreferences.getInstance();
      final storedRates = prefs.getString('exchange_rates');
      if (storedRates != null) {
        _loadCachedRates(storedRates);
      }
      rethrow;
    }
    notifyListeners();
  }

  bool _shouldUseCachedData(String? lastFetchTime) {
    if (lastFetchTime == null) return false;
    final lastFetch = DateTime.parse(lastFetchTime);
    return DateTime.now().difference(lastFetch) < cacheDuration;
  }

  void _loadCachedRates(String storedRates) {
    _exchangeRates = Map<String, double>.from(jsonDecode(storedRates));
  }

  Future<void> _fetchAndUpdateRates(SharedPreferences prefs) async {
    final lastFetchTime = prefs.getString('last_fetch_time');

    if (lastFetchTime == null || _shouldFetchAgain(lastFetchTime)) {
      try {
        final newRates = await ApiService.fetchExchangeRates();
        final bool hasRatesChanged = _haveRatesChanged(newRates);
        
        _exchangeRates = newRates;
        prefs.setString('exchange_rates', jsonEncode(_exchangeRates));
        prefs.setString('last_fetch_time', DateTime.now().toIso8601String());

        // If rates have changed, update all history with new rates
        if (hasRatesChanged && _userInputProvider != null) {
          await _userInputProvider!.recalculateHistory(_exchangeRates);
        }

      } catch (e) {
        print('Error fetching rates: $e');
      }
    } else {
      // Load from local storage
      final storedRates = prefs.getString('exchange_rates');
      if (storedRates != null) {
        _exchangeRates = Map<String, double>.from(jsonDecode(storedRates));
      }

      // Load existing balance history
      await _loadBalanceHistory(prefs);
    }

    // Update user total balance after fetching exchange rates
    if (_userInputProvider != null) {
      _userInputProvider!.updateTotalBalance(
          _exchangeRates, 'USD'); // Update balance in default local currency
    }

    notifyListeners();
  }

  bool _haveRatesChanged(Map<String, double> newRates) {
    if (_exchangeRates.isEmpty) return true;
    
    for (final entry in newRates.entries) {
      final oldRate = _exchangeRates[entry.key];
      if (oldRate == null || oldRate != entry.value) {
        return true;
      }
    }
    return false;
  }

  Future<void> _updateBalanceHistory(SharedPreferences prefs) async {
    // Assuming you have a function to calculate the total balance based on currencies the user has
    double totalBalance = _calculateTotalBalance();

    // Append the new balance and timestamp to the history
    _balanceHistory.add(totalBalance);
    _timeHistory.add(DateTime.now());

    // Save to SharedPreferences
    prefs.setString('balance_history', jsonEncode(_balanceHistory));
    prefs.setString('time_history',
        jsonEncode(_timeHistory.map((e) => e.toIso8601String()).toList()));
  }

  Future<void> _loadBalanceHistory(SharedPreferences prefs) async {
    final storedBalanceHistory = prefs.getString('balance_history');
    final storedTimeHistory = prefs.getString('time_history');

    if (storedBalanceHistory != null && storedTimeHistory != null) {
      _balanceHistory = List<double>.from(jsonDecode(storedBalanceHistory));
      _timeHistory = (jsonDecode(storedTimeHistory) as List)
          .map((e) => DateTime.parse(e))
          .toList();
    }
  }

  bool _shouldFetchAgain(String lastFetchTime) {
    final lastFetchDate = DateTime.parse(lastFetchTime);
    final now = DateTime.now();
    return now.difference(lastFetchDate).inDays >= 1;
  }

  // Link UserInputProvider for balance updates
  void setUserInputProvider(UserInputProvider userInputProvider) {
    _userInputProvider = userInputProvider;
  }

  double _calculateTotalBalance() {
    if (_userInputProvider == null) return 0.0;
    return _userInputProvider!
        .calculateTotalInLocalCurrency('USD', _exchangeRates);
  }

// In ExchangeRateProvider
  void syncBalanceHistory(List<double> balances, List<DateTime> times) {
    _balanceHistory = balances;
    _timeHistory = times;
    notifyListeners();
  }
}
