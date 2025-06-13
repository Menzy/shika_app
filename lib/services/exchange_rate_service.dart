import 'package:shared_preferences/shared_preferences.dart';
import 'package:kukuo/services/api_service.dart';
import 'dart:convert';

class ExchangeRateService {
  static const cacheDuration = Duration(hours: 12);

  static Future<Map<String, double>> getExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastFetchTime = prefs.getString('last_fetch_time');
      final storedRates = prefs.getString('exchange_rates');

      if (_shouldUseCachedData(lastFetchTime) && storedRates != null) {
        return _loadCachedRates(storedRates);
      } else {
        return await _fetchAndCacheRates(prefs);
      }
    } catch (e) {
      // Load cached data as fallback
      final prefs = await SharedPreferences.getInstance();
      final storedRates = prefs.getString('exchange_rates');
      if (storedRates != null) {
        return _loadCachedRates(storedRates);
      }
      rethrow;
    }
  }

  static bool _shouldUseCachedData(String? lastFetchTime) {
    if (lastFetchTime == null) return false;
    final lastFetch = DateTime.parse(lastFetchTime);
    return DateTime.now().difference(lastFetch) < cacheDuration;
  }

  static Map<String, double> _loadCachedRates(String storedRates) {
    return Map<String, double>.from(jsonDecode(storedRates));
  }

  static Future<Map<String, double>> _fetchAndCacheRates(
      SharedPreferences prefs) async {
    final newRates = await ApiService.fetchExchangeRates();

    // Cache the new rates
    await prefs.setString('exchange_rates', jsonEncode(newRates));
    await prefs.setString('last_fetch_time', DateTime.now().toIso8601String());

    return newRates;
  }

  static Future<bool> shouldFetchAgain() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetchTime = prefs.getString('last_fetch_time');

    if (lastFetchTime == null) return true;

    final lastFetchDate = DateTime.parse(lastFetchTime);
    final now = DateTime.now();
    return now.difference(lastFetchDate).inDays >= 1;
  }

  static Future<bool> haveRatesChanged(Map<String, double> newRates) async {
    final prefs = await SharedPreferences.getInstance();
    final storedRates = prefs.getString('exchange_rates');

    if (storedRates == null) return true;

    final oldRates = Map<String, double>.from(jsonDecode(storedRates));

    for (final entry in newRates.entries) {
      final oldRate = oldRates[entry.key];
      if (oldRate == null || oldRate != entry.value) {
        return true;
      }
    }
    return false;
  }
}
