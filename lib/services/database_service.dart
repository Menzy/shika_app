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

  // Add more methods here for other data (transactions, etc.)
}
