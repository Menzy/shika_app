import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kukuo/screens/login_screen.dart';
import 'package:kukuo/services/auth_service.dart';
import 'package:kukuo/services/database_service.dart';
import 'package:kukuo/providers/user_input_provider.dart';
import 'package:provider/provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  DatabaseService? _databaseService;

  bool _isLoading = false;
  User? _user;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  User? get user => _user;
  String? get userId => _user?.uid;
  String? get email => _user?.email;
  String? get username => _user?.displayName;
  DatabaseService? get databaseService => _databaseService;

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
        _databaseService = DatabaseService(uid: _user!.uid);
        await _databaseService?.saveUserData(_user!);
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
        _databaseService = DatabaseService(uid: credential.user!.uid);
        await _databaseService?.saveUserData(credential.user!);
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
        // Clear local user data
        Provider.of<UserInputProvider>(context, listen: false).clearData();

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
    final user = _user;
    if (user == null) return 'No user logged in';

    try {
      _isLoading = true;
      notifyListeners();

      // Delete user data from Firestore
      if (_databaseService != null) {
        await _databaseService!.deleteUserData(user.uid);
      }

      // Delete user from Firebase Auth
      await user.delete();

      // Ensure complete sign out (clears Google Sign In, etc.)
      await _authService.signOut();

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
        // Force logout so user can log in again to delete account
        await _authService.signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
        return 'Security requirement: Please log in again to confirm account deletion.';
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
