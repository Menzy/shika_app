import 'package:shared_preferences/shared_preferences.dart';

class CurrencyPreferenceService {
  static const String _selectedCurrencyKey = 'selected_local_currency';
  static const String _defaultCurrency = 'USD';

  /// Saves the selected local currency to SharedPreferences
  static Future<void> saveSelectedCurrency(String currencyCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedCurrencyKey, currencyCode);
    } catch (e) {
      print('Error saving selected currency: $e');
    }
  }

  /// Loads the selected local currency from SharedPreferences
  /// Returns the default currency (USD) if no currency is saved
  static Future<String> loadSelectedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_selectedCurrencyKey) ?? _defaultCurrency;
    } catch (e) {
      print('Error loading selected currency: $e');
      return _defaultCurrency;
    }
  }

  /// Checks if a currency preference exists
  static Future<bool> hasSavedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_selectedCurrencyKey);
    } catch (e) {
      print('Error checking saved currency: $e');
      return false;
    }
  }
}
