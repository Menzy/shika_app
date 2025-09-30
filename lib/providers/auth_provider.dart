import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kukuo/screens/login_screen.dart';

class AuthProvider extends ChangeNotifier {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  bool _isLoading = false;
  Map<String, dynamic>? _user;
  String? _username;
  String? _email;
  String? _userId;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get username => _username;
  Map<String, dynamic>? get user => _user;
  String? get userId => _userId;
  String? get email => _email;

  AuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (isLoggedIn) {
      final userData = prefs.getString(_userKey);
      if (userData != null) {
        _user = Map<String, dynamic>.from(
            Map<String, dynamic>.from(await _parseUserData(userData)));
        _username = _user!['username'];
        _email = _user!['email'];
        _userId = _user!['userId'];
        notifyListeners();
      }
    }
  }

  Future<Map<String, dynamic>> _parseUserData(String userData) async {
    // Simple parsing of the stored JSON string
    return Map<String, dynamic>.from(await jsonDecode(userData));
  }

  Future<void> _saveUserData() async {
    if (_user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_user));
      await prefs.setBool(_isLoggedInKey, true);
    }
  }

  Future<void> checkAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadUserData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Automatically logs in a default user without requiring credentials
  /// This is used to bypass the login screen
  Future<void> autoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Create a default user
      _user = {
        'username': 'DefaultUser',
        'email': 'default@example.com',
        'userId': 'default-user-id',
      };

      _username = _user!['username'];
      _email = _user!['email'];
      _userId = _user!['userId'];

      // Save the user data to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(_user));
      await prefs.setBool(_isLoggedInKey, true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this helper method
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<String?> signUpWithEmail(
      String email, String password, String username) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if email already exists
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData != null) {
        final existingUser = await _parseUserData(userData);
        if (existingUser['email'] == email) {
          return 'Email already in use';
        }
      }

      // Capitalize first letter of username
      final capitalizedUsername = _capitalizeFirstLetter(username);

      // Generate a unique user ID
      final userId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create user data
      _user = {
        'userId': userId,
        'username': capitalizedUsername,
        'email': email,
        'password': password, // In a real app, you would hash this
        'createdAt': DateTime.now().toIso8601String(),
      };

      _username = capitalizedUsername;
      _email = email;
      _userId = userId;

      // Save user data
      await _saveUserData();

      return null;
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

      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);

      if (userData == null) {
        return 'No account found with this email';
      }

      final storedUser = await _parseUserData(userData);

      if (storedUser['email'] != email) {
        return 'No account found with this email';
      }

      if (storedUser['password'] != password) {
        return 'Invalid password';
      }

      _user = storedUser;
      _username = storedUser['username'];
      _email = storedUser['email'];
      _userId = storedUser['userId'];

      await prefs.setBool(_isLoggedInKey, true);

      return null;
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

      // Since we're removing Firebase, we'll simulate Google sign-in
      // In a real app, you would implement proper OAuth flow

      return 'Google Sign In is not available in this version';
    } catch (e) {
      debugPrint('Google sign in error: $e');
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

      // Clear user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);

      _user = null;
      _username = null;
      _email = null;
      _userId = null;

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
}
