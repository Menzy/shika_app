import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kukuo/screens/login_screen.dart';
import 'package:kukuo/services/auth_service.dart';
import 'package:kukuo/services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  late DatabaseService _databaseService;

  bool _isLoading = false;
  User? _user;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  User? get user => _user;
  String? get userId => _user?.uid;
  String? get email => _user?.email;
  String? get username => _user?.displayName;

  final Completer<void> _authReady = Completer<void>();

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _databaseService = DatabaseService(uid: user.uid);
      }
      if (!_authReady.isCompleted) {
        _authReady.complete();
      }
      notifyListeners();
    });
  }

  Future<void> checkAuthState() async {
    await _authReady.future;
  }

  // Removed autoLogin as we want real auth now

  Future<String?> signUpWithEmail(
      String email, String password, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(username);
        _user = FirebaseAuth
            .instance.currentUser; // Refresh user to get display name

        _databaseService = DatabaseService(uid: _user!.uid);
        await _databaseService.saveUserData(_user!);
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _authService.signInWithGoogle();

      if (credential?.user != null) {
        _databaseService = DatabaseService(uid: credential!.user!.uid);
        await _databaseService.saveUserData(credential.user!);
        return null;
      } else {
        return 'Google sign in cancelled';
      }
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();

      if (context.mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> deleteAccount(BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Delete user data from Firestore
      if (_user != null) {
        await _databaseService.deleteUserData(_user!.uid);
      }

      // Delete user from Firebase Auth
      await _user?.delete();

      if (context.mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Please log out and log in again to delete your account.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
