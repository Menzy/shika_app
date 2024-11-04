import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kukuo/models/currency_transaction.dart';
import 'package:kukuo/models/currency_amount_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveCurrencyData(
      String userId, List<CurrencyAmount> currencies) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('currencies')
        .doc('current')
        .set({
      'currencies': currencies.map((c) => c.toJson()).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveTransaction(
      String userId, CurrencyTransaction transaction) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .add({
      ...transaction.toJson(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CurrencyTransaction>> loadTransactions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('timestamp',
              descending: false) // Changed to false for ascending order
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure timestamp is properly converted
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] =
              (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        return CurrencyTransaction.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error loading transactions: $e');
      return [];
    }
  }

  Future<List<CurrencyAmount>> loadCurrencies(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('currencies')
        .doc('current')
        .get();

    if (!doc.exists) return [];

    final data = doc.data();
    final currenciesList = data?['currencies'] as List<dynamic>?;

    if (currenciesList == null) return [];

    return currenciesList.map((json) => CurrencyAmount.fromJson(json)).toList();
  }

  Stream<List<CurrencyTransaction>> watchTransactions(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
        }
        return CurrencyTransaction.fromJson(data);
      }).toList();
    });
  }

  Stream<List<CurrencyAmount>> watchCurrencies(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('currencies')
        .doc('current')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return [];
      
      final data = doc.data()!;
      final currenciesList = data['currencies'] as List<dynamic>?;
      
      if (currenciesList == null) return [];
      
      return currenciesList.map((json) => CurrencyAmount.fromJson(json)).toList();
    });
  }
}
