import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? uid;

  DatabaseService({this.uid});

  // Collection reference
  CollectionReference get usersCollection => _firestore.collection('users');

  // Save user data
  Future<void> saveUserData(User user) async {
    await usersCollection.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Delete user data
  Future<void> deleteUserData(String uid) async {
    await usersCollection.doc(uid).delete();
  }

  // Subcollections
  CollectionReference get transactionsCollection =>
      usersCollection.doc(uid).collection('transactions');

  DocumentReference get dataDocument =>
      usersCollection.doc(uid).collection('data').doc('main');

  // --- Transactions ---

  Future<void> saveTransaction(Map<String, dynamic> transactionJson) async {
    if (uid == null) return;
    // Use timestamp as ID to ensure ordering and uniqueness
    await transactionsCollection.add(transactionJson);
  }

  Future<List<Map<String, dynamic>>> loadTransactions() async {
    if (uid == null) return [];
    final snapshot = await transactionsCollection.orderBy('timestamp').get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  // --- Currencies ---

  Future<void> saveCurrencies(List<Map<String, dynamic>> currenciesJson) async {
    if (uid == null) return;
    await dataDocument.set({
      'currencies': currenciesJson,
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>?> loadCurrencies() async {
    if (uid == null) return null;
    final doc = await dataDocument.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('currencies')) {
        return List<Map<String, dynamic>>.from(data['currencies']);
      }
    }
    return null;
  }

  Future<void> saveSelectedCurrency(String currencyCode) async {
    if (uid == null) return;
    await dataDocument.set({
      'selectedCurrency': currencyCode,
    }, SetOptions(merge: true));
  }

  Future<String?> loadSelectedCurrency() async {
    if (uid == null) return null;
    final doc = await dataDocument.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('selectedCurrency')) {
        return data['selectedCurrency'] as String;
      }
    }
    return null;
  }

  // --- Balance History ---

  Future<void> saveBalanceHistory(
      List<double> balances, List<String> times) async {
    if (uid == null) return;
    await dataDocument.set({
      'balanceHistory': balances,
      'timeHistory': times,
    }, SetOptions(merge: true));
  }

  Future<void> saveInvestedHistory(List<double> investedHistory) async {
    if (uid == null) return;
    await dataDocument.set({
      'investedHistory': investedHistory,
    }, SetOptions(merge: true));
  }

  Future<List<double>?> loadInvestedHistory() async {
    if (uid == null) return null;
    final doc = await dataDocument.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('investedHistory')) {
        return List<double>.from(data['investedHistory']);
      }
    }
    return null;
  }

  Future<({List<double> balances, List<DateTime> times})?>
      loadBalanceHistory() async {
    if (uid == null) return null;
    final doc = await dataDocument.get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('balanceHistory') &&
          data.containsKey('timeHistory')) {
        final balances = List<double>.from(data['balanceHistory']);
        final times = (data['timeHistory'] as List)
            .map((e) => DateTime.parse(e))
            .toList();
        return (balances: balances, times: times);
      }
    }
    return null;
  }
}
