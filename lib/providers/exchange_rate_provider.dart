import 'package:flutter/material.dart';
import 'package:kukuo/services/exchange_rate_service.dart';
import 'package:kukuo/services/data_storage_service.dart';

class ExchangeRateProvider with ChangeNotifier {
  Map<String, double> _exchangeRates = {};
  List<double> _balanceHistory = [];
  List<DateTime> _timeHistory = [];
  bool _isLoading = false;
  String? _error;

  Map<String, double> get exchangeRates => _exchangeRates;
  List<double> get balanceHistory => _balanceHistory;
  List<DateTime> get timeHistory => _timeHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchExchangeRates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exchangeRates = await ExchangeRateService.getExchangeRates();
      await _loadBalanceHistory();
      _error = null;
    } catch (e) {
      _error = 'Failed to fetch exchange rates: $e';
      debugPrint('Error fetching exchange rates: $e');
      await _loadBalanceHistory(); // Load cached balance history even if rates fail
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadBalanceHistory() async {
    try {
      final historyData = await DataStorageService.loadBalanceHistory();
      if (historyData != null) {
        _balanceHistory = historyData.balances;
        _timeHistory = historyData.times;
      }
    } catch (e) {
      debugPrint('Error loading balance history: $e');
    }
  }

  Future<bool> shouldRefreshRates() async {
    return await ExchangeRateService.shouldFetchAgain();
  }

  Future<bool> haveRatesChanged() async {
    if (_exchangeRates.isEmpty) return true;
    return await ExchangeRateService.haveRatesChanged(_exchangeRates);
  }

  double? getRate(String currencyCode) {
    return _exchangeRates[currencyCode];
  }

  bool hasRate(String currencyCode) {
    return _exchangeRates.containsKey(currencyCode);
  }

  List<String> get availableCurrencies => _exchangeRates.keys.toList();

  int get currencyCount => _exchangeRates.length;

  bool get isEmpty => _exchangeRates.isEmpty;

  bool get isNotEmpty => _exchangeRates.isNotEmpty;

  void clearRates() {
    _exchangeRates.clear();
    notifyListeners();
  }

  void updateRates(Map<String, double> newRates) {
    _exchangeRates = Map.from(newRates);
    notifyListeners();
  }

  // Legacy methods for backward compatibility
  void setUserInputProvider(dynamic userInputProvider) {
    // This method is kept for backward compatibility but no longer needed
    // The coupling between providers is now handled differently
  }

  void syncBalanceHistory(List<double> balances, List<DateTime> times) {
    _balanceHistory = List.from(balances);
    _timeHistory = List.from(times);
    notifyListeners();
  }
}
