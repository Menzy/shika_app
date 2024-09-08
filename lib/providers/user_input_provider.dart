import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kukuo/models/currency_amount_model.dart';

class UserInputProvider with ChangeNotifier {
  List<CurrencyAmount> _currencies = [];

  List<CurrencyAmount> get currencies => _currencies;

  UserInputProvider() {
    loadCurrencies(); // Ensure currencies are loaded on initialization
  }

  Future<void> loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCurrencies = prefs.getString('currencies');
    if (storedCurrencies != null) {
      final List<dynamic> jsonList = jsonDecode(storedCurrencies);
      _currencies =
          jsonList.map((json) => CurrencyAmount.fromJson(json)).toList();
      print('Currencies loaded: $_currencies'); // Debug print
      notifyListeners();
    } else {
      print('No stored currencies found'); // Debug print
    }
  }

  // Future<void> addCurrency(CurrencyAmount currency) async {
  //   _currencies.add(currency);
  //   await _saveCurrencies();
  //   print('Currency added: $currency'); // Debug print
  // }

  Future<void> addCurrency(CurrencyAmount currency) async {
    _currencies.insert(0, currency); // Insert at the beginning
    await _saveCurrencies();
    print('Currency added: $currency'); // Debug print
  }

  Future<void> updateCurrency(int index, CurrencyAmount currency) async {
    _currencies[index] = currency;
    await _saveCurrencies();
    print('Currency updated: $currency'); // Debug print
  }

  Future<void> removeCurrency(int index) async {
    _currencies.removeAt(index);
    await _saveCurrencies();
    print('Currency removed at index: $index'); // Debug print
  }

  Future<void> _saveCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _currencies
        .map((c) => {
              'code': c.code,
              'amount': c.amount,
            })
        .toList();
    await prefs.setString('currencies', jsonEncode(jsonList));
    print('Currencies saved: $_currencies'); // Debug print
    notifyListeners();
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

  // Method to get top number of currencies
  List<CurrencyAmount> getTopCurrencies(int number) {
    if (_currencies.isEmpty) {
      return [];
    }

    // Ensure the list is not empty
    final topCurrencies = _currencies.take(number).toList();
    return topCurrencies;
  }
}
