import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:kukuo/models/currency_amount_model.dart';
import 'package:kukuo/services/local_storage_service.dart';

class FirebaseService {
  final LocalStorageService _localStorage = LocalStorageService();

  Future<void> saveCurrencyData(
      String userId, List<CurrencyAmount> currencies) async {
    await _localStorage.saveCurrencies(currencies);
  }

  Future<void> saveTransaction(
      String userId, CurrencyTransaction transaction) async {
    // Load existing transactions
    final transactions = await loadTransactions(userId);

    // Add the new transaction
    transactions.add(transaction);

    // Save all transactions
    await _localStorage.saveTransactions(transactions);
  }

  Future<List<CurrencyTransaction>> loadTransactions(String userId) async {
    try {
      return await _localStorage.loadTransactions();
    } catch (e) {
      debugPrint('Error loading transactions: $e');
      return [];
    }
  }

  Future<List<CurrencyAmount>> loadCurrencies(String userId) async {
    return await _localStorage.loadCurrencies();
  }

  Stream<List<CurrencyTransaction>> watchTransactions(String userId) {
    // Create a stream controller to simulate Firestore's real-time updates
    final controller = StreamController<List<CurrencyTransaction>>();

    // Initial load
    loadTransactions(userId).then((transactions) {
      controller.add(transactions);
    });

    return controller.stream;
  }

  Stream<List<CurrencyAmount>> watchCurrencies(String userId) {
    // Create a stream controller to simulate Firestore's real-time updates
    final controller = StreamController<List<CurrencyAmount>>();

    // Initial load
    loadCurrencies(userId).then((currencies) {
      controller.add(currencies);
    });

    return controller.stream;
  }
}
