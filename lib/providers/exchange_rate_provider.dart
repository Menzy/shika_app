import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kukuo/services/api_service.dart';
import 'dart:convert';

class ExchangeRateProvider with ChangeNotifier {
  Map<String, double> _exchangeRates = {};

  Map<String, double> get exchangeRates => _exchangeRates;

  Future<void> fetchExchangeRates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getString('last_fetch_time');

    // Fetch rates only if a day has passed
    if (lastFetchTime == null || _shouldFetchAgain(lastFetchTime)) {
      try {
        _exchangeRates = await ApiService.fetchExchangeRates();
        prefs.setString('exchange_rates', jsonEncode(_exchangeRates));
        prefs.setString('last_fetch_time', DateTime.now().toIso8601String());
      } catch (e) {
        print('Error fetching rates: $e');
      }
    } else {
      // Load from local storage
      final storedRates = prefs.getString('exchange_rates');
      if (storedRates != null) {
        _exchangeRates = Map<String, double>.from(jsonDecode(storedRates));
      }
    }
    notifyListeners();
  }

  bool _shouldFetchAgain(String lastFetchTime) {
    final lastFetchDate = DateTime.parse(lastFetchTime);
    final now = DateTime.now();
    return now.difference(lastFetchDate).inDays >= 1;
  }
}
